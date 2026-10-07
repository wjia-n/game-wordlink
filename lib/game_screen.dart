import 'dart:math';
import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';

/// Word Link — swipe through adjacent letters to build every word.
/// 60 generated levels, 3x3 → 5x5 grids, shuffle button, juicy trail.
class WordLinkScreen extends StatefulWidget {
  final List<Player> players;
  final GameCallbacks callbacks;

  const WordLinkScreen({super.key, required this.players, required this.callbacks});

  @override
  State<WordLinkScreen> createState() => _WordLinkScreenState();
}

class _WordLinkScreenState extends State<WordLinkScreen> {
  static const int maxLevel = 60;
  int level = 1;
  late int size;
  late List<String> letters; // size*size
  late List<String> words; // level word list
  final Set<String> found = {};
  final List<int> path = [];
  bool levelDone = false;
  bool over = false;
  final _gridKey = GlobalKey();
  String _shakeWord = '';

  int get _sizeFor => level <= 20 ? 3 : (level <= 40 ? 4 : 5);

  @override
  void initState() {
    super.initState();
    _loadLevel(1);
  }

  void _loadLevel(int lv) {
    level = lv;
    size = _sizeFor;
    found.clear();
    path.clear();
    levelDone = false;
    _shakeWord = '';
    final gen = _generate(lv, size);
    letters = gen.$1;
    words = gen.$2;
  }

  /// Returns (letters, words). Words are guaranteed placeable as
  /// adjacent (8-way) paths because we literally draw them on the grid.
  (List<String>, List<String>) _generate(int lv, int sz) {
    final wordCount = sz == 3 ? 3 : (sz == 4 ? 4 : 5);
    final maxLen = sz == 3 ? 4 : (sz == 4 ? 5 : 6);
    for (int attempt = 0; attempt < 60; attempt++) {
      final rng = Random(lv * 7919 + attempt * 131);
      final pool = _words.where((w) => w.length >= 3 && w.length <= maxLen).toList();
      pool.shuffle(rng);
      final picked = <String>[];
      for (final w in pool) {
        if (picked.length >= wordCount) break;
        if (!picked.contains(w)) picked.add(w);
      }
      // longer words first = easier placement
      picked.sort((a, b) => b.length.compareTo(a.length));
      final grid = List<String>.filled(sz * sz, '');
      bool okAll = true;
      for (final w in picked) {
        bool placed = false;
        for (int t = 0; t < 250 && !placed; t++) {
          final start = rng.nextInt(sz * sz);
          if (grid[start] != '' && grid[start] != w[0]) continue;
          final p = [start];
          final used = {start};
          bool ok = true;
          for (int i = 1; i < w.length; i++) {
            final nbs = _neighbors(p.last, sz).where((x) => !used.contains(x)).toList()
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
            placed = true;
          }
        }
        if (!placed) {
          okAll = false;
          break;
        }
      }
      if (!okAll) continue;
      const abc = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
      for (int i = 0; i < grid.length; i++) {
        if (grid[i] == '') grid[i] = abc[rng.nextInt(26)];
      }
      picked.sort((a, b) => a.length.compareTo(b.length));
      return (grid, picked);
    }
    // ultra-safe fallback: straight rows
    final fb = _words.where((w) => w.length <= sz).take(wordCount).toList();
    final grid = List<String>.filled(sz * sz, 'A');
    for (int wi = 0; wi < fb.length; wi++) {
      for (int i = 0; i < fb[wi].length; i++) {
        grid[wi * sz + i] = fb[wi][i];
      }
    }
    return (grid, fb);
  }

  List<int> _neighbors(int idx, int sz) {
    final r = idx ~/ sz, c = idx % sz;
    final out = <int>[];
    for (int dr = -1; dr <= 1; dr++) {
      for (int dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;
        final nr = r + dr, nc = c + dc;
        if (nr >= 0 && nr < sz && nc >= 0 && nc < sz) out.add(nr * sz + nc);
      }
    }
    return out;
  }

  int? _cellAt(Offset global) {
    final ctx = _gridKey.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject() as RenderBox;
    final local = box.globalToLocal(global);
    final cell = box.size.width / size;
    final c = (local.dx / cell).floor();
    final r = (local.dy / cell).floor();
    if (r < 0 || r >= size || c < 0 || c >= size) return null;
    return r * size + c;
  }

  void _onPanStart(DragStartDetails d) {
    if (levelDone || over) return;
    final idx = _cellAt(d.globalPosition);
    if (idx == null) return;
    Sfx.tap();
    setState(() {
      path
        ..clear()
        ..add(idx);
    });
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (levelDone || over || path.isEmpty) return;
    final idx = _cellAt(d.globalPosition);
    if (idx == null || idx == path.last) return;
    final r1 = path.last ~/ size, c1 = path.last % size;
    final r2 = idx ~/ size, c2 = idx % size;
    if ((r1 - r2).abs() > 1 || (c1 - c2).abs() > 1) return;
    setState(() {
      if (path.length >= 2 && path[path.length - 2] == idx) {
        path.removeLast(); // backtrack
      } else if (!path.contains(idx)) {
        path.add(idx);
        Sfx.tap();
      }
    });
  }

  void _onPanEnd(DragEndDetails d) {
    if (path.isEmpty || levelDone || over) return;
    final spelled = path.map((i) => letters[i]).join();
    final rev = spelled.split('').reversed.join();
    String? hit;
    for (final w in words) {
      if (found.contains(w)) continue;
      if (w == spelled || w == rev) {
        hit = w;
        break;
      }
    }
    if (hit != null) {
      Sfx.move();
      setState(() {
        found.add(hit!);
        path.clear();
        widget.players.first.score += 10;
        widget.callbacks.refreshHud();
        if (found.length == words.length) _levelCleared();
      });
    } else {
      Sfx.click();
      setState(() {
        _shakeWord = spelled;
        path.clear();
      });
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) setState(() => _shakeWord = '');
      });
    }
  }

  void _levelCleared() {
    levelDone = true;
    Sfx.win();
    widget.players.first.score += 25;
    widget.callbacks.refreshHud();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted || over) return;
      if (level >= maxLevel) {
        over = true;
        widget.callbacks.finish(
          headline: 'Word Link legend! 🔗👑',
          subline:
              'All $maxLevel levels linked! Your brain deserves a trophy and a nap.',
        );
      } else {
        setState(() => _loadLevel(level + 1));
      }
    });
  }

  void _shuffle() {
    if (levelDone || over) return;
    Sfx.click();
    // regenerate the board for the same words: new layout, same words stay findable
    setState(() {
      final rng = Random(DateTime.now().microsecondsSinceEpoch);
      final sz = size;
      for (int attempt = 0; attempt < 60; attempt++) {
        final grid = List<String>.filled(sz * sz, '');
        final order = [...words]..shuffle(rng);
        order.sort((a, b) => b.length.compareTo(a.length));
        bool okAll = true;
        for (final w in order) {
          bool placed = false;
          for (int t = 0; t < 250 && !placed; t++) {
            final start = rng.nextInt(sz * sz);
            if (grid[start] != '' && grid[start] != w[0]) continue;
            final p = [start];
            final used = {start};
            bool ok = true;
            for (int i = 1; i < w.length; i++) {
              final nbs = _neighbors(p.last, sz).where((x) => !used.contains(x)).toList()
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
              placed = true;
            }
          }
          if (!placed) {
            okAll = false;
            break;
          }
        }
        if (okAll) {
          const abc = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
          for (int i = 0; i < grid.length; i++) {
            if (grid[i] == '') grid[i] = abc[rng.nextInt(26)];
          }
          letters = grid;
          path.clear();
          break;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = ThemeController.of(context).theme;
    final current = path.map((i) => letters[i]).join();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text('Level $level',
                  style: TextStyle(
                      color: t.text, fontWeight: FontWeight.w800, fontSize: 18)),
              const Spacer(),
              Text('${found.length}/${words.length} words',
                  style: TextStyle(color: t.muted, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        // word chips
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: words.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final w = words[i];
              final done = found.contains(w);
              return Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: done
                      ? t.primary.withValues(alpha: 0.25)
                      : t.surface,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                      color: t.primary.withValues(alpha: done ? 0.6 : 0.25)),
                ),
                child: Text(
                  done ? w : '•' * w.length,
                  style: TextStyle(
                    color: done ? t.muted : t.text,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                    decoration: done ? TextDecoration.lineThrough : null,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        // current swipe preview
        SizedBox(
          height: 44,
          child: Center(
            child: _shakeWord.isNotEmpty && path.isEmpty
                ? Text('“$_shakeWord” — not a word here! 🙈',
                    style: TextStyle(
                        color: t.secondary, fontWeight: FontWeight.w800))
                : Text(
                    current.isEmpty ? 'Swipe letters to link a word 🔗' : current,
                    style: TextStyle(
                      color: current.isEmpty ? t.muted : t.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: current.isEmpty ? 14 : 30,
                      letterSpacing: 6,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 6),
        // letter grid
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GestureDetector(
                  key: _gridKey,
                  onPanStart: _onPanStart,
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: _onPanEnd,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: size,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                    ),
                    itemCount: size * size,
                    itemBuilder: (_, i) {
                      final inPath = path.contains(i);
                      final order =
                          inPath ? path.indexOf(i) + 1 : 0;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 90),
                        decoration: BoxDecoration(
                          gradient: inPath
                              ? LinearGradient(colors: [t.primary, t.secondary])
                              : null,
                          color: inPath ? null : t.surface,
                          borderRadius: t.radius,
                          border: Border.all(
                              color: t.primary.withValues(alpha: 0.3)),
                          boxShadow: inPath
                              ? [
                                  BoxShadow(
                                      color: t.primary.withValues(alpha: 0.45),
                                      blurRadius: 10)
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Text(letters[i],
                                style: TextStyle(
                                    fontSize: size == 5 ? 22 : 30,
                                    fontWeight: FontWeight.w900,
                                    color:
                                        inPath ? Colors.white : t.text)),
                            if (inPath)
                              Positioned(
                                right: 6,
                                top: 4,
                                child: Text('$order',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white70)),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        if (levelDone)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('Level $level cleared! 🎉 Next one coming…',
                style: TextStyle(
                    color: t.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 16)),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: WajihaButton(
              label: 'Shuffle letters', emoji: '🔀', onTap: _shuffle),
        ),
      ],
    );
  }
}

/// Built-in word pool (~200 words, 3-6 letters) used to generate all 60 levels.
const _words = [
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
