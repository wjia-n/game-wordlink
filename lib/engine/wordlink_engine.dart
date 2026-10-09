import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../theme/word_themes.dart';

// ---------------------------------------------------------------------------
// Modes & phases
// ---------------------------------------------------------------------------

/// Play modes: Journey (60 hand-progressed levels), Blitz (2-minute timed
/// scramble), Relaxed (untimed random boards).
enum WlMode { journey, blitz, relaxed }

/// Engine-owned phases. The UI only renders — it never drives transitions.
/// [dealing]: letters drop in one by one. [playing]: swipe input accepted.
/// [evaluating]: a found word reveals letter-by-letter. [levelClear]:
/// celebration, then auto-advance. [over]: game finished.
enum WlPhase { dealing, playing, evaluating, levelClear, over }

/// Audio/UI hook events emitted by the engine. The UI wires these to sounds.
enum WlEvent {
  letterAdded,
  wordFound,
  wordMissed,
  shuffle,
  dealDone,
  levelClear,
  gameOver,
  tickTock,
  hintUsed,
  gameStart,
}

// ---------------------------------------------------------------------------
// Engine
// ---------------------------------------------------------------------------

class WordLinkEngine extends ChangeNotifier {
  final WlMode mode;
  final int difficulty; // 0 rookie, 1 wordsmith, 2 genius
  final int gridSize;
  final int maxLevel = 60;

  int level = 1; // journey level (1-based)
  int score = 0;
  int moves = 0;
  int secondsLeft = 120;
  WlPhase phase = WlPhase.dealing;

  List<String> letters = [];
  List<String> words = [];
  final Set<String> found = {};
  final List<int> path = [];

  /// Deal animation: how many tiles are currently visible.
  int dealtCount = 0;

  /// Found-word reveal animation: word being revealed + letters shown so far.
  /// [lastFoundPath] holds the tile indices of the just-found word so the
  /// UI can pulse them in sequence instead of popping the result instantly.
  String revealWord = '';
  int revealCount = 0;
  int revealNonce = 0;
  List<int> lastFoundPath = [];

  /// Every tile index that belongs to a found word this board. The UI tints
  /// them as linked tokens; reset on every new board.
  final Set<int> foundCells = {};

  /// Wrong-word feedback: increments every miss; UI shakes the preview text.
  int missNonce = 0;
  String missWord = '';

  /// Hint state: revealed letter count per word.
  final Map<String, int> hinted = {};

  /// Hints remaining on this board (free tier). Pro = unlimited (-1).
  int hintsLeft = 3;

  int wordsFoundTotal = 0;

  /// Current swipe preview, built by the UI from [path] + [letters].
  String get preview => path.map((i) => letters[i]).join();

  bool get allFound => words.isNotEmpty && found.length == words.length;
  bool get isOver => phase == WlPhase.over;
  bool get inputOpen => phase == WlPhase.playing && !paused;

  ValueChanged<WlEvent>? onEvent;

  final _rand = Random();
  Timer? _timer; // single phase-transition timer
  Timer? _dealTimer;
  Timer? _revealTimer;
  Timer? _blitzTimer;
  Timer? _watchdog; // stuck-state recovery
  bool _disposed = false;
  bool paused = false;
  bool proUnlimitedHints = false;

  static const int blitzSeconds = 120;
  static const int freeHintsPerBoard = 3;

  WordLinkEngine({
    required this.mode,
    required this.difficulty,
    int? startLevel,
  }) : gridSize = WlDifficulty.gridSizes[difficulty.clamp(0, 2)] {
    level = (startLevel ?? 1).clamp(1, maxLevel);
    if (mode == WlMode.journey) {
      // Journey overrides grid size by level band (3x3 -> 5x5).
      _loadBoard(_sizeForLevel(level), seed: level * 7919);
    } else {
      secondsLeft = blitzSeconds;
      _loadBoard(gridSize, seed: _rand.nextInt(1 << 30));
    }
    _beginDeal();
    _watchdog = Timer.periodic(const Duration(seconds: 3), (_) => _recover());
  }

  int _sizeForLevel(int lv) => lv <= 20 ? 3 : (lv <= 40 ? 4 : 5);

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _dealTimer?.cancel();
    _revealTimer?.cancel();
    _blitzTimer?.cancel();
    _watchdog?.cancel();
    super.dispose();
  }

  void _arm(Duration d, void Function() fn) {
    if (_disposed || paused) return;
    _timer?.cancel();
    _timer = Timer(d, () {
      _timer = null;
      if (!_disposed && !paused) fn();
    });
  }

  /// Pause: freeze every engine timer. Resume re-arms the current phase.
  void setPaused(bool v) {
    if (paused == v || _disposed) return;
    paused = v;
    if (v) {
      _timer?.cancel();
      _timer = null;
      _dealTimer?.cancel();
      _dealTimer = null;
      _revealTimer?.cancel();
      _revealTimer = null;
      _blitzTimer?.cancel();
      _blitzTimer = null;
    } else {
      _recover();
    }
    notifyListeners();
  }

  /// Watchdog: recover any phase found without a live timer. Stuck states
  /// are impossible by construction. Respects [paused].
  void _recover() {
    if (_disposed || paused) return;
    if (phase == WlPhase.over) {
      notifyListeners();
      return;
    }
    if (phase == WlPhase.dealing && _dealTimer == null) {
      _resumeDeal();
    } else if (phase == WlPhase.evaluating && _revealTimer == null) {
      _afterReveal();
    } else if (phase == WlPhase.levelClear && _timer == null) {
      _advanceAfterClear();
    } else if (phase == WlPhase.playing &&
        mode == WlMode.blitz &&
        _blitzTimer == null &&
        !isOver) {
      _startBlitzClock();
    }
  }

  // ------------------------------------------------------------ board setup
  void _loadBoard(int size, {required int seed}) {
    final minLen = WlDifficulty.minWordLens[difficulty];
    final maxLen = mode == WlMode.journey
        ? (size == 3 ? 4 : (size == 4 ? 5 : 6))
        : WlDifficulty.maxWordLens[difficulty];
    final count = WlDifficulty.wordCountFor(size);
    final gen = _generate(seed, size, count, minLen, maxLen);
    letters = gen.$1;
    words = gen.$2;
    found.clear();
    path.clear();
    hinted.clear();
    foundCells.clear();
    lastFoundPath = [];
    hintsLeft = proUnlimitedHints ? 999999 : freeHintsPerBoard;
    dealtCount = 0;
    revealWord = '';
    revealCount = 0;
    missWord = '';
    if (mode == WlMode.journey) secondsLeft = 0;
  }

  void _beginDeal() {
    phase = WlPhase.dealing;
    dealtCount = 0;
    _dealTimer?.cancel();
    _resumeDeal();
  }

  void _resumeDeal() {
    if (_disposed || paused) return;
    _dealTimer?.cancel();
    final total = letters.length;
    _dealTimer = Timer.periodic(const Duration(milliseconds: 45), (t) {
      if (_disposed || paused) {
        t.cancel();
        _dealTimer = null;
        return;
      }
      dealtCount++;
      onEvent?.call(WlEvent.letterAdded);
      notifyListeners();
      if (dealtCount >= total) {
        t.cancel();
        _dealTimer = null;
        _enterPlaying();
      }
    });
    notifyListeners();
  }

  void _enterPlaying() {
    if (phase == WlPhase.over) return;
    phase = WlPhase.playing;
    onEvent?.call(WlEvent.dealDone);
    if (mode == WlMode.blitz && _blitzTimer == null) _startBlitzClock();
    notifyListeners();
  }

  void _startBlitzClock() {
    if (_disposed || paused) return;
    _blitzTimer?.cancel();
    _blitzTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_disposed || paused) {
        t.cancel();
        _blitzTimer = null;
        return;
      }
      secondsLeft--;
      if (secondsLeft <= 10 && secondsLeft > 0) {
        onEvent?.call(WlEvent.tickTock);
      }
      if (secondsLeft <= 0) {
        t.cancel();
        _blitzTimer = null;
        _finishBlitz();
      }
      notifyListeners();
    });
  }

  void _finishBlitz() {
    phase = WlPhase.over;
    path.clear();
    onEvent?.call(WlEvent.gameOver);
    notifyListeners();
  }

  // -------------------------------------------------------------- swiping
  bool get canStartSwipe => inputOpen;

  /// True if [idx] is a legal next cell for the current swipe.
  bool _isAdjacent(int idx) {
    if (path.isEmpty) return true;
    final last = path.last;
    final r1 = last ~/ _size(), c1 = last % _size();
    final r2 = idx ~/ _size(), c2 = idx % _size();
    return (r1 - r2).abs() <= 1 && (c1 - c2).abs() <= 1;
  }

  int _size() => (letters.isEmpty ? gridSize : sqrt(letters.length)).round();

  void swipeStart(int idx) {
    if (!canStartSwipe || dealtCount < letters.length) return;
    path
      ..clear()
      ..add(idx);
    onEvent?.call(WlEvent.letterAdded);
    notifyListeners();
  }

  void swipeMove(int idx) {
    if (!canStartSwipe || path.isEmpty) return;
    if (idx == path.last || !_isAdjacent(idx)) return;
    if (path.length >= 2 && path[path.length - 2] == idx) {
      path.removeLast(); // backtrack
    } else if (!path.contains(idx)) {
      path.add(idx);
      onEvent?.call(WlEvent.letterAdded);
    } else {
      return;
    }
    notifyListeners();
  }

  /// Finger lifted: evaluate the spelled word. Never resolves instantly —
  /// hits run through the reveal animation, misses shake the preview.
  void swipeEnd() {
    if (path.isEmpty || !canStartSwipe) {
      path.clear();
      notifyListeners();
      return;
    }
    final spelled = preview;
    final rev = spelled.split('').reversed.join();
    String? hit;
    for (final w in words) {
      if (found.contains(w)) continue;
      if (w == spelled || w == rev) {
        hit = w;
        break;
      }
    }
    moves++;
    if (hit != null) {
      _foundWord(hit);
    } else {
      missWord = spelled;
      missNonce++;
      path.clear();
      onEvent?.call(WlEvent.wordMissed);
      notifyListeners();
    }
  }

  void _foundWord(String w) {
    found.add(w);
    wordsFoundTotal++;
    score += w.length * 10;
    lastFoundPath = List.of(path);
    foundCells.addAll(path);
    path.clear();
    phase = WlPhase.evaluating;
    revealWord = w;
    revealCount = 0;
    revealNonce++;
    onEvent?.call(WlEvent.wordFound);
    notifyListeners();
    _revealTimer?.cancel();
    _revealTimer = Timer.periodic(const Duration(milliseconds: 110), (t) {
      if (_disposed || paused) {
        t.cancel();
        _revealTimer = null;
        return;
      }
      revealCount++;
      notifyListeners();
      if (revealCount >= revealWord.length + 2) {
        t.cancel();
        _revealTimer = null;
        _afterReveal();
      }
    });
  }

  void _afterReveal() {
    if (_disposed || phase != WlPhase.evaluating) return;
    revealWord = '';
    if (allFound) {
      _levelCleared();
    } else {
      phase = WlPhase.playing;
      notifyListeners();
    }
  }

  void _levelCleared() {
    phase = WlPhase.levelClear;
    final bonus = mode == WlMode.blitz ? 50 : 25 + _size() * 5;
    score += bonus;
    onEvent?.call(WlEvent.levelClear);
    notifyListeners();
    _arm(const Duration(milliseconds: 1900), _advanceAfterClear);
  }

  void _advanceAfterClear() {
    if (_disposed || phase != WlPhase.levelClear) return;
    if (mode == WlMode.journey && level >= maxLevel) {
      phase = WlPhase.over;
      onEvent?.call(WlEvent.gameOver);
      notifyListeners();
      return;
    }
    if (mode == WlMode.journey) {
      level++;
      _loadBoard(_sizeForLevel(level), seed: level * 7919);
    } else {
      // Blitz / Relaxed: fresh board, keep the score rolling.
      _loadBoard(gridSize, seed: _rand.nextInt(1 << 30));
    }
    _beginDeal();
  }

  // ------------------------------------------------------------------ hints
  bool get canHint =>
      inputOpen &&
      found.length < words.length &&
      (proUnlimitedHints || hintsLeft > 0);

  /// Reveal the next hidden letter of the first unfinished word.
  void useHint() {
    if (!canHint) return;
    for (final w in words) {
      if (found.contains(w)) continue;
      final have = hinted[w] ?? 0;
      if (have < w.length) {
        hinted[w] = have + 1;
        break;
      }
    }
    if (!proUnlimitedHints) hintsLeft--;
    onEvent?.call(WlEvent.hintUsed);
    notifyListeners();
  }

  // ---------------------------------------------------------------- shuffle
  /// Shuffle: re-place the SAME word list on a fresh letter layout (RULES
  /// §7). All words stay findable; free and unlimited. Clears the
  /// found-tile tint map — re-placed word paths move, so old cell indices
  /// would tint the wrong tiles.
  void shuffle() {
    if (!inputOpen) return;
    path.clear();
    foundCells.clear();
    lastFoundPath = [];
    final size = _size();
    final rng = Random(DateTime.now().microsecondsSinceEpoch);
    for (int attempt = 0; attempt < 80; attempt++) {
      final grid = List<String>.filled(size * size, '');
      final order = [...words]..shuffle(rng);
      order.sort((a, b) => b.length.compareTo(a.length));
      if (_placeAll(grid, order, size, rng)) {
        letters = grid;
        dealtCount = letters.length; // already dealt: no re-deal, just pop
        onEvent?.call(WlEvent.shuffle);
        notifyListeners();
        return;
      }
    }
    // Placement failed (astronomically unlikely): leave the board as-is.
    onEvent?.call(WlEvent.shuffle);
    notifyListeners();
  }

  /// Restart with a fresh random board (new words), score kept.
  void restartBoard() {
    if (phase == WlPhase.over) return;
    _loadBoard(_size(), seed: _rand.nextInt(1 << 30));
    _beginDeal();
  }

  // ------------------------------------------------------- board generation
  /// Returns (letters, words). Words are guaranteed placeable as adjacent
  /// (8-way) paths because we draw them onto the grid. Deterministic per
  /// [seed] so Journey levels are identical for every player.
  (List<String>, List<String>) _generate(
      int seed, int size, int count, int minLen, int maxLen) {
    final rng = Random(seed);
    for (int attempt = 0; attempt < 80; attempt++) {
      final pool = wordPool
          .where((w) => w.length >= minLen && w.length <= maxLen)
          .toList();
      pool.shuffle(rng);
      final picked = <String>[];
      for (final w in pool) {
        if (picked.length >= count) break;
        if (!picked.contains(w)) picked.add(w);
      }
      if (picked.length < count) continue;
      picked.sort((a, b) => b.length.compareTo(a.length));
      final grid = List<String>.filled(size * size, '');
      if (!_placeAll(grid, picked, size, rng)) continue;
      const abc = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
      for (int i = 0; i < grid.length; i++) {
        if (grid[i] == '') grid[i] = abc[rng.nextInt(26)];
      }
      picked.sort((a, b) => a.length.compareTo(b.length));
      return (grid, picked);
    }
    // Ultra-safe fallback: straight rows of short words.
    final fb = wordPool.where((w) => w.length <= size).take(count).toList();
    final grid = List<String>.filled(size * size, 'A');
    for (int wi = 0; wi < fb.length; wi++) {
      for (int i = 0; i < fb[wi].length && i < size; i++) {
        grid[wi * size + i] = fb[wi][i];
      }
    }
    return (grid, fb);
  }

  bool _placeAll(List<String> grid, List<String> words, int size, Random rng) {
    for (final w in words) {
      if (!_placeWord(grid, w, size, rng)) return false;
    }
    return true;
  }

  bool _placeWord(List<String> grid, String w, int size, Random rng) {
    for (int t = 0; t < 250; t++) {
      final start = rng.nextInt(size * size);
      if (grid[start] != '' && grid[start] != w[0]) continue;
      final p = [start];
      final used = {start};
      bool ok = true;
      for (int i = 1; i < w.length; i++) {
        final nbs = _neighbors(p.last, size)
            .where((x) => !used.contains(x))
            .toList()
          ..shuffle(rng);
        bool stepped = false;
        for (final nb in nbs) {
          if (grid[nb] == '' || grid[nb] == w[i]) {
            p.add(nb);
            used.add(nb);
            stepped = true;
            break;
          }
        }
        if (!stepped) {
          ok = false;
          break;
        }
      }
      if (ok) {
        for (int i = 0; i < w.length; i++) {
          grid[p[i]] = w[i];
        }
        return true;
      }
    }
    return false;
  }

  List<int> _neighbors(int idx, int size) {
    final r = idx ~/ size, c = idx % size;
    final out = <int>[];
    for (int dr = -1; dr <= 1; dr++) {
      for (int dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;
        final nr = r + dr, nc = c + dc;
        if (nr >= 0 && nr < size && nc >= 0 && nc < size) {
          out.add(nr * size + nc);
        }
      }
    }
    return out;
  }
}

/// Built-in word pool (3–6 letters) used to generate every board.
const wordPool = [
  'CAT','DOG','PIG','COW','FOX','OWL','ANT','BEE','SUN','SKY','SEA','PIE','TEA',
  'EGG','JAM','HAM','BUN','HAT','CAP','MAP','BUS','CAR','BED','BOX','CUP','PEN',
  'KEY','ICE','BAT','RAT','HEN','APE','ELK','YAK','COD','EEL','OAK','ASH','IVY',
  'LOG','FOG','RUG','MUG','JUG','HUG','DIG','WIG','FIG','RIG','NOD','ZIP','FISH',
  'BIRD','FROG','BEAR','LION','WOLF','CAKE','CRAB','DUCK','GOAT','LAMB','MOTH','WASP','STAR',
  'MOON','COMET','CACTUS','LEAF','MOSS','CORAL','PEARL','BREAD','PASTA','PIZZA','SOUP','TACOS','RICE',
  'CORN','HONEY','SUGAR','CANDY','LEMON','MANGO','PEACH','GRAPE','APPLE','MELON','KIWI','PLUM','DANCE',
  'SING','JUMP','RUNS','SWIMS','FLIES','GROWS','BLOOM','GLOWS','SHINES','BRAVE','SWIFT','CALM','WILD',
  'COZY','JOLLY','MERRY','LUCKY','HAPPY','ZEBRA','PANDA','KOALA','WHALE','SHARK','SNAKE','TURTLE','CAMEL',
  'DONUT','MUFFIN','COOKIE','WAFFLE','TIGER','HORSE','SHEEP','MOUSE','EAGLE','ROBOT','ALIEN','MAGIC','DREAM',
  'LIGHT','OCEAN','RIVER','MOUNT','VALLEY','FOREST','MEADOW','SUNNY','CLOUDY','STORMY','FROSTY','SPICY','SWEET',
  'TASTY','CRUNCH','MUSIC','PARTY','GAMES','SPORT','SMILE','LAUGH','HEART','BRAIN','TOWER','BRIDGE','CASTLE',
  'ROCKET','PLANET','SOLAR','LUNAR','NOVA','ORBIT','MONKEY','JAGUAR','RABBIT','GALAXY','NEBULA','SATURN','BANANA',
  'ORANGE','PAPAYA','CHERRY','DONUTS','POTATO','TOMATO','CARROT','ONION','PEPPER','PUZZLE','RIDDLE','JIGSAW','ARCADE',
  'PIXELS','JOYFUL','CHEEKY','BOUNCY','GIGGLE','SUNSET','BEACH','JUNGLE','DESERT','TUNNEL','GARDEN','MELODY','RHYTHM',
];
