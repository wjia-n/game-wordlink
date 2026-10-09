import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/word_themes.dart';
import '../theme/widgets.dart';
import 'menu_screen.dart';

/// Launch splash: game logo + name, animated loading line, and credits.
/// (Single splash only — no separate company moment.)
class SplashScreen extends StatefulWidget {
  final WordLinkAudio audio;
  final WordLinkSettings settings;
  const SplashScreen({super.key, required this.audio, required this.settings});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loader;

  @override
  void initState() {
    super.initState();
    _loader = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _run();
  }

  Future<void> _run() async {
    // Pre-warm audio while the splash shows, then start menu music.
    widget.audio.prewarm();
    widget.audio.startMenuMusic();
    _loader.forward();
    await Future.delayed(const Duration(milliseconds: 1900));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MenuScreen(
          audio: widget.audio,
          settings: widget.settings,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _loader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = WordThemes.byId(
      widget.settings.themeId,
      custom: widget.settings.customTheme,
    );
    return Scaffold(
      backgroundColor: theme.bgBottom,
      body: WlBackdrop(
        theme: theme,
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: theme.accent, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        offset: const Offset(0, 10),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset('assets/wordlink_logo.png',
                      fit: BoxFit.cover),
                ),
                const SizedBox(height: 22),
                Text('Word Link', style: WlText.display(52, theme)),
                const SizedBox(height: 6),
                Text(
                  'THE WOODWORKER\u2019S STUDY EDITION',
                  style: WlText.label(13, theme),
                ),
                const SizedBox(height: 30),
                // Animated loading line.
                SizedBox(
                  width: 220,
                  child: AnimatedBuilder(
                    animation: _loader,
                    builder: (_, _) => Column(
                      children: [
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: Colors.black.withValues(alpha: 0.45),
                            border: Border.all(
                                color: theme.accent.withValues(alpha: 0.5)),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: _loader.value.clamp(0.02, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(3),
                                color: theme.accent,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _loader.value < 1
                              ? 'Carving the tiles…'
                              : 'Ready!',
                          style: WlText.body(13, theme,
                              color: theme.text.withValues(alpha: 0.75)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 44),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/wajiha_logo.png',
                      width: 30,
                      height: 30,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Credits: WAJIHA',
                      style: WlText.label(14, theme),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
