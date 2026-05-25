import 'package:flutter/cupertino.dart';

import 'src/generated/ids_all.g.dart';

/// Runtime wrapper for generated ID maps.
/// Usage:
///   LocalizedIDs.labelFor('end_crystal', 'zh_cn');
class LocalizedIDs {
  /// Returns a localized label for [id] in [locale].
  /// Fallback order: requested locale -> fallbackLocale -> first available locale -> return id.
  static String labelFor(String id, String locale, {String? fallbackLocale}) {
    final preferred = locale.toLowerCase();
    final fb = fallbackLocale?.toLowerCase();

    String? result;
    result = IDS_ALL[preferred]?[id];
    if (result != null && result.isNotEmpty) return result;

    if (fb != null) {
      result = IDS_ALL[fb]?[id];
      if (result != null && result.isNotEmpty) return result;
    }

    if (IDS_ALL.isNotEmpty) {
      final first = IDS_ALL.values.first;
      result = first[id];
      if (result != null && result.isNotEmpty) return result;
    }

    return id;
  }

  /// Reverse lookup: find id by label in given locale (with same fallback order).
  /// Returns null if not found.
  static String? idForLabel(String label, String locale, {String? fallbackLocale}) {
    final preferred = locale.toLowerCase();
    final fb = fallbackLocale?.toLowerCase();

    String? id = _findIdInLocale(label, preferred);
    if (id != null) return id;

    if (fb != null) {
      id = _findIdInLocale(label, fb);
      if (id != null) return id;
    }

    // search in any locale
    for (final map in IDS_ALL.values) {
      id = _findIdInMap(label, map);
      if (id != null) return id;
    }
    return null;
  }

  static String? _findIdInLocale(String label, String locale) {
    final map = IDS_ALL[locale];
    if (map == null) return null;
    return _findIdInMap(label, map);
  }

  static String? _findIdInMap(String label, Map<String, String> map) {
    for (final entry in map.entries) {
      if (entry.value == label) return entry.key;
    }
    return null;
  }

  /// List of available locale keys.
  static List<String> get availableLocales => IDS_ALL.keys.toList();
}

class LocaleProvider with ChangeNotifier {
  LocaleProvider(this.locale);

  Locale locale;

  void setLocale(Locale newLocale) {
    locale = newLocale;
    notifyListeners();
  }

  String getLocaleName() {
    return locale.languageCode;
  }

  String getLocaleNameWithCountry() {
    return "${locale.languageCode}_${locale.countryCode}";
  }
}