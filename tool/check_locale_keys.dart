import 'dart:io';

/// Check that all generated ids_*.g.dart in the given directory share the same key set.
/// Usage:
///   dart run tool/check_locale_keys.dart lib/src/generated
void main(List<String> args) {
  final dirPath = args.isNotEmpty ? args[0] : 'lib/src/generated';
  final dir = Directory(dirPath);
  if (!dir.existsSync()) {
    stderr.writeln('Directory not found: $dirPath');
    exit(2);
  }

  final files = dir
      .listSync()
      .whereType<File>()
      .where((f) => f.uri.pathSegments.last.startsWith('ids_') && f.uri.pathSegments.last != 'ids_all.g.dart')
      .toList();

  if (files.isEmpty) {
    stdout.writeln('No generated locale files found in $dirPath');
    exit(0);
  }

  final Map<String, Set<String>> localeKeys = {};

  for (final f in files) {
    final name = f.uri.pathSegments.last; // ids_map.g.dart
    final locale = name.replaceFirst('ids_', '').replaceFirst('.g.dart', '');
    final content = f.readAsStringSync();
    final keys = <String>{};

    final reg = RegExp(r'"([^\"]+)"\s*:');
    for (final m in reg.allMatches(content)) {
      final k = m.group(1)!;
      // skip if looks like map variable assignment (e.g., 'Locale: map' comments)
      if (k == 'Locale' || k == 'Generated' || k == 'DO NOT EDIT') continue;
      keys.add(k);
    }

    localeKeys[locale] = keys;
    stdout.writeln('Found ${keys.length} keys for locale $locale');
  }

  // choose baseline: prefer 'map', else the one with max keys
  String baseline = localeKeys.keys.first;
  if (localeKeys.containsKey('map')) baseline = 'map';
  else {
    int max = -1;
    for (final e in localeKeys.entries) {
      if (e.value.length > max) {
        max = e.value.length;
        baseline = e.key;
      }
    }
  }

  final baseKeys = localeKeys[baseline]!;
  stdout.writeln('\nUsing baseline locale: $baseline (${baseKeys.length} keys)');

  var hasError = false;
  for (final entry in localeKeys.entries) {
    final locale = entry.key;
    if (locale == baseline) continue;
    final keys = entry.value;
    final missing = baseKeys.difference(keys);
    final extra = keys.difference(baseKeys);
    if (missing.isNotEmpty || extra.isNotEmpty) {
      hasError = true;
      stdout.writeln('\nLocale $locale differs:');
      if (missing.isNotEmpty) {
        stdout.writeln('  Missing ${missing.length} keys: ${missing.take(10).toList()}${missing.length>10? ' ...':''}');
      }
      if (extra.isNotEmpty) {
        stdout.writeln('  Extra ${extra.length} keys: ${extra.take(10).toList()}${extra.length>10? ' ...':''}');
      }
    }
  }

  if (hasError) {
    stderr.writeln('\nLocale key consistency check FAILED');
    exit(1);
  }

  stdout.writeln('\nLocale key consistency check OK');
}
