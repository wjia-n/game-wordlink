import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/word_themes.dart';
import '../theme/widgets.dart';

/// Custom theme creator (PRO): pick every workshop color and preview the
/// result live on a sample tile.
class CustomThemeScreen extends StatefulWidget {
  final WordLinkAudio audio;
  final WordLinkSettings settings;
  const CustomThemeScreen(
      {super.key, required this.audio, required this.settings});

  @override
  State<CustomThemeScreen> createState() => _CustomThemeScreenState();
}

class _CustomThemeScreenState extends State<CustomThemeScreen> {
  String _editing = 'tileFace';

  WordThemeDef get _t => WordThemes.byId(
        'custom',
        custom: widget.settings.customTheme,
      );

  // A friendly workshop palette to pick from (physical, warm, no neon).
  static const List<int> _palette = [
    0xFF4A2F1B, 0xFF6B4226, 0xFF8A5A30, 0xFFB98A3E, 0xFFE8C77E, 0xFFF7ECD2,
    0xFF3E2A22, 0xFF5C2A1E, 0xFF7A3B26, 0xFFC08A45, 0xFFF2D38B, 0xFFFFF6DC,
    0xFF3A4430, 0xFF4E5B3E, 0xFF55643A, 0xFF6FBF73, 0xFFEDDCA8, 0xFFF6F0DA,
    0xFF3B4048, 0xFF4D545E, 0xFF7FB3D5, 0xFF9BA1B8, 0xFFD8D4C4, 0xFFF0EEE4,
    0xFF2B3350, 0xFF3B4460, 0xFFE8C766, 0xFF9C6B1E, 0xFFD94F2B, 0xFFB8452F,
    0xFF2E3A33, 0xFF37473D, 0xFF5E8F4E, 0xFF8FD694, 0xFF3A2410, 0xFF221410,
  ];

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final s = widget.settings;
    final keys = WordThemes.defaultCustomColors.keys.toList();
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
          title: Text('My Creation', style: WlText.display(22, t)),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: t.accent),
              tooltip: 'Reset colors',
              onPressed: () {
                widget.audio.click();
                s.resetCustomColors();
                setState(() {});
              },
            ),
          ],
        ),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: s,
            builder: (_, _) => Column(
              children: [
                // Live preview.
                Container(
                  margin: const EdgeInsets.all(18),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: t.board,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: t.boardEdge, width: 2),
                    boxShadow: [
                      BoxShadow(
                          color:
                              Colors.black.withValues(alpha: 0.4),
                          offset: const Offset(0, 4),
                          blurRadius: 10),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                          width: 64,
                          height: 64,
                          child: WlTile(
                              letter: 'W',
                              theme: t,
                              shape: s.tileStyle)),
                      const SizedBox(width: 8),
                      SizedBox(
                          width: 64,
                          height: 64,
                          child: WlTile(
                              letter: 'L',
                              theme: t,
                              shape: s.tileStyle,
                              selected: true)),
                      const SizedBox(width: 8),
                      SizedBox(
                          width: 64,
                          height: 64,
                          child: WlTile(
                              letter: 'K',
                              theme: t,
                              shape: s.tileStyle,
                              foundState: true)),
                    ],
                  ),
                ),
                // Color keys.
                SizedBox(
                  height: 46,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    itemCount: keys.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final k = keys[i];
                      final selected = _editing == k;
                      return GestureDetector(
                        onTap: () {
                          widget.audio.click();
                          setState(() => _editing = k);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected
                                ? Color.lerp(
                                        t.board, t.accent, 0.25)!
                                : t.board,
                            borderRadius:
                                BorderRadius.circular(99),
                            border: Border.all(
                              color: selected
                                  ? t.accent
                                  : t.boardEdge,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Color(s.customColors[k]!),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.black26),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                WordThemes.customColorLabels[k]!,
                                style: WlText.body(12, t),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
                // Palette.
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                    ),
                    itemCount: _palette.length,
                    itemBuilder: (_, i) {
                      final c = _palette[i];
                      final selected =
                          s.customColors[_editing] == c;
                      return GestureDetector(
                        onTap: () {
                          widget.audio.tick();
                          s.setCustomColor(_editing, c);
                          setState(() {});
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Color(c),
                            borderRadius:
                                BorderRadius.circular(12),
                            border: Border.all(
                              color: selected
                                  ? t.accent
                                  : Colors.black26,
                              width: selected ? 3 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black
                                      .withValues(alpha: 0.35),
                                  offset: const Offset(0, 2),
                                  blurRadius: 4),
                            ],
                          ),
                          child: selected
                              ? const Icon(Icons.check,
                                  color: Colors.white)
                              : null,
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: SizedBox(
                    width: double.infinity,
                    child: WlButton(
                      label: 'Use this theme',
                      icon: Icons.check,
                      onTap: () {
                        widget.audio.click();
                        s.setTheme('custom');
                        Navigator.of(context).pop();
                      },
                      theme: t,
                      primary: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
