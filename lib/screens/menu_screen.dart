import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import '../engine/wordlink_engine.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/word_themes.dart';
import '../theme/widgets.dart';
import 'custom_theme_screen.dart';
import 'game_screen.dart';
import 'pro_screen.dart';
import 'settings_screen.dart';

/// Main menu: game identity, renameable player, mode cards (Journey / Blitz
/// / Relaxed), difficulty tiers, theme picker, Pro / settings / share.
class MenuScreen extends StatefulWidget {
  final WordLinkAudio audio;
  final WordLinkSettings settings;
  const MenuScreen({super.key, required this.audio, required this.settings});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  static const _storeUrl =
      'https://play.google.com/store/apps/details?id=com.gameswajiha.wordlink';

  final _store = StoreService();
  final _nameCtrl = TextEditingController();

  WordThemeDef get _t => WordThemes.byId(
        widget.settings.themeId,
        custom: widget.settings.customTheme,
      );

  @override
  void initState() {
    super.initState();
    _store.init();
    _nameCtrl.text = widget.settings.playerNames.first;
    widget.audio.startMenuMusic();
    _store.proPurchased.addListener(_onPro);
    _store.lastThanks.addListener(_onThanks);
  }

  void _onPro() {
    if (_store.proPurchased.value && mounted) {
      widget.settings.setPro(true);
      _store.proPurchased.value = false;
      widget.audio.win();
      setState(() {});
    }
  }

  void _onThanks() {
    final msg = _store.lastThanks.value;
    if (msg == null || !mounted) return;
    widget.audio.win();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: WlText.body(15, _t)),
        backgroundColor: _t.boardEdge,
        behavior: SnackBarBehavior.floating,
      ),
    );
    _store.lastThanks.value = null;
  }

  @override
  void dispose() {
    _store.proPurchased.removeListener(_onPro);
    _store.lastThanks.removeListener(_onThanks);
    _store.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  /// Real in-app review flow: the Play in-app review sheet when available,
  /// otherwise fall back to opening the store listing. No fake dialogs.
  Future<void> _requestReview() async {
    final review = InAppReview.instance;
    try {
      if (await review.isAvailable()) {
        await review.requestReview();
      } else {
        await review.openStoreListing();
      }
    } catch (_) {
      // Review UI unavailable on this device/build: stay silent, no fake UI.
    }
  }

  void _play() {
    widget.audio.gameStart();
    final engine = WordLinkEngine(
      mode: WlMode.values[widget.settings.mode],
      difficulty: widget.settings.difficulty,
      startLevel: widget.settings.journeyLevel,
    );
    engine.proUnlimitedHints = widget.settings.isPro;
    // App-scoped music: keep playing across screens. GameScreen switches
    // to the game track on entry; we switch back to menu music on return.
    Navigator.of(context)
        .push(MaterialPageRoute(
      builder: (_) => GameScreen(
        engine: engine,
        audio: widget.audio,
        settings: widget.settings,
        onJourneyProgress: (lv) =>
            widget.settings.setJourneyLevel(lv),
      ),
    ))
        .then((_) {
      if (mounted) widget.audio.startMenuMusic();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final s = widget.settings;
    return WlBackdrop(
      theme: t,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListenableBuilder(
            listenable: s,
            builder: (_, _) => SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              child: Column(
                children: [
                  // Header: logo + title.
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border:
                              Border.all(color: t.accent, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              offset: const Offset(0, 4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset('assets/wordlink_logo.png',
                            fit: BoxFit.cover),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Word Link',
                                style: WlText.display(32, t)),
                            Text(
                              'Swipe, link, and unleash your inner word wizard!',
                              style: WlText.body(13, t, color: t.muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Renameable player.
                  _nameCard(t, s),
                  const SizedBox(height: 18),
                  // Mode cards.
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('CHOOSE YOUR GAME',
                        style: WlText.label(13, t)),
                  ),
                  const SizedBox(height: 10),
                  _modeCard(
                    t,
                    icon: Icons.map_outlined,
                    title: 'Journey',
                    subtitle:
                        '60 hand-carved levels · you are on level ${s.journeyLevel}',
                    selected: s.mode == 0,
                    onTap: () {
                      widget.audio.click();
                      s.setMode(0);
                    },
                  ),
                  const SizedBox(height: 10),
                  _modeCard(
                    t,
                    icon: Icons.timer_outlined,
                    title: 'Blitz',
                    subtitle: '2 minutes · link as many words as you can',
                    selected: s.mode == 1,
                    onTap: () {
                      widget.audio.click();
                      s.setMode(1);
                    },
                  ),
                  const SizedBox(height: 10),
                  _modeCard(
                    t,
                    icon: Icons.spa_outlined,
                    title: 'Relaxed',
                    subtitle: 'No timer · just you and the tiles',
                    selected: s.mode == 2,
                    onTap: () {
                      widget.audio.click();
                      s.setMode(2);
                    },
                  ),
                  const SizedBox(height: 18),
                  // Difficulty tiers.
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('DIFFICULTY',
                        style: WlText.label(13, t)),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (int i = 0; i < 3; i++)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                                right: i < 2 ? 8 : 0),
                            child: _difficultyCard(t, s, i),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Play.
                  SizedBox(
                    width: double.infinity,
                    child: WlButton(
                      label: 'Start Linking',
                      icon: Icons.play_arrow,
                      onTap: _play,
                      theme: t,
                      primary: true,
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Theme picker.
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Text('WORKSHOP THEMES',
                            style: WlText.label(13, t)),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            widget.audio.click();
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => CustomThemeScreen(
                                audio: widget.audio,
                                settings: s,
                              ),
                            ));
                          },
                          child: Text(
                            s.isPro ? 'Create my own →' : 'Unlock more with PRO →',
                            style: WlText.body(13, t, color: t.accent),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _themeGrid(t, s),
                  const SizedBox(height: 20),
                  // Secondary actions.
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      WlButton(
                        label: 'Tiles',
                        icon: Icons.dashboard_customize_outlined,
                        onTap: () => _tileStyleSheet(t, s),
                        theme: t,
                      ),
                      WlButton(
                        label: s.isPro ? 'PRO ✓' : 'PRO',
                        icon: Icons.workspace_premium_outlined,
                        onTap: () {
                          widget.audio.click();
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => ProScreen(
                              audio: widget.audio,
                              settings: s,
                              store: _store,
                            ),
                          ));
                        },
                        theme: t,
                        primary: !s.isPro,
                      ),
                      WlButton(
                        label: 'Settings',
                        icon: Icons.settings_outlined,
                        onTap: () {
                          widget.audio.click();
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => SettingsScreen(
                              audio: widget.audio,
                              settings: s,
                            ),
                          ));
                        },
                        theme: t,
                      ),
                      WlButton(
                        label: 'Share',
                        icon: Icons.share_outlined,
                        onTap: () async {
                          widget.audio.click();
                          await SharePlus.instance.share(
                            ShareParams(
                              text: 'I\'m linking words in Word Link — swipe through letter tiles and find every hidden word! 🔗\n$_storeUrl',
                              subject: 'Word Link',
                            ),
                          );
                        },
                        theme: t,
                      ),
                      WlButton(
                        label: 'Rate',
                        icon: Icons.star_outline,
                        onTap: () async {
                          widget.audio.click();
                          await _requestReview();
                        },
                        theme: t,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Best Blitz: ${s.bestBlitz} · Words linked: ${s.wordsFound}',
                    style: WlText.label(12, t),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _nameCard(WordThemeDef t, WordLinkSettings s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: t.board,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.boardEdge, width: 2),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              offset: const Offset(0, 3),
              blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.person_outline, color: t.accent),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _nameCtrl,
              style: WlText.title(16, t),
              decoration: InputDecoration(
                hintText: 'Your name',
                hintStyle: WlText.body(14, t, color: t.muted),
                border: InputBorder.none,
                isDense: true,
              ),
              maxLength: 16,
              onSubmitted: (v) {
                widget.audio.click();
                s.setPlayerName(v);
                setState(() {});
              },
            ),
          ),
          IconButton(
            icon: Icon(Icons.check, color: t.accent),
            onPressed: () {
              widget.audio.click();
              s.setPlayerName(_nameCtrl.text);
              FocusScope.of(context).unfocus();
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _modeCard(WordThemeDef t,
      {required IconData icon,
      required String title,
      required String subtitle,
      required bool selected,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? Color.lerp(t.board, t.accent, 0.18)!
              : t.board,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: selected ? t.accent : t.boardEdge, width: 2),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                offset: const Offset(0, 3),
                blurRadius: 8),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? t.accent : t.muted, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: WlText.title(17, t)),
                  Text(subtitle,
                      style: WlText.body(12, t, color: t.muted)),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, color: t.accent),
          ],
        ),
      ),
    );
  }

  Widget _difficultyCard(WordThemeDef t, WordLinkSettings s, int i) {
    final selected = s.difficulty == i;
    final locked = WlDifficulty.isPro(i) && !s.isPro;
    return GestureDetector(
      onTap: () {
        if (locked) {
          widget.audio.invalid();
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ProScreen(
                audio: widget.audio, settings: s, store: _store),
          ));
          return;
        }
        widget.audio.click();
        s.setDifficulty(i);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: selected
              ? Color.lerp(t.board, t.accent, 0.18)!
              : t.board,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected ? t.accent : t.boardEdge, width: 2),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(WlDifficulty.names[i],
                    style: WlText.title(14, t)),
                if (locked) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.lock, size: 13, color: t.muted),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              WlDifficulty.descriptions[i],
              style: WlText.body(10, t, color: t.muted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _themeGrid(WordThemeDef t, WordLinkSettings s) {
    final themes = WordThemes.all;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.78,
      ),
      itemCount: themes.length,
      itemBuilder: (_, i) {
        final th = themes[i];
        final selected = s.themeId == th.id;
        final locked = th.isPro && !s.isPro;
        return GestureDetector(
          onTap: () {
            if (locked) {
              widget.audio.invalid();
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ProScreen(
                    audio: widget.audio, settings: s, store: _store),
              ));
              return;
            }
            widget.audio.click();
            s.setTheme(th.id);
          },
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: selected ? t.accent : th.boardEdge,
                      width: selected ? 3 : 2),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        offset: const Offset(0, 3),
                        blurRadius: 6),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          Expanded(
                              child: Container(color: th.tileFace)),
                          Expanded(
                              child: Container(color: th.board)),
                        ],
                      ),
                      Center(
                        child: Text('A',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: th.letter)),
                      ),
                      if (locked)
                        Container(
                          color:
                              Colors.black.withValues(alpha: 0.45),
                          child: const Center(
                            child: Icon(Icons.lock,
                                size: 18, color: Colors.white70),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                th.name,
                style: WlText.body(9, t,
                    color: selected ? t.accent : t.muted),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  void _tileStyleSheet(WordThemeDef t, WordLinkSettings s) {
    widget.audio.click();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: t.board,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: t.boardEdge, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Letter tile style', style: WlText.title(18, t)),
            const SizedBox(height: 6),
            Text(
              s.isPro
                  ? 'Pick your carving'
                  : 'First 4 free — the rest unlock with PRO',
              style: WlText.body(12, t, color: t.muted),
            ),
            const SizedBox(height: 14),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: TileStyles.names.length,
              itemBuilder: (_, i) {
                final locked =
                    TileStyles.isPro(i) && !s.isPro;
                final selected = s.tileStyle == i;
                return GestureDetector(
                  onTap: () {
                    if (locked) {
                      widget.audio.invalid();
                      Navigator.of(context).pop();
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ProScreen(
                            audio: widget.audio,
                            settings: s,
                            store: _store),
                      ));
                      return;
                    }
                    widget.audio.click();
                    s.setTileStyle(i);
                    Navigator.of(context).pop();
                  },
                  child: Column(
                    children: [
                      SizedBox(
                        width: 56,
                        height: 56,
                        child: Stack(
                          children: [
                            WlTile(
                              letter: 'W',
                              theme: t,
                              shape: i,
                              selected: selected,
                            ),
                            if (locked)
                              const Positioned(
                                right: 0,
                                top: 0,
                                child: Icon(Icons.lock,
                                    size: 16,
                                    color: Colors.white70),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        TileStyles.names[i],
                        style: WlText.body(9, t,
                            color: selected ? t.accent : t.muted),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
