import 'dart:convert';
import 'dart:io';

void main() {
  const LocalizationsGenerator().generate();
}

class LocalizationsGenerator {
  static const _jsonEncoder = JsonEncoder.withIndent('  ');

  final String path = 'lib/core/l10n';

  const LocalizationsGenerator();

  void generate() {
    final translationGroups = _deserializeTranslationGroups();
    _generateSchema(translationGroups);
    _generateArbFiles(translationGroups);
    Process.runSync('fvm', ['flutter', 'pub', 'get']);
  }

  List<TranslationGroup> _deserializeTranslationGroups() {
    final file = File('$path/localizations.json');
    final Map<String, dynamic> rawJsonMap = const JsonDecoder().convert(file.readAsStringSync());
    final Map<String, dynamic> localizationsMap = rawJsonMap['localizations'];
    final translationGroups = <TranslationGroup>[];
    for (final translationGroupMap in localizationsMap.entries) {
      translationGroups.add(TranslationGroup.fromMapEntry(translationGroupMap));
    }
    return translationGroups;
  }

  void _generateArbFiles(List<TranslationGroup> translationGroups) {
    for (final language in Translation.supportedLanguages) {
      final allTranslations = <String, String?>{};
      for (final translationGroup in translationGroups) {
        allTranslations.addAll(translationGroup.translateTo(language));
      }
      final arbFileContents = _jsonEncoder.convert(allTranslations);
      File('$path/app_$language.arb')
        ..createSync()
        ..writeAsStringSync(arbFileContents);
    }
  }

  void _generateSchema(List<TranslationGroup> translationGroups) {
    final keys = _generateKeys(translationGroups);
    final schema = <String, dynamic>{
      r'$schema': 'http://json-schema.org/draft-07/schema#',
      'description': 'Generated schema — do not edit manually.',
      'type': 'object',
      'additionalProperties': false,
      'properties': {for (final key in keys) key: <String, dynamic>{'type': 'string'}},
      'required': keys.toList(),
    };
    File('$path/arb_schema.json')
      ..createSync()
      ..writeAsStringSync(_jsonEncoder.convert(schema));
  }

  Set<String> _generateKeys(List<TranslationGroup> translationGroups) {
    final keys = <String>{};
    for (final group in translationGroups) {
      keys.addAll(group.getKeys());
    }
    return keys;
  }
}

class TranslationGroup {
  final String prefix;
  final List<Translation> translations;

  const TranslationGroup(this.prefix, this.translations);

  Set<String> getKeys() => translations.map((t) => t.getPrefixedKey(prefix)).toSet();

  Map<String, String?> translateTo(String language) {
    return Map.fromEntries(
      translations.map((t) => MapEntry(t.getPrefixedKey(prefix), t.ofLanguage(language))),
    );
  }

  factory TranslationGroup.fromMapEntry(MapEntry<String, dynamic> entry) {
    if (entry.value case final String untranslatedString) {
      return TranslationGroup('', [Translation.untranslatable(entry.key, untranslatedString)]);
    }
    if (Translation.isTranslationMap(entry.value)) {
      return TranslationGroup('', [Translation.fromMapEntry(entry)]);
    }
    if (TranslationGroup.isTranslationGroupMap(entry.value)) {
      final groupPrefix = entry.key;
      final groupMap = Map<String, dynamic>.from(entry.value as Map);
      return TranslationGroup(groupPrefix, groupMap.entries.map(Translation.fromMapEntry).toList());
    }
    throw Exception('Unformatted localizations.json entry $entry');
  }

  static bool isTranslationGroupMap(dynamic value) {
    if (value case final Map translationGroupMap) {
      final areKeysStrings = translationGroupMap.keys.every((key) => key is String);
      final areValuesOk = translationGroupMap.values.every(
        (v) => Translation.isTranslationMap(v) || v is String,
      );
      return areKeysStrings && areValuesOk;
    }
    return false;
  }
}

class Translation {
  static const supportedLanguages = {'pt', 'en', 'es'};

  final String key;
  final Map<String, String> translationMap;

  const Translation(this.key, this.translationMap);

  Translation.untranslatable(this.key, String value)
    : translationMap = {for (final lang in supportedLanguages) lang: value};

  String getPrefixedKey(String prefix) {
    if (prefix.isEmpty) return key;
    final capitalized = '${key[0].toUpperCase()}${key.substring(1)}';
    return '$prefix$capitalized';
  }

  String? ofLanguage(String language) => translationMap[language];

  factory Translation.fromMapEntry(MapEntry<String, dynamic> entry) {
    if (isTranslationMap(entry.value)) {
      return Translation(entry.key, Map<String, String>.from(entry.value as Map));
    }
    if (entry.value is String) {
      return Translation.untranslatable(entry.key, entry.value as String);
    }
    throw Exception('Unformatted translation map: ${entry.value}');
  }

  static bool isTranslationMap(dynamic value) {
    if (value case final Map map) {
      var hasAllLanguages = true;
      for (final language in supportedLanguages) {
        if (!map.keys.contains(language)) {
          hasAllLanguages = false;
          break;
        }
      }
      return hasAllLanguages && map.keys.length == supportedLanguages.length && map.values.every((v) => v is String);
    }
    return false;
  }
}
