import 'dart:convert';
import 'dart:io';

/// Simple JSON -> Dart code generator for assets/map.json
/// Usage:
///   dart run tool/generate_map_to_dart.dart [input.json] [output.dart]
void main(List<String> args) {
  final input = args.isNotEmpty ? args[0] : 'assets/map.json';
  final outDir = args.length > 1 ? args[1] : 'lib/src/generated';

  final inputEntity = FileSystemEntity.typeSync(input);
  if (inputEntity == FileSystemEntityType.directory) {
    _processIdsDirectory(Directory(input), Directory(outDir));
  } else if (inputEntity == FileSystemEntityType.file) {
    // Only process the specified file
    _processSingleFile(File(input), Directory(outDir));
  } else {
    stderr.writeln('Input path not found: $input');
    exit(2);
  }
}

String _titleCaseFromKey(String key) {
  final parts = key.split(RegExp(r'[_\-]+'));
  final words = parts.map((p) {
    if (p.isEmpty) return p;
    return p[0].toUpperCase() + (p.length > 1 ? p.substring(1) : '');
  }).toList();
  return words.join(' ');
}

String toCamelCase(String str) {
  if (str.isEmpty) return str;

  final parts = str.split(RegExp(r'[_\-]+'));
  
  final camelParts = parts.map((part) {
    if (part.isEmpty) return '';
    return part.toLowerCase();
  }).toList();

  if (camelParts.isEmpty) return '';

  final first = camelParts.first;
  final others = camelParts.skip(1).map((p) {
    if (p.isEmpty) return '';
    return p[0].toUpperCase() + p.substring(1);
  }).join('');

  return first + others;
}

String toPascalCase(String str) {
  if (str.isEmpty) return str;

  final parts = str.split(RegExp(r'[_\-]+'));
  
  return parts.map((part) {
    if (part.isEmpty) return '';
    return part[0].toUpperCase() + part.substring(1).toLowerCase();
  }).join('');
}

void _processIdsDirectory(Directory inputDir, Directory outDir) {
  if (!inputDir.existsSync()) {
    stderr.writeln('Input directory not found: ${inputDir.path}');
    exit(2);
  }

  final files = inputDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('_ids.json'))
      .toList();

  // If zh_cn exists and en_us missing, generate en_us automatically from keys
  final zh = files.firstWhere((f) => f.uri.pathSegments.last == 'zh_cn_ids.json', orElse: () => File(''));
  final en = files.firstWhere((f) => f.uri.pathSegments.last == 'en_us_ids.json', orElse: () => File(''));
  if (zh.path.isNotEmpty && en.path.isEmpty) {
    try {
      final decoded = json.decode(zh.readAsStringSync()) as Map<String, dynamic>;
      final Map<String, String> enMap = {};
      for (final k in decoded.keys) {
        enMap[k] = _titleCaseFromKey(k);
      }
      final enFile = File('${inputDir.path.replaceAll(RegExp(r'\\\\|/+\$'), '')}/en_us_ids.json');
      enFile.createSync(recursive: true);
      enFile.writeAsStringSync(JsonEncoder.withIndent('  ').convert(enMap));
      stdout.writeln('Generated ${enFile.path} from ${zh.path}');
      files.add(enFile);
    } catch (e) {
      stderr.writeln('Failed to generate en_us_ids.json: $e');
    }
  }

  final generatedLocales = <String, String>{};
  for (final f in files) {
    final name = f.uri.pathSegments.last; // zh_cn_ids.json
    final locale = name.replaceFirst('_ids.json', '');
    final outFile = File('${outDir.path}/ids_${locale}.g.dart');
    final decoded = json.decode(f.readAsStringSync());
    if (decoded is! Map<String, dynamic>) {
      stderr.writeln('Skipping ${f.path}: not an object');
      continue;
    }
    final entries = decoded as Map<String, dynamic>;
    _writeLocaleFile(outFile, locale, entries);
    generatedLocales[locale] = outFile.path;
    stdout.writeln('Generated ${outFile.path} (${entries.length} entries)');
  }

  _writeAggregateFile(outDir, generatedLocales);
}

String _sanitizeLocale(String raw) {
  return raw.replaceAll(RegExp(r'[^A-Za-z0-9]'), '_').toLowerCase();
}

void _processDirectory(Directory inputDir, Directory outDir) {
  final generatedLocales = <String, String>{};
  if (!inputDir.existsSync()) {
    stderr.writeln('Input directory not found: ${inputDir.path}');
    exit(2);
  }

  // Deprecated: directory processing not used when generating only map.json
  stderr.writeln('Directory processing is deprecated; call with specific map.json file instead');
}

void _processSingleFile(File inputFile, Directory outDir) {
  if (!inputFile.existsSync()) {
    stderr.writeln('Input file not found: ${inputFile.path}');
    exit(2);
  }
  final entries = json.decode(inputFile.readAsStringSync()) as Map<String, dynamic>;
  final locale = _sanitizeLocale(inputFile.uri.pathSegments.last.replaceAll('.json', ''));
  final outFile = File('${outDir.path}/${locale}.g.dart');
  _writeLocaleFile(outFile, locale, entries);
  // _writeAggregateFile(outDir, {locale: outFile.path});
  stdout.writeln('Generated ${outFile.path} (${entries.length} entries)');
}

void _writeLocaleFile(File outFile, String locale, Map<String, dynamic> data) {
  final buffer = StringBuffer();
  buffer.writeln('// GENERATED CODE - DO NOT EDIT');
  buffer.writeln('// Locale: $locale');
  buffer.writeln('const Map<String, String> ids_${locale} = {');
  for (final entry in data.entries) {
    final k = json.encode(entry.key);
    //final v = json.encode(entry.value?.toString() ?? '');
    final k2 = toCamelCase(k.replaceAll('"', ''));

    buffer.writeln('  $k2($k),');
  }
  buffer.writeln('};');

  outFile.createSync(recursive: true);
  outFile.writeAsStringSync(buffer.toString());
}

void _writeAggregateFile(Directory outDir, Map<String, String> generatedLocales) {
  final aggFile = File('${outDir.path}/ids_all.g.dart');
  final buffer = StringBuffer();
  buffer.writeln('// GENERATED AGGREGATE - DO NOT EDIT');
  // include individual files
  for (final entry in generatedLocales.entries) {
    final locale = entry.key;
    final filename = Uri.file(entry.value).pathSegments.last;
    buffer.writeln("import '$filename';");
  }
  buffer.writeln();
  buffer.writeln('const Map<String, Map<String, String>> IDS_ALL = {');
  for (final locale in generatedLocales.keys) {
    buffer.writeln("  '$locale': ids_${locale},");
  }
  buffer.writeln('};');

  aggFile.createSync(recursive: true);
  aggFile.writeAsStringSync(buffer.toString());
  stdout.writeln('Generated aggregate ${aggFile.path} (${generatedLocales.length} locales)');
}