import 'package:flutter/material.dart';

/// Art direction: "The Woodworker's Study" — handcrafted wooden letter tiles,
/// carved bevels, warm physical materials. Pseudo-3D, no neon anywhere.
///
/// Every theme is a complete color scheme for the backdrop, board, tiles,
/// letters and UI accents. The first 6 are free; the rest are Pro.
class WordThemeDef {
  final String id;
  final String name;
  final bool isPro;
  final Color bgTop;
  final Color bgBottom;
  final Color board;
  final Color boardEdge;
  final Color tileFace;
  final Color tileBevel;
  final Color tileShadow;
  final Color letter;
  final Color letterShadow;
  final Color selected;
  final Color found;
  final Color accent;
  final Color text;
  final Color muted;
  final Color chip;
  final Color chipFound;

  const WordThemeDef({
    required this.id,
    required this.name,
    this.isPro = false,
    required this.bgTop,
    required this.bgBottom,
    required this.board,
    required this.boardEdge,
    required this.tileFace,
    required this.tileBevel,
    required this.tileShadow,
    required this.letter,
    required this.letterShadow,
    required this.selected,
    required this.found,
    required this.accent,
    required this.text,
    required this.muted,
    required this.chip,
    required this.chipFound,
  });
}

class WordThemes {
  static const List<WordThemeDef> all = [
    WordThemeDef(
      id: 'oak',
      name: 'Classic Oak',
      bgTop: Color(0xFF4A2F1B),
      bgBottom: Color(0xFF2A1A0E),
      board: Color(0xFF6B4226),
      boardEdge: Color(0xFF3A2210),
      tileFace: Color(0xFFE8C77E),
      tileBevel: Color(0xFFB98A3E),
      tileShadow: Color(0xFF000000),
      letter: Color(0xFF4A2C10),
      letterShadow: Color(0xFFFFF3D6),
      selected: Color(0xFFFFB627),
      found: Color(0xFF7BC96F),
      accent: Color(0xFFFFB627),
      text: Color(0xFFFFF3DC),
      muted: Color(0xFFC9A876),
      chip: Color(0xFF5A3A1E),
      chipFound: Color(0xFF2E5B33),
    ),
    WordThemeDef(
      id: 'walnut',
      name: 'Walnut Library',
      bgTop: Color(0xFF3E2A22),
      bgBottom: Color(0xFF221410),
      board: Color(0xFF54402F),
      boardEdge: Color(0xFF2C1D14),
      tileFace: Color(0xFFD9B878),
      tileBevel: Color(0xFF9A7438),
      tileShadow: Color(0xFF000000),
      letter: Color(0xFF3A2410),
      letterShadow: Color(0xFFFFE9C4),
      selected: Color(0xFFE09112),
      found: Color(0xFF6FAE5F),
      accent: Color(0xFFE09112),
      text: Color(0xFFF7E8CC),
      muted: Color(0xFFB99B72),
      chip: Color(0xFF463327),
      chipFound: Color(0xFF2F5230),
    ),
    WordThemeDef(
      id: 'cherry',
      name: 'Cherry Cheer',
      bgTop: Color(0xFF5C2A1E),
      bgBottom: Color(0xFF35150E),
      board: Color(0xFF7A3B26),
      boardEdge: Color(0xFF451D10),
      tileFace: Color(0xFFF2D38B),
      tileBevel: Color(0xFFC08A45),
      tileShadow: Color(0xFF000000),
      letter: Color(0xFF5C2410),
      letterShadow: Color(0xFFFFF6DC),
      selected: Color(0xFFFF8C42),
      found: Color(0xFF7FBF6A),
      accent: Color(0xFFFF8C42),
      text: Color(0xFFFFF0D8),
      muted: Color(0xFFD9A87E),
      chip: Color(0xFF63301F),
      chipFound: Color(0xFF33572F),
    ),
    WordThemeDef(
      id: 'pine',
      name: 'Pine Cabin',
      bgTop: Color(0xFF3A4430),
      bgBottom: Color(0xFF1E241A),
      board: Color(0xFF4E5B3E),
      boardEdge: Color(0xFF28301F),
      tileFace: Color(0xFFEDDCA8),
      tileBevel: Color(0xFFB9A05E),
      tileShadow: Color(0xFF000000),
      letter: Color(0xFF33401E),
      letterShadow: Color(0xFFFFF8E0),
      selected: Color(0xFFE8B33C),
      found: Color(0xFF6FBF73),
      accent: Color(0xFFE8B33C),
      text: Color(0xFFF4EED6),
      muted: Color(0xFFB3AC86),
      chip: Color(0xFF3F4A32),
      chipFound: Color(0xFF2E5A34),
    ),
    WordThemeDef(
      id: 'bamboo',
      name: 'Bamboo Garden',
      bgTop: Color(0xFF3D4A24),
      bgBottom: Color(0xFF202712),
      board: Color(0xFF55643A),
      boardEdge: Color(0xFF2E3818),
      tileFace: Color(0xFFF3E3B0),
      tileBevel: Color(0xFFC0A45C),
      tileShadow: Color(0xFF000000),
      letter: Color(0xFF3A4420),
      letterShadow: Color(0xFFFFFAE2),
      selected: Color(0xFFD9A441),
      found: Color(0xFF78C26E),
      accent: Color(0xFFD9A441),
      text: Color(0xFFF6F0DA),
      muted: Color(0xFFBDB488),
      chip: Color(0xFF47552E),
      chipFound: Color(0xFF2F5C32),
    ),
    WordThemeDef(
      id: 'slate',
      name: 'River Stone',
      bgTop: Color(0xFF3B4048),
      bgBottom: Color(0xFF20242B),
      board: Color(0xFF4D545E),
      boardEdge: Color(0xFF2A2F36),
      tileFace: Color(0xFFD8D4C4),
      tileBevel: Color(0xFF9A9584),
      tileShadow: Color(0xFF000000),
      letter: Color(0xFF33383F),
      letterShadow: Color(0xFFF5F2E6),
      selected: Color(0xFF7FB3D5),
      found: Color(0xFF7BC96F),
      accent: Color(0xFF7FB3D5),
      text: Color(0xFFF0EEE4),
      muted: Color(0xFFA8A494),
      chip: Color(0xFF41474F),
      chipFound: Color(0xFF2E5A34),
    ),
    WordThemeDef(
      id: 'typewriter',
      name: 'Vintage Typewriter',
      isPro: true,
      bgTop: Color(0xFF3A3733),
      bgBottom: Color(0xFF1E1C19),
      board: Color(0xFF2C2A26),
      boardEdge: Color(0xFF161412),
      tileFace: Color(0xFFF0EAD8),
      tileBevel: Color(0xFFB5AC94),
      tileShadow: Color(0xFF000000),
      letter: Color(0xFF2B2925),
      letterShadow: Color(0xFFFFFFFF),
      selected: Color(0xFFC9A227),
      found: Color(0xFF7BC96F),
      accent: Color(0xFFC9A227),
      text: Color(0xFFF5EFE0),
      muted: Color(0xFFA9A090),
      chip: Color(0xFF35322C),
      chipFound: Color(0xFF2E5A34),
    ),
    WordThemeDef(
      id: 'newsprint',
      name: 'Newsprint Press',
      isPro: true,
      bgTop: Color(0xFF4E4638),
      bgBottom: Color(0xFF2A251B),
      board: Color(0xFFD9CFB8),
      boardEdge: Color(0xFF6E6250),
      tileFace: Color(0xFFF7F2E2),
      tileBevel: Color(0xFFC2B79E),
      tileShadow: Color(0xFF000000),
      letter: Color(0xFF33302A),
      letterShadow: Color(0xFFFFFFFF),
      selected: Color(0xFFB8452F),
      found: Color(0xFF4E7F4A),
      accent: Color(0xFFB8452F),
      text: Color(0xFFF2EBD8),
      muted: Color(0xFFB5A98E),
      chip: Color(0xFF655C48),
      chipFound: Color(0xFF2F5230),
    ),
    WordThemeDef(
      id: 'chalk',
      name: 'Chalkboard',
      isPro: true,
      bgTop: Color(0xFF2E3A33),
      bgBottom: Color(0xFF161D19),
      board: Color(0xFF37473D),
      boardEdge: Color(0xFF1C2620),
      tileFace: Color(0xFF3F5347),
      tileBevel: Color(0xFF223028),
      tileShadow: Color(0xFF000000),
      letter: Color(0xFFF2EFE4),
      letterShadow: Color(0xFF000000),
      selected: Color(0xFFE8D48B),
      found: Color(0xFF8FD694),
      accent: Color(0xFFE8D48B),
      text: Color(0xFFF2EFE4),
      muted: Color(0xFF9BA89C),
      chip: Color(0xFF2A362E),
      chipFound: Color(0xFF2E5A34),
    ),
    WordThemeDef(
      id: 'parchment',
      name: 'Parchment Scroll',
      isPro: true,
      bgTop: Color(0xFF5E4A30),
      bgBottom: Color(0xFF362813),
      board: Color(0xFFE4CFA0),
      boardEdge: Color(0xFF8A6F42),
      tileFace: Color(0xFFF7ECD2),
      tileBevel: Color(0xFFCBAF7E),
      tileShadow: Color(0xFF000000),
      letter: Color(0xFF5A3E1C),
      letterShadow: Color(0xFFFFFFFF),
      selected: Color(0xFF9C6B1E),
      found: Color(0xFF5E8F4E),
      accent: Color(0xFF9C6B1E),
      text: Color(0xFFFFF2D8),
      muted: Color(0xFFCDB488),
      chip: Color(0xFF6B5636),
      chipFound: Color(0xFF33572F),
    ),
    WordThemeDef(
      id: 'moonlit',
      name: 'Moonlit Study',
      isPro: true,
      bgTop: Color(0xFF2B3350),
      bgBottom: Color(0xFF141826),
      board: Color(0xFF3B4460),
      boardEdge: Color(0xFF1D2335),
      tileFace: Color(0xFFD9DCE8),
      tileBevel: Color(0xFF9BA1B8),
      tileShadow: Color(0xFF000000),
      letter: Color(0xFF2B3350),
      letterShadow: Color(0xFFF2F4FA),
      selected: Color(0xFFE8C766),
      found: Color(0xFF8FD694),
      accent: Color(0xFFE8C766),
      text: Color(0xFFEEF0F8),
      muted: Color(0xFF9BA1B8),
      chip: Color(0xFF323A54),
      chipFound: Color(0xFF2E5A34),
    ),
    WordThemeDef(
      id: 'desert',
      name: 'Desert Clay',
      isPro: true,
      bgTop: Color(0xFF6E4A2E),
      bgBottom: Color(0xFF3A2415),
      board: Color(0xFF8A5C36),
      boardEdge: Color(0xFF4A2E18),
      tileFace: Color(0xFFE8B98A),
      tileBevel: Color(0xFFB57E4E),
      tileShadow: Color(0xFF000000),
      letter: Color(0xFF4A2410),
      letterShadow: Color(0xFFFFE4C4),
      selected: Color(0xFFD94F2B),
      found: Color(0xFF7BC96F),
      accent: Color(0xFFD94F2B),
      text: Color(0xFFFFECd8),
      muted: Color(0xFFD9A87E),
      chip: Color(0xFF704E30),
      chipFound: Color(0xFF33572F),
    ),
    WordThemeDef(
      id: 'meadow',
      name: 'Meadow Picnic',
      isPro: true,
      bgTop: Color(0xFF4A5E38),
      bgBottom: Color(0xFF27331C),
      board: Color(0xFF8A6B4A),
      boardEdge: Color(0xFF4A3A26),
      tileFace: Color(0xFFF2E3C0),
      tileBevel: Color(0xFFBFA06E),
      tileShadow: Color(0xFF000000),
      letter: Color(0xFF4A3A1E),
      letterShadow: Color(0xFFFFF8E6),
      selected: Color(0xFFC23B4E),
      found: Color(0xFF5E9F52),
      accent: Color(0xFFC23B4E),
      text: Color(0xFFF6F0DC),
      muted: Color(0xFFBCB184),
      chip: Color(0xFF55643C),
      chipFound: Color(0xFF2F5A32),
    ),
    WordThemeDef(
      id: 'ember',
      name: 'Ember Forge',
      isPro: true,
      bgTop: Color(0xFF4A2420),
      bgBottom: Color(0xFF241110),
      board: Color(0xFF5E3228),
      boardEdge: Color(0xFF331815),
      tileFace: Color(0xFFD9A06A),
      tileBevel: Color(0xFF9A6238),
      tileShadow: Color(0xFF000000),
      letter: Color(0xFF3E1E10),
      letterShadow: Color(0xFFFFE0B8),
      selected: Color(0xFFE8590C),
      found: Color(0xFF7BC96F),
      accent: Color(0xFFE8590C),
      text: Color(0xFFF7E6D2),
      muted: Color(0xFFC49A7A),
      chip: Color(0xFF543026),
      chipFound: Color(0xFF2E5A34),
    ),
  ];

  static WordThemeDef byId(String id, {required WordThemeDef custom}) {
    if (id == 'custom') return custom;
    for (final t in all) {
      if (t.id == id) return t;
    }
    return all.first;
  }

  static bool isProTheme(String id) =>
      id == 'custom' || all.any((t) => t.id == id && t.isPro);

  /// Color keys editable in the custom theme creator (Pro).
  static const Map<String, int> defaultCustomColors = {
    'bgTop': 0xFF4A2F1B,
    'bgBottom': 0xFF2A1A0E,
    'board': 0xFF6B4226,
    'boardEdge': 0xFF3A2210,
    'tileFace': 0xFFE8C77E,
    'tileBevel': 0xFFB98A3E,
    'letter': 0xFF4A2C10,
    'selected': 0xFFFFB627,
    'found': 0xFF7BC96F,
    'accent': 0xFFFFB627,
    'text': 0xFFFFF3DC,
    'muted': 0xFFC9A876,
    'chip': 0xFF5A3A1E,
    'chipFound': 0xFF2E5B33,
  };

  static const Map<String, String> customColorLabels = {
    'bgTop': 'Backdrop light',
    'bgBottom': 'Backdrop dark',
    'board': 'Board',
    'boardEdge': 'Board edge',
    'tileFace': 'Tile face',
    'tileBevel': 'Tile bevel',
    'letter': 'Letters',
    'selected': 'Selection glow',
    'found': 'Found tint',
    'accent': 'Accent',
    'text': 'Text',
    'muted': 'Muted text',
    'chip': 'Word chips',
    'chipFound': 'Found chips',
  };
}

/// Letter-tile shapes. First 4 free, rest Pro.
class TileStyles {
  static const List<String> names = [
    'Classic Square',
    'Soft Rounded',
    'Wooden Coin',
    'Honeycomb',
    'Diamond Cut',
    'River Pebble',
    'Carved Shield',
    'Notched Tile',
  ];

  static bool isPro(int i) => i >= 4;

  static const List<String> descriptions = [
    'Sharp-cornered carpenter tile',
    'Gently rounded family tile',
    'Round turned-wood coin',
    'Six-sided honeycomb cell',
    'Faceted gem-cut tile',
    'Smooth river-worn oval',
    'Carved heraldic shield',
    'Scrabble-style notched tile',
  ];
}

/// Difficulty tiers: word length + grid size. Genius is Pro.
class WlDifficulty {
  static const List<String> names = ['Rookie', 'Wordsmith', 'Genius'];
  static const List<String> descriptions = [
    '3×3 board · short words',
    '4×4 board · medium words',
    '5×5 board · long words',
  ];
  static const List<int> gridSizes = [3, 4, 5];
  static const List<int> maxWordLens = [4, 5, 6];
  static const List<int> minWordLens = [3, 3, 4];

  static bool isPro(int i) => i >= 2;

  static int wordCountFor(int size) => size == 3 ? 3 : (size == 4 ? 4 : 6);
}
