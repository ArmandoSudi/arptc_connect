import 'dart:convert';
import 'dart:io';

final _identifierPattern = RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$');
final _placeholderPattern = RegExp(r'\{([A-Za-z_][A-Za-z0-9_]*)\}');

void main(List<String> arguments) {
  final outputPath =
      arguments.isEmpty ? 'lib/generated/l10n.dart' : arguments.single;
  final translations = <String, Map<String, String>>{};

  for (final locale in const ['en', 'fr']) {
    final source = File('lib/l10n/intl_$locale.arb');
    final decoded = jsonDecode(source.readAsStringSync());
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('${source.path} must contain a JSON object.');
    }

    translations[locale] = <String, String>{
      for (final entry in decoded.entries)
        if (!entry.key.startsWith('@'))
          entry.key: _readTranslation(source.path, entry.key, entry.value),
    };
  }

  final englishKeys = translations['en']!.keys.toSet();
  final frenchKeys = translations['fr']!.keys.toSet();
  final missingFrench = englishKeys.difference(frenchKeys).toList()..sort();
  final missingEnglish = frenchKeys.difference(englishKeys).toList()..sort();
  if (missingFrench.isNotEmpty || missingEnglish.isNotEmpty) {
    throw StateError(
      'Localization keys must match. '
      'Missing in French: $missingFrench. Missing in English: $missingEnglish.',
    );
  }

  final buffer = StringBuffer()
    ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND')
    ..writeln("import 'package:flutter/material.dart';")
    ..writeln()
    ..writeln('class S {')
    ..writeln('  S._(this.localeName, this._messages);')
    ..writeln()
    ..writeln('  final String localeName;')
    ..writeln('  final Map<String, String> _messages;')
    ..writeln('  static S? _current;')
    ..writeln()
    ..writeln('  static S get current {')
    ..writeln('    assert(')
    ..writeln('      _current != null,')
    ..writeln(
        "      'No instance of S was loaded. Try to initialize S.delegate.',")
    ..writeln('    );')
    ..writeln('    return _current!;')
    ..writeln('  }')
    ..writeln()
    ..writeln(
      '  static const AppLocalizationDelegate delegate = '
      'AppLocalizationDelegate();',
    )
    ..writeln()
    ..writeln('  static Future<S> load(Locale locale) async {')
    ..writeln(
      '    final localeName = '
      '_supportedLanguageCodes.contains(locale.languageCode)',
    )
    ..writeln("        ? locale.languageCode : 'en';")
    ..writeln('    final instance = S._(')
    ..writeln('      localeName,')
    ..writeln(
      "      _localizedValues[localeName] ?? _localizedValues['en']!,",
    )
    ..writeln('    );')
    ..writeln('    _current = instance;')
    ..writeln('    return instance;')
    ..writeln('  }')
    ..writeln()
    ..writeln('  static S of(BuildContext context) {')
    ..writeln('    final instance = maybeOf(context);')
    ..writeln('    assert(')
    ..writeln('      instance != null,')
    ..writeln(
      "      'No S instance is present. Add S.delegate to "
      "localizationsDelegates.',",
    )
    ..writeln('    );')
    ..writeln('    return instance!;')
    ..writeln('  }')
    ..writeln()
    ..writeln(
      '  static S? maybeOf(BuildContext context) => '
      'Localizations.of<S>(context, S);',
    )
    ..writeln()
    ..writeln("  String _text(String key) =>")
    ..writeln("      _messages[key] ?? _localizedValues['en']?[key] ?? key;")
    ..writeln()
    ..writeln(
      '  String _format(String key, Map<String, Object?> values) {',
    )
    ..writeln('    var result = _text(key);')
    ..writeln('    for (final entry in values.entries) {')
    ..writeln('      result = result.replaceAll(')
    ..writeln("        '{\${entry.key}}',")
    ..writeln("        entry.value?.toString() ?? '',")
    ..writeln('      );')
    ..writeln('    }')
    ..writeln('    return result;')
    ..writeln('  }')
    ..writeln();

  for (final entry in translations['en']!.entries) {
    final key = entry.key;
    if (!_identifierPattern.hasMatch(key)) {
      throw FormatException(
        'Localization key "$key" is not a valid Dart identifier.',
      );
    }

    final placeholders = _placeholderPattern
        .allMatches(entry.value)
        .map((match) => match.group(1)!)
        .toSet()
        .toList();
    if (placeholders.isEmpty) {
      buffer.writeln("  String get $key => _text('$key');");
      continue;
    }

    buffer
      ..writeln(
        '  String $key(${placeholders.map((name) => 'Object? $name').join(', ')}) =>',
      )
      ..writeln("      _format('$key', {")
      ..writeln(
        placeholders.map((name) => "        '$name': $name,").join('\n'),
      )
      ..writeln('      });');
  }

  buffer
    ..writeln('}')
    ..writeln()
    ..writeln(
      'class AppLocalizationDelegate extends LocalizationsDelegate<S> {',
    )
    ..writeln('  const AppLocalizationDelegate();')
    ..writeln()
    ..writeln('  List<Locale> get supportedLocales => const <Locale>[')
    ..writeln("        Locale.fromSubtags(languageCode: 'en'),")
    ..writeln("        Locale.fromSubtags(languageCode: 'fr'),")
    ..writeln('      ];')
    ..writeln()
    ..writeln('  @override')
    ..writeln('  bool isSupported(Locale locale) =>')
    ..writeln(
      '      _supportedLanguageCodes.contains(locale.languageCode);',
    )
    ..writeln()
    ..writeln('  @override')
    ..writeln('  Future<S> load(Locale locale) => S.load(locale);')
    ..writeln()
    ..writeln('  @override')
    ..writeln('  bool shouldReload(AppLocalizationDelegate old) => false;')
    ..writeln('}')
    ..writeln()
    ..writeln(
      "const _supportedLanguageCodes = <String>{'en', 'fr'};",
    )
    ..writeln()
    ..writeln(
      'const _localizedValues = <String, Map<String, String>>{',
    );

  for (final locale in const ['en', 'fr']) {
    buffer.writeln("  '$locale': <String, String>{");
    for (final entry in translations[locale]!.entries) {
      buffer.writeln(
        "    '${entry.key}': ${_dartString(entry.value)},",
      );
    }
    buffer.writeln('  },');
  }
  buffer.writeln('};');

  final output = File(outputPath);
  output.parent.createSync(recursive: true);
  output.writeAsStringSync(buffer.toString());
}

String _readTranslation(String path, String key, Object? value) {
  if (value is! String) {
    throw FormatException('$path: "$key" must have a string value.');
  }
  return value;
}

String _dartString(String value) => jsonEncode(value).replaceAll(r'$', r'\$');
