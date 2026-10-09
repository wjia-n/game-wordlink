import 'package:flutter_test/flutter_test.dart';
import 'package:wordlink/services/settings_service.dart';

/// Player names persist as ONE JSON string — never setStringList, whose
/// Android StringSet backend scrambles order.
void main() {
  test('encode/decode round-trips a single name in order', () {
    const names = ['Word Wizard'];
    final raw = WordLinkSettings.encodePlayerNames(names);
    expect(WordLinkSettings.decodePlayerNames(raw), names);
  });

  test('decode falls back to defaults on corrupt data', () {
    expect(WordLinkSettings.decodePlayerNames('not-json'),
        WordLinkSettings.defaultNames);
    expect(WordLinkSettings.decodePlayerNames(null),
        WordLinkSettings.defaultNames);
    expect(WordLinkSettings.decodePlayerNames('[]'),
        WordLinkSettings.defaultNames);
  });

  test('blank entries are replaced with defaults', () {
    final raw = WordLinkSettings.encodePlayerNames(['   ']);
    expect(WordLinkSettings.decodePlayerNames(raw),
        WordLinkSettings.defaultNames);
  });
}
