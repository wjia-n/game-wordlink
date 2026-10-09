import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import '../engine/wordlink_engine.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/word_themes.dart';
import '../theme/widgets.dart';

/// Game screen: renders the engine. The engine owns ALL phases and
/// transitions (deal -> play -> reveal -> level-clear -> over) plus a
/// watchdog, so stuck states are impossible by construction. The UI only
/// renders: animated letter placement, swipe trail, sequential word reveals,
/// overlays. Nothing ever pops in instantly.
class GameScreen extends StatefulWidget {
  final WordLinkEngine engine;
  final WordLinkAudio audio;
  final WordLinkSettings settings;
  final void Function(int level) onJourneyProgress;

  const GameScreen({
    super.key,
    required this.engine,
    required this.audio,
    required this.settings,
    required this.onJourneyProgress,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  static const _storeUrl =
      'https://play.google.com/store/apps/details?id=com.gameswajiha.wordlink';

  final _gridKey = GlobalKey();
  int _lastSeenLevel = 1;
  bool _reviewAsked = false;
  // The engine's watchdog notifies every 3s while the phase is `over`;
  // record stats exactly once per session.
  bool _statsRecorded = false;

  WordLinkEngine get _e => widget.engine;
  WordLinkAudio get _a => widget.audio;
  WordLinkSettings get _s => widget.settings;

  WordThemeDef get _t => WordThemes.byId(
        _s.themeId,
        custom: _s.customTheme,
      );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lastSeenLevel = _e.level;
    _e.onEvent = _onEngineEvent;
    _e.addListener(_onEngineChanged);
    _a.startGameMusic();
    _a.gameStart();
  }

  void _onEngineEvent(WlEvent ev) {
    switch (ev) {
      case WlEvent.letterAdded:
        _a.tick();
        break;
      case WlEvent.wordFound:
        _a.wordFound();
        break;
      case WlEvent.wordMissed:
        _a.invalid();
        break;
      case WlEvent.shuffle:
        _a.shuffle();
        break;
      case WlEvent.dealDone:
        _a.place();
        break;
      case WlEvent.levelClear:
        _a.win();
        break;
      case WlEvent.gameOver:
        _a.lose();
        break;
      case WlEvent.tickTock:
        _a.tickTock();
        break;
      case WlEvent.hintUsed:
        _a.hint();
        break;
      case WlEvent.gameStart:
        _a.gameStart();
        break;
    }
  }

  void _onEngineChanged() {
    if (!mounted) return;
    // Persist journey progress the moment the engine advances a level.
    if (_e.level != _lastSeenLevel) {
      _lastSeenLevel = _e.level;
      widget.onJourneyProgress(_e.level);
      // Sensible review moment: every 10th journey level, once per session.
      if (_e.mode == WlMode.journey && _e.level % 10 == 0 && !_reviewAsked) {
        _reviewAsked = true;
        _requestReview();
      }
    }
    // Sensible review moment: a finished blitz with a real score.
    if (_e.isOver && _e.mode == WlMode.blitz && !_reviewAsked && _e.score > 0) {
      _reviewAsked = true;
      _requestReview();
    }
    if (_e.isOver && !_statsRecorded) {
      _statsRecorded = true;
      final blitz = _e.mode == WlMode.blitz ? _e.score : 0;
      _s.recordGame(words: _e.wordsFoundTotal, blitzScore: blitz);
    }
  }

  /// Real in-app review flow, fully guarded: silent when unavailable or
  /// not installed from Play.
  Future<void> _requestReview() async {
    try {
      final review = InAppReview.instance;
      if (await review.isAvailable()) {
        await review.requestReview();
      }
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Freeze the engine while backgrounded; the watchdog re-arms on resume.
    if (state == AppLifecycleState.paused) {
      _e.setPaused(true);
    } else if (state == AppLifecycleState.resumed) {
      _e.setPaused(false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _e.removeListener(_onEngineChanged);
    _e.onEvent = null;
    _e.dispose();
    super.dispose();
  }

  int? _cellAt(Offset global) {
    final ctx = _gridKey.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject() as RenderBox;
    final local = box.globalToLocal(global);
    final size = _e.letters.isEmpty
        ? _e.gridSize
        : (widget.engine.letters.length == 9
            ? 3
            : (widget.engine.letters.length == 16 ? 4 : 5));
    final cell = box.size.width / size;
    final c = (local.dx / cell).floor();
    final r = (local.dy / cell).floor();
    if (r < 0 || r >= size || c < 0 || c >= size) return null;
    return r * size + c;
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    return WlBackdrop(
      theme: t,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListenableBuilder(
            listenable: _e,
            builder: (_, _) => Stack(
              children: [
                Column(
                  children: [
                    _hud(t),
                    const SizedBox(height: 6),
                    _wordChips(t),
                    const SizedBox(height: 6),
                    _previewBar(t),
                    const SizedBox(height: 4),
                    Expanded(child: _board(t)),
                    _actions(t),
                  ],
                ),
                if (_e.paused) _pauseOverlay(t),
                if (_e.phase == WlPhase.levelClear) _clearOverlay(t),
                if (_e.phase == WlPhase.over) _overOverlay(t),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------ HUD
  Widget _hud(WordThemeDef t) {
    final e = _e;
    String modeLabel;
    IconData modeIcon;
    String modeValue;
    switch (e.mode) {
      case WlMode.journey:
        modeLabel = 'Level';
        modeIcon = Icons.map_outlined;
        modeValue = '${e.level}';
        break;
      case WlMode.blitz:
        modeLabel = 'Time';
        modeIcon = Icons.timer_outlined;
        modeValue = _fmtTime(e.secondsLeft);
        break;
      case WlMode.relaxed:
        modeLabel = 'Board';
        modeIcon = Icons.spa_outlined;
        modeValue = '${e.found.length}/${e.words.length}';
        break;
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: t.accent),
            onPressed: () {
              _a.click();
              Navigator.of(context).pop();
            },
          ),
          StatChip(icon: modeIcon, text: '$modeLabel $modeValue', theme: t),
          const SizedBox(width: 8),
          StatChip(
              icon: Icons.star_outline,
              text: '${e.score}',
              theme: t),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.pause_outlined, color: t.accent),
            onPressed: () {
              _a.click();
              _e.setPaused(true);
            },
          ),
        ],
      ),
    );
  }

  String _fmtTime(int s) {
    final m = (s ~/ 60).clamp(0, 99);
    final r = (s % 60).clamp(0, 59);
    return '$m:${r.toString().padLeft(2, '0')}';
  }

  // ------------------------------------------------------------- word chips
  Widget _wordChips(WordThemeDef t) {
    final e = _e;
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: e.words.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final w = e.words[i];
          final done = e.found.contains(w);
          final hinted = e.hinted[w] ?? 0;
          // Progressive reveal: a found word shows letters one by one
          // during the reveal animation, then settles struck-through.
          int show = w.length;
          if (!done && e.revealWord == w) {
            show = e.revealCount.clamp(0, w.length);
          }
          return AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: done ? t.chipFound : t.chip,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                color: (done || e.revealWord == w)
                    ? t.found
                    : t.boardEdge,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int k = 0; k < w.length; k++)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 140),
                    transitionBuilder: (child, anim) => ScaleTransition(
                        scale: anim, child: child),
                    child: Text(
                      _chipChar(w, k, done, hinted, show),
                      key: ValueKey(
                          '$w-$k-${_chipChar(w, k, done, hinted, show)}'),
                      style: TextStyle(
                        color: done
                            ? t.text.withValues(alpha: 0.85)
                            : (k < hinted ? t.accent : t.muted),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        fontSize: 14,
                        decoration:
                            done ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _chipChar(String w, int k, bool done, int hinted, int show) {
    if (done) return w[k];
    if (eReveal(w, k, show)) return w[k];
    if (k < hinted) return w[k];
    return '•';
  }

  bool eReveal(String w, int k, int show) =>
      _e.revealWord == w && k < show;

  // ------------------------------------------------------------- preview
  Widget _previewBar(WordThemeDef t) {
    final e = _e;
    final current = e.preview;
    return SizedBox(
      height: 46,
      child: Center(
        child: e.missNonce > 0 && current.isEmpty && e.missWord.isNotEmpty
            ? ShakeText(
                text: '“${e.missWord}” — not a word here!',
                theme: t,
                nonce: e.missNonce,
              )
            : Text(
                current.isEmpty
                    ? 'Swipe letters to link a word'
                    : current,
                style: TextStyle(
                  color: current.isEmpty ? t.muted : t.accent,
                  fontWeight: FontWeight.w900,
                  fontSize: current.isEmpty ? 14 : 30,
                  letterSpacing: 6,
                  shadows: current.isEmpty
                      ? null
                      : [
                          Shadow(
                              color:
                                  Colors.black.withValues(alpha: 0.5),
                              offset: const Offset(0, 2),
                              blurRadius: 4),
                        ],
                ),
              ),
      ),
    );
  }

  // ---------------------------------------------------------------- board
  Widget _board(WordThemeDef t) {
    final e = _e;
    final size = e.letters.isEmpty
        ? e.gridSize
        : (e.letters.length == 9
            ? 3
            : (e.letters.length == 16 ? 4 : 5));
    return Center(
      child: AspectRatio(
        aspectRatio: 1,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Container(
            decoration: BoxDecoration(
              color: t.board,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: t.boardEdge, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.55),
                  offset: const Offset(0, 8),
                  blurRadius: 18,
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.08),
                  offset: const Offset(0, -3),
                  blurRadius: 4,
                ),
              ],
            ),
            padding: const EdgeInsets.all(10),
            child: GestureDetector(
              key: _gridKey,
              onPanStart: (d) {
                final idx = _cellAt(d.globalPosition);
                if (idx != null) _e.swipeStart(idx);
              },
              onPanUpdate: (d) {
                final idx = _cellAt(d.globalPosition);
                if (idx != null) _e.swipeMove(idx);
              },
              onPanEnd: (_) => _e.swipeEnd(),
              onPanCancel: () => _e.swipeEnd(),
              child: LayoutBuilder(
                builder: (ctx, constraints) {
                  final cell =
                      constraints.biggest.width / size;
                  final centers = <int, Offset>{};
                  for (int r = 0; r < size; r++) {
                    for (int c = 0; c < size; c++) {
                      centers[r * size + c] = Offset(
                          (c + 0.5) * cell, (r + 0.5) * cell);
                    }
                  }
                  final trail = e.path
                      .map((i) => centers[i]!)
                      .toList();
                  return Stack(
                    children: [
                      GridView.builder(
                        physics:
                            const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: size,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                        itemCount: size * size,
                        itemBuilder: (_, i) {
                          final inPath = e.path.contains(i);
                          final order = inPath
                              ? e.path.indexOf(i) + 1
                              : 0;
                          // Reveal pulse: tiles of the just-found word
                          // light up in sequence with the chip.
                          final revealIdx =
                              e.lastFoundPath.indexOf(i);
                          final pulsing = e.phase ==
                                  WlPhase.evaluating &&
                              revealIdx >= 0 &&
                              revealIdx < e.revealCount;
                          final foundTile =
                              e.foundCells.contains(i);
                          final shown = i < e.dealtCount;
                          return WlTile(
                            letter: i < e.letters.length
                                ? e.letters[i]
                                : '',
                            theme: t,
                            shape: _s.tileStyle,
                            selected: inPath || pulsing,
                            foundState:
                                foundTile && !inPath && !pulsing,
                            reveal: shown ? 1.0 : 0.0,
                            selectOrder: order,
                          );
                        },
                      ),
                      if (trail.length >= 2)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: TrailPainter(
                                points: trail,
                                color: t.selected,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------- actions
  Widget _actions(WordThemeDef t) {
    final e = _e;
    final hintLabel = _s.isPro ? 'Hint ∞' : 'Hint ${e.hintsLeft}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: WlButton(
              label: 'Shuffle',
              icon: Icons.shuffle,
              onTap: () => _e.shuffle(),
              theme: t,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Opacity(
              opacity: e.canHint ? 1.0 : 0.5,
              child: WlButton(
                label: hintLabel,
                icon: Icons.lightbulb_outline,
                onTap: () {
                  if (!e.canHint && !_s.isPro) {
                    _a.invalid();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Out of hints — PRO players get unlimited hints!',
                          style: WlText.body(14, t),
                        ),
                        backgroundColor: t.boardEdge,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }
                  _e.useHint();
                },
                theme: t,
                locked: !e.canHint && !_s.isPro,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------- overlays
  Widget _pauseOverlay(WordThemeDef t) {
    return _overlayCard(
      t,
      icon: Icons.pause_circle_outline,
      title: 'Paused',
      subtitle: 'Take a breath — the tiles will wait.',
      buttons: [
        WlButton(
            label: 'Resume',
            icon: Icons.play_arrow,
            onTap: () {
              _a.click();
              _e.setPaused(false);
            },
            theme: t,
            primary: true),
        const SizedBox(height: 10),
        WlButton(
            label: 'Restart board',
            icon: Icons.refresh,
            onTap: () {
              _a.click();
              _e.setPaused(false);
              _e.restartBoard();
            },
            theme: t),
        const SizedBox(height: 10),
        WlButton(
            label: 'Quit to menu',
            icon: Icons.home_outlined,
            onTap: () {
              _a.click();
              Navigator.of(context).pop();
            },
            theme: t),
      ],
    );
  }

  Widget _clearOverlay(WordThemeDef t) {
    final e = _e;
    return _overlayCard(
      t,
      icon: Icons.emoji_events_outlined,
      title: e.mode == WlMode.journey
          ? 'Level ${e.level} cleared!'
          : 'Board cleared!',
      subtitle: e.mode == WlMode.journey
          ? 'Beautiful linking, ${_s.playerNames.first}. Next board is being carved…'
          : '+50 bonus — fresh tiles incoming!',
      buttons: const [],
      auto: true,
    );
  }

  Widget _overOverlay(WordThemeDef t) {
    final e = _e;
    final isBlitz = e.mode == WlMode.blitz;
    final title = e.mode == WlMode.journey
        ? 'Journey complete!'
        : (isBlitz ? 'Time\u2019s up!' : 'Lovely session!');
    final subtitle = e.mode == WlMode.journey
        ? 'All 60 levels linked, ${_s.playerNames.first}. True word royalty!'
        : (isBlitz
            ? 'You linked ${e.wordsFoundTotal} words for ${e.score} points!'
            : 'You linked ${e.wordsFoundTotal} words. The tiles applaud you.');
    return _overlayCard(
      t,
      icon: isBlitz ? Icons.timer_off_outlined : Icons.emoji_events_outlined,
      title: title,
      subtitle: subtitle,
      buttons: [
        if (isBlitz)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text('Best Blitz: ${_s.bestBlitz}',
                style: WlText.title(16, t)),
          ),
        WlButton(
            label: 'Play again',
            icon: Icons.replay,
            onTap: () {
              _a.click();
              Navigator.of(context).pop();
            },
            theme: t,
            primary: true),
        const SizedBox(height: 10),
        WlButton(
            label: 'Share',
            icon: Icons.share_outlined,
            onTap: () async {
              _a.click();
              await SharePlus.instance.share(
                ShareParams(
                  text: '$subtitle\nCan you beat me in Word Link? 🔗\n$_storeUrl',
                  subject: 'Word Link',
                ),
              );
            },
            theme: t),
        const SizedBox(height: 10),
        WlButton(
            label: 'Menu',
            icon: Icons.home_outlined,
            onTap: () {
              _a.click();
              Navigator.of(context).pop();
            },
            theme: t),
      ],
    );
  }

  Widget _overlayCard(WordThemeDef t,
      {required IconData icon,
      required String title,
      required String subtitle,
      required List<Widget> buttons,
      bool auto = false}) {
    return Container(
      color: Colors.black.withValues(alpha: 0.55),
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.7, end: 1.0),
          duration: const Duration(milliseconds: 350),
          curve: Curves.elasticOut,
          builder: (_, v, child) =>
              Transform.scale(scale: v, child: child),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 36),
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: t.board,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: t.accent, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  offset: const Offset(0, 12),
                  blurRadius: 28,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 56, color: t.accent),
                const SizedBox(height: 12),
                Text(title,
                    style: WlText.display(26, t),
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(subtitle,
                    style: WlText.body(14, t, color: t.muted),
                    textAlign: TextAlign.center),
                if (buttons.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  ...buttons,
                ],
                if (auto) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 160,
                    child: LinearProgressIndicator(
                      color: t.accent,
                      backgroundColor:
                          Colors.black.withValues(alpha: 0.3),
                      minHeight: 6,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
