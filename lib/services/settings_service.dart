import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/word_themes.dart';

/// Persisted settings + stats for Word Link. Survives app restarts.
///
/// Stores: audio toggles, player name, theme/appearance choices (incl. custom
/// theme colors), difficulty + mode setup, journey progress, Pro unlock
/// state, and lifetime stats.
class WordLinkSettings extends ChangeNotifier {
  static const _kMusic = 'wordlink_music_on';
  static const _kSfx = 'wordlink_sfx_on';
  static const _kVolume = 'wordlink_volume';
  static const _kDifficulty = 'wordlink_difficulty'; // 0 rookie, 1 wordsmith, 2 genius
  static const _kMode = 'wordlink_mode'; // 0 journey, 1 blitz, 2 relaxed
  static const _kNameLegacy = 'wordlink_player_name'; // legacy plain-string key
  /// Order-safe player-name storage: a single JSON string. Android's
  /// SharedPreferences stores StringLists as an unordered StringSet, so
  /// ordered data must NEVER live in a StringList on Android.
  static const _kNamesJson = 'wordlink_player_names_json';
  static const _kTheme = 'wordlink_theme_id';
  static const _kTileStyle = 'wordlink_tile_style';
  static const _kJourneyLevel = 'wordlink_journey_level';
  static const _kGames = 'wordlink_games_played';
  static const _kWords = 'wordlink_words_found';
  static const _kBestBlitz = 'wordlink_best_blitz';
  static const _kIsPro = 'wordlink_is_pro';
  static const _kCustomPrefix = 'wordlink_custom_';

  static const defaultNames = ['Word Wizard'];

  /// Encode player names as one JSON string (order-preserving).
  static String encodePlayerNames(List<String> names) => jsonEncode(names);

  static String _cleanName(int i, Object? v) {
    final s = v is String ? v.trim() : '';
    return s.isEmpty ? defaultNames[i] : s;
  }

  /// Decode persisted names; falls back to defaults on missing/corrupt data.
  static List<String> decodePlayerNames(String? raw) {
    if (raw == null) return List.of(defaultNames);
    try {
      final d = jsonDecode(raw);
      if (d is List && d.isNotEmpty) {
        return [for (int i = 0; i < d.length && i < 4; i++) _cleanName(i, d[i])];
      }
    } catch (_) {}
    return List.of(defaultNames);
  }

  bool musicOn = true;
  bool sfxOn = true;
  double volume = 0.8;
  int difficulty = 1; // wordsmith default
  int mode = 0; // journey default
  List<String> playerNames = List.of(defaultNames);
  String themeId = 'oak';
  int tileStyle = 0;
  int journeyLevel = 1;
  int gamesPlayed = 0;
  int wordsFound = 0;
  int bestBlitz = 0;
  bool isPro = false;

  /// Custom theme colors (ARGB ints). Defaults mirror Classic Oak.
  Map<String, int> customColors = Map.of(WordThemes.defaultCustomColors);

  /// Builds the user-designed custom theme from stored colors.
  WordThemeDef get customTheme {
    Color c(String k) => Color(customColors[k] ?? 0xFF000000);
    return WordThemeDef(
      id: 'custom',
      name: 'My Creation',
      bgTop: c('bgTop'),
      bgBottom: c('bgBottom'),
      board: c('board'),
      boardEdge: c('boardEdge'),
      tileFace: c('tileFace'),
      tileBevel: c('tileBevel'),
      tileShadow: const Color(0xFF000000),
      letter: c('letter'),
      letterShadow: const Color(0xFFFFFFFF),
      selected: c('selected'),
      found: c('found'),
      accent: c('accent'),
      text: c('text'),
      muted: c('muted'),
      chip: c('chip'),
      chipFound: c('chipFound'),
    );
  }

  SharedPreferences? _prefs;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    musicOn = p.getBool(_kMusic) ?? true;
    sfxOn = p.getBool(_kSfx) ?? true;
    volume = p.getDouble(_kVolume) ?? 0.8;
    difficulty = (p.getInt(_kDifficulty) ?? 1).clamp(0, 2);
    mode = (p.getInt(_kMode) ?? 0).clamp(0, 2);
    // Player name: prefer the order-safe JSON key; migrate the legacy
    // plain-string key once (it stored a single name).
    final namesRaw = p.getString(_kNamesJson);
    if (namesRaw != null) {
      playerNames = decodePlayerNames(namesRaw);
    } else {
      final legacy = p.getString(_kNameLegacy);
      playerNames = legacy == null || legacy.trim().isEmpty
          ? List.of(defaultNames)
          : [legacy.trim()];
    }
    themeId = p.getString(_kTheme) ?? 'oak';
    tileStyle = (p.getInt(_kTileStyle) ?? 0).clamp(0, TileStyles.names.length - 1);
    journeyLevel = (p.getInt(_kJourneyLevel) ?? 1).clamp(1, 60);
    gamesPlayed = p.getInt(_kGames) ?? 0;
    wordsFound = p.getInt(_kWords) ?? 0;
    bestBlitz = p.getInt(_kBestBlitz) ?? 0;
    isPro = p.getBool(_kIsPro) ?? false;
    for (final k in WordThemes.defaultCustomColors.keys) {
      customColors[k] =
          p.getInt('$_kCustomPrefix$k') ?? WordThemes.defaultCustomColors[k]!;
    }
    _enforceFreeLimits(silent: true);
    notifyListeners();
  }

  Future<void> _save() async {
    final p = _prefs;
    if (p == null) return;
    await p.setBool(_kMusic, musicOn);
    await p.setBool(_kSfx, sfxOn);
    await p.setDouble(_kVolume, volume);
    await p.setInt(_kDifficulty, difficulty);
    await p.setInt(_kMode, mode);
    await p.setString(_kNamesJson, encodePlayerNames(playerNames));
    await p.remove(_kNameLegacy); // drop the legacy key for good
    await p.setString(_kTheme, themeId);
    await p.setInt(_kTileStyle, tileStyle);
    await p.setInt(_kJourneyLevel, journeyLevel);
    await p.setInt(_kGames, gamesPlayed);
    await p.setInt(_kWords, wordsFound);
    await p.setInt(_kBestBlitz, bestBlitz);
    await p.setBool(_kIsPro, isPro);
    for (final e in customColors.entries) {
      await p.setInt('$_kCustomPrefix${e.key}', e.value);
    }
  }

  /// Free-tier limits: clamp pro-only choices back when not Pro.
  /// Called after load and whenever Pro status could have changed.
  void _enforceFreeLimits({bool silent = false}) {
    if (isPro) return;
    var changed = false;
    if (themeId == 'custom' || WordThemes.isProTheme(themeId)) {
      themeId = 'oak';
      changed = true;
    }
    if (TileStyles.isPro(tileStyle)) {
      tileStyle = 0;
      changed = true;
    }
    if (difficulty > 1) {
      difficulty = 1;
      changed = true;
    }
    if (changed && !silent) {
      notifyListeners();
      _save();
    }
  }

  Future<void> setPro(bool v) async {
    isPro = v;
    if (!v) _enforceFreeLimits();
    notifyListeners();
    await _save();
  }

  Future<void> setCustomColor(String key, int argb) async {
    if (!isPro) return; // custom theme creator is a Pro feature
    if (!WordThemes.defaultCustomColors.containsKey(key)) return;
    customColors[key] = argb;
    notifyListeners();
    await _save();
  }

  Future<void> resetCustomColors() async {
    customColors = Map.of(WordThemes.defaultCustomColors);
    notifyListeners();
    await _save();
  }

  Future<void> setMusic(bool v) async {
    musicOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setSfx(bool v) async {
    sfxOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setVolume(double v) async {
    volume = v.clamp(0.0, 1.0);
    notifyListeners();
    await _save();
  }

  Future<void> setDifficulty(int v) async {
    v = v.clamp(0, 2);
    // Genius is a Pro feature.
    if (!isPro && WlDifficulty.isPro(v)) return;
    difficulty = v;
    notifyListeners();
    await _save();
  }

  Future<void> setMode(int v) async {
    mode = v.clamp(0, 2);
    notifyListeners();
    await _save();
  }

  Future<void> setPlayerName(String name) async {
    final clean = name.trim();
    playerNames = [clean.isEmpty ? defaultNames.first : clean];
    notifyListeners();
    await _save();
  }

  Future<void> setTheme(String id) async {
    // Pro-only themes (incl. the custom theme creator) require Pro;
    // silently ignore otherwise (UI shows lock).
    if (!isPro && (id == 'custom' || WordThemes.isProTheme(id))) return;
    themeId = id;
    notifyListeners();
    await _save();
  }

  Future<void> setTileStyle(int v) async {
    v = v.clamp(0, TileStyles.names.length - 1);
    if (!isPro && TileStyles.isPro(v)) return;
    tileStyle = v;
    notifyListeners();
    await _save();
  }

  Future<void> setJourneyLevel(int v) async {
    journeyLevel = v.clamp(1, 60);
    notifyListeners();
    await _save();
  }

  /// Record a finished session.
  Future<void> recordGame(
      {required int words, required int blitzScore}) async {
    gamesPlayed++;
    wordsFound += words;
    if (blitzScore > bestBlitz) bestBlitz = blitzScore;
    notifyListeners();
    await _save();
  }
}
