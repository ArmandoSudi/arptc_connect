import 'dart:collection';

import 'support_serialization.dart';

class LocalizedValue {
  LocalizedValue({
    required this.en,
    required this.fr,
    Map<String, String> additional = const {},
  }) : additional = UnmodifiableMapView(
          Map<String, String>.from(additional)
            ..removeWhere(
              (locale, value) =>
                  locale.trim().isEmpty ||
                  value.trim().isEmpty ||
                  locale == 'en' ||
                  locale == 'fr',
            ),
        ) {
    supportRequire(en, 'en');
    supportRequire(fr, 'fr');
  }

  factory LocalizedValue.fromMap(Map<String, Object?> map) {
    final en = supportString(map['en'], supportString(map['default']));
    final fr = supportString(map['fr'], en);
    final additional = <String, String>{};
    for (final entry in map.entries) {
      if (entry.key != 'en' &&
          entry.key != 'fr' &&
          entry.key != 'default' &&
          supportString(entry.value).isNotEmpty) {
        additional[entry.key] = supportString(entry.value);
      }
    }
    return LocalizedValue(en: en, fr: fr, additional: additional);
  }

  factory LocalizedValue.fromValue(Object? value) {
    final map = supportMapFromValue(value);
    if (map.isNotEmpty) return LocalizedValue.fromMap(map);
    final text = supportString(value);
    return LocalizedValue(en: text, fr: text);
  }

  final String en;
  final String fr;
  final Map<String, String> additional;

  String resolve(String languageCode) {
    final normalized = languageCode.trim().toLowerCase();
    if (normalized == 'fr') return fr;
    if (normalized == 'en') return en;
    return additional[normalized] ?? en;
  }

  Map<String, Object?> toFirestore() => {
        'en': en.trim(),
        'fr': fr.trim(),
        ...additional,
      };
}
