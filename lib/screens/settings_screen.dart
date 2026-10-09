import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/word_themes.dart';
import '../theme/widgets.dart';

/// Settings: audio toggles + volume, player name, journey progress reset.
class SettingsScreen extends StatefulWidget {
  final WordLinkAudio audio;
  final WordLinkSettings settings;
  const SettingsScreen(
      {super.key, required this.audio, required this.settings});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameCtrl = TextEditingController();

  WordThemeDef get _t => WordThemes.byId(
        widget.settings.themeId,
        custom: widget.settings.customTheme,
      );

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.settings.playerNames.first;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _applyAudio() {
    widget.audio.configure(
      musicOn: widget.settings.musicOn,
      sfxOn: widget.settings.sfxOn,
      volume: widget.settings.volume,
    );
    if (widget.settings.musicOn) widget.audio.startMenuMusic();
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final s = widget.settings;
    return WlBackdrop(
      theme: t,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: t.accent),
            onPressed: () {
              widget.audio.click();
              Navigator.of(context).pop();
            },
          ),
          title: Text('Settings', style: WlText.display(22, t)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: s,
            builder: (_, _) => ListView(
              padding: const EdgeInsets.all(22),
              children: [
                _section(t, 'SOUND & MUSIC', [
                  _switchRow(
                    t,
                    icon: Icons.music_note_outlined,
                    label: 'Music',
                    value: s.musicOn,
                    onChanged: (v) {
                      s.setMusic(v);
                      _applyAudio();
                    },
                  ),
                  _switchRow(
                    t,
                    icon: Icons.volume_up_outlined,
                    label: 'Sound effects',
                    value: s.sfxOn,
                    onChanged: (v) {
                      s.setSfx(v);
                      _applyAudio();
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.tune_outlined, color: t.muted),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Slider(
                            value: s.volume,
                            onChanged: (v) {
                              s.setVolume(v);
                              _applyAudio();
                            },
                            activeThumbColor: t.accent,
                            inactiveColor: t.boardEdge,
                          ),
                        ),
                        Text('${(s.volume * 100).round()}%',
                            style: WlText.body(13, t,
                                color: t.muted)),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 18),
                _section(t, 'PLAYER', [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.person_outline,
                            color: t.muted),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _nameCtrl,
                            style: WlText.title(16, t),
                            decoration: InputDecoration(
                              hintText: 'Your name',
                              hintStyle: WlText.body(14, t,
                                  color: t.muted),
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
                          },
                        ),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 18),
                _section(t, 'PROGRESS', [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Journey level ${s.journeyLevel} of 60 · ${s.wordsFound} words linked',
                          style: WlText.body(14, t),
                        ),
                        const SizedBox(height: 12),
                        WlButton(
                          label: 'Restart journey from level 1',
                          icon: Icons.restart_alt_outlined,
                          onTap: () {
                            widget.audio.click();
                            s.setJourneyLevel(1);
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Journey reset — level 1 awaits!',
                                    style: WlText.body(14, t)),
                                backgroundColor: t.boardEdge,
                                behavior:
                                    SnackBarBehavior.floating,
                              ),
                            );
                          },
                          theme: t,
                        ),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 18),
                _section(t, 'ABOUT', [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Image.asset('assets/wajiha_logo.png',
                            width: 34,
                            height: 34,
                            fit: BoxFit.contain),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Word Link · handcrafted with love by WAJIHA',
                            style: WlText.body(13, t,
                                color: t.muted),
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(WordThemeDef t, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: WlText.label(13, t)),
        const SizedBox(height: 8),
        Container(
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
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _switchRow(WordThemeDef t,
      {required IconData icon,
      required String label,
      required bool value,
      required ValueChanged<bool> onChanged}) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: t.muted),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: WlText.title(16, t))),
          Switch(
            value: value,
            onChanged: (v) {
              widget.audio.click();
              onChanged(v);
            },
            activeColor: t.accent,
          ),
        ],
      ),
    );
  }
}
