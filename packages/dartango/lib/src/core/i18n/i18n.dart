import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Internationalization and localization support for Dartango
/// Based on Django's i18n framework

// Global translation function
String _(String messageId, {Map<String, dynamic>? args, String? domain}) {
  return I18n.instance.translate(messageId, args: args, domain: domain);
}

// Lazy translation for strings that should be translated at runtime
LazyTranslation _lazy(String messageId,
    {Map<String, dynamic>? args, String? domain}) {
  return LazyTranslation(messageId, args: args, domain: domain);
}

// Ngettext - pluralization support
String ngettext(String singular, String plural, int count,
    {Map<String, dynamic>? args, String? domain}) {
  return I18n.instance
      .ngettext(singular, plural, count, args: args, domain: domain);
}

// Pgettext - context-aware translation
String pgettext(String context, String messageId,
    {Map<String, dynamic>? args, String? domain}) {
  return I18n.instance.pgettext(context, messageId, args: args, domain: domain);
}

// Npgettext - context-aware pluralization
String npgettext(String context, String singular, String plural, int count,
    {Map<String, dynamic>? args, String? domain}) {
  return I18n.instance
      .npgettext(context, singular, plural, count, args: args, domain: domain);
}

/// Main I18n class that handles translation and localization
class I18n {
  static final I18n _instance = I18n._internal();
  static I18n get instance => _instance;
  I18n._internal();

  String _currentLanguage = 'en';
  String _defaultLanguage = 'en';
  String _localeDirectory = 'locale';
  String _defaultDomain = 'messages';

  final Map<String, Map<String, TranslationCatalog>> _catalogs = {};
  final Map<String, LocaleInfo> _locales = {};

  bool _initialized = false;
  final List<String> _fallbackLanguages = ['en'];

  /// Current active language code
  String get currentLanguage => _currentLanguage;

  /// Default language code
  String get defaultLanguage => _defaultLanguage;

  /// Available languages
  List<String> get availableLanguages => _catalogs.keys.toList();

  /// Current locale info
  LocaleInfo? get currentLocale => _locales[_currentLanguage];

  /// Initialize the i18n system
  Future<void> initialize({
    String? defaultLanguage,
    String? localeDirectory,
    List<String>? fallbackLanguages,
  }) async {
    _defaultLanguage = defaultLanguage ?? 'en';
    _currentLanguage = _defaultLanguage;
    _localeDirectory = localeDirectory ?? 'locale';

    if (fallbackLanguages != null) {
      _fallbackLanguages.clear();
      _fallbackLanguages.addAll(fallbackLanguages);
    }

    // Load locale information
    await _loadLocaleInfo();

    // Load default language catalog
    await _loadCatalog(_defaultLanguage);

    _initialized = true;
  }

  /// Set the current language
  Future<void> setLanguage(String languageCode) async {
    if (_currentLanguage == languageCode) return;

    // Load catalog for new language if not already loaded
    if (!_catalogs.containsKey(languageCode)) {
      await _loadCatalog(languageCode);
    }

    _currentLanguage = languageCode;
  }

  /// Translate a message
  String translate(String messageId,
      {Map<String, dynamic>? args, String? domain}) {
    if (!_initialized) {
      return _interpolate(messageId, args);
    }

    final domainName = domain ?? _defaultDomain;

    // Try current language first
    String? translation =
        _getTranslation(_currentLanguage, domainName, messageId);

    // Try fallback languages
    if (translation == null) {
      for (final fallbackLang in _fallbackLanguages) {
        translation = _getTranslation(fallbackLang, domainName, messageId);
        if (translation != null) break;
      }
    }

    // Use original message if no translation found
    translation ??= messageId;

    return _interpolate(translation, args);
  }

  /// Translate with pluralization
  String ngettext(String singular, String plural, int count,
      {Map<String, dynamic>? args, String? domain}) {
    if (!_initialized) {
      return _interpolate(count == 1 ? singular : plural, args);
    }

    final domainName = domain ?? _defaultDomain;

    // Try current language first
    String? translation = _getPluralTranslation(
        _currentLanguage, domainName, singular, plural, count);

    // Try fallback languages
    if (translation == null) {
      for (final fallbackLang in _fallbackLanguages) {
        translation = _getPluralTranslation(
            fallbackLang, domainName, singular, plural, count);
        if (translation != null) break;
      }
    }

    // Use original message if no translation found
    translation ??= (count == 1 ? singular : plural);

    return _interpolate(translation, args);
  }

  /// Translate with context
  String pgettext(String context, String messageId,
      {Map<String, dynamic>? args, String? domain}) {
    final contextualMessageId = '$context\u0004$messageId';
    final translation =
        translate(contextualMessageId, args: args, domain: domain);

    // If contextual translation not found, try without context
    if (translation == contextualMessageId) {
      return translate(messageId, args: args, domain: domain);
    }

    return translation;
  }

  /// Translate with context and pluralization
  String npgettext(String context, String singular, String plural, int count,
      {Map<String, dynamic>? args, String? domain}) {
    final contextualSingular = '$context\u0004$singular';
    final contextualPlural = '$context\u0004$plural';
    final translation = ngettext(contextualSingular, contextualPlural, count,
        args: args, domain: domain);

    // If contextual translation not found, try without context
    if (translation == contextualSingular || translation == contextualPlural) {
      return ngettext(singular, plural, count, args: args, domain: domain);
    }

    return translation;
  }

  /// Load available locales
  Future<void> _loadLocaleInfo() async {
    _locales.clear();

    // Add built-in locales
    _locales['en'] = LocaleInfo(
      code: 'en',
      name: 'English',
      nativeName: 'English',
      direction: TextDirection.ltr,
      pluralForms: 'nplurals=2; plural=(n != 1);',
    );

    _locales['es'] = LocaleInfo(
      code: 'es',
      name: 'Spanish',
      nativeName: 'Español',
      direction: TextDirection.ltr,
      pluralForms: 'nplurals=2; plural=(n != 1);',
    );

    _locales['fr'] = LocaleInfo(
      code: 'fr',
      name: 'French',
      nativeName: 'Français',
      direction: TextDirection.ltr,
      pluralForms: 'nplurals=2; plural=(n > 1);',
    );

    _locales['de'] = LocaleInfo(
      code: 'de',
      name: 'German',
      nativeName: 'Deutsch',
      direction: TextDirection.ltr,
      pluralForms: 'nplurals=2; plural=(n != 1);',
    );

    _locales['ar'] = LocaleInfo(
      code: 'ar',
      name: 'Arabic',
      nativeName: 'العربية',
      direction: TextDirection.rtl,
      pluralForms:
          'nplurals=6; plural=(n==0 ? 0 : n==1 ? 1 : n==2 ? 2 : n%100>=3 && n%100<=10 ? 3 : n%100>=11 ? 4 : 5);',
    );

    _locales['zh'] = LocaleInfo(
      code: 'zh',
      name: 'Chinese',
      nativeName: '中文',
      direction: TextDirection.ltr,
      pluralForms: 'nplurals=1; plural=0;',
    );

    _locales['ja'] = LocaleInfo(
      code: 'ja',
      name: 'Japanese',
      nativeName: '日本語',
      direction: TextDirection.ltr,
      pluralForms: 'nplurals=1; plural=0;',
    );

    _locales['ru'] = LocaleInfo(
      code: 'ru',
      name: 'Russian',
      nativeName: 'Русский',
      direction: TextDirection.ltr,
      pluralForms:
          'nplurals=4; plural=(n%10==1 && n%100!=11 ? 0 : n%10>=2 && n%10<=4 && (n%100<10 || n%100>=20) ? 1 : 2);',
    );
  }

  /// Load translation catalog for a language
  Future<void> _loadCatalog(String languageCode) async {
    if (_catalogs.containsKey(languageCode)) return;

    _catalogs[languageCode] = {};

    // Try to load from files
    final localeDir = Directory('$_localeDirectory/$languageCode/LC_MESSAGES');
    if (await localeDir.exists()) {
      await for (final file in localeDir.list()) {
        if (file is File && file.path.endsWith('.json')) {
          final domain = file.path.split('/').last.replaceAll('.json', '');
          try {
            final content = await file.readAsString();
            final data = json.decode(content) as Map<String, dynamic>;
            _catalogs[languageCode]![domain] =
                TranslationCatalog.fromJson(data);
          } catch (e) {
            print('Warning: Failed to load translation file ${file.path}: $e');
          }
        }
      }
    }

    // Ensure default domain exists
    if (!_catalogs[languageCode]!.containsKey(_defaultDomain)) {
      _catalogs[languageCode]![_defaultDomain] = TranslationCatalog({});
    }
  }

  /// Get translation for a specific language and domain
  String? _getTranslation(
      String languageCode, String domain, String messageId) {
    final catalog = _catalogs[languageCode]?[domain];
    return catalog?.getTranslation(messageId);
  }

  /// Get plural translation for a specific language and domain
  String? _getPluralTranslation(String languageCode, String domain,
      String singular, String plural, int count) {
    final catalog = _catalogs[languageCode]?[domain];
    return catalog?.getPluralTranslation(
        singular, plural, count, _locales[languageCode]);
  }

  /// Interpolate variables in a message
  String _interpolate(String message, Map<String, dynamic>? args) {
    if (args == null || args.isEmpty) return message;

    String result = message;

    // Replace named placeholders like {name}
    args.forEach((key, value) {
      result = result.replaceAll('{$key}', value.toString());
    });

    // Replace positional placeholders like %s, %d
    final matches = RegExp(r'%([sd])').allMatches(result);
    var argIndex = 0;

    for (final match in matches) {
      if (argIndex < args.length) {
        final placeholder = match.group(0)!;
        final values = args.values.toList();
        result = result.replaceFirst(placeholder, values[argIndex].toString());
        argIndex++;
      }
    }

    return result;
  }

  /// Add translations programmatically
  void addTranslations(String languageCode, Map<String, String> translations,
      {String? domain}) {
    final domainName = domain ?? _defaultDomain;

    if (!_catalogs.containsKey(languageCode)) {
      _catalogs[languageCode] = {};
    }

    if (!_catalogs[languageCode]!.containsKey(domainName)) {
      _catalogs[languageCode]![domainName] = TranslationCatalog({});
    }

    _catalogs[languageCode]![domainName]!.addTranslations(translations);
  }

  /// Add plural translations programmatically
  void addPluralTranslations(String languageCode, String singular,
      String plural, List<String> translations,
      {String? domain}) {
    final domainName = domain ?? _defaultDomain;

    if (!_catalogs.containsKey(languageCode)) {
      _catalogs[languageCode] = {};
    }

    if (!_catalogs[languageCode]!.containsKey(domainName)) {
      _catalogs[languageCode]![domainName] = TranslationCatalog({});
    }

    _catalogs[languageCode]![domainName]!
        .addPluralTranslations(singular, plural, translations);
  }

  /// Get all translations for a language and domain
  Map<String, String> getTranslations(String languageCode, {String? domain}) {
    final domainName = domain ?? _defaultDomain;
    return _catalogs[languageCode]?[domainName]?.translations ?? {};
  }

  /// Export translations to JSON
  Map<String, dynamic> exportTranslations(String languageCode,
      {String? domain}) {
    final domainName = domain ?? _defaultDomain;
    return _catalogs[languageCode]?[domainName]?.toJson() ?? {};
  }

  /// Import translations from JSON
  void importTranslations(String languageCode, Map<String, dynamic> data,
      {String? domain}) {
    final domainName = domain ?? _defaultDomain;

    if (!_catalogs.containsKey(languageCode)) {
      _catalogs[languageCode] = {};
    }

    _catalogs[languageCode]![domainName] = TranslationCatalog.fromJson(data);
  }
}

/// Stores translations for a specific domain
class TranslationCatalog {
  final Map<String, String> translations;
  final Map<String, List<String>> pluralTranslations;

  TranslationCatalog(this.translations,
      {Map<String, List<String>>? pluralTranslations})
      : pluralTranslations = pluralTranslations ?? {};

  /// Get translation for a message
  String? getTranslation(String messageId) {
    return translations[messageId];
  }

  /// Get plural translation
  String? getPluralTranslation(
      String singular, String plural, int count, LocaleInfo? localeInfo) {
    final key = '$singular\u0000$plural';
    final pluralForms = pluralTranslations[key];

    if (pluralForms == null || pluralForms.isEmpty) {
      return null;
    }

    final pluralIndex = _calculatePluralIndex(count, localeInfo);

    if (pluralIndex < pluralForms.length) {
      return pluralForms[pluralIndex];
    }

    return pluralForms.last;
  }

  /// Calculate plural index based on count and locale rules
  int _calculatePluralIndex(int count, LocaleInfo? localeInfo) {
    if (localeInfo == null) {
      return count == 1 ? 0 : 1;
    }

    // Simple implementation - can be extended for complex plural rules
    switch (localeInfo.code) {
      case 'en':
      case 'es':
      case 'de':
        return count == 1 ? 0 : 1;
      case 'fr':
        return count > 1 ? 1 : 0;
      case 'ar':
        if (count == 0) return 0;
        if (count == 1) return 1;
        if (count == 2) return 2;
        if (count % 100 >= 3 && count % 100 <= 10) return 3;
        if (count % 100 >= 11) return 4;
        return 5;
      case 'zh':
      case 'ja':
        return 0;
      case 'ru':
        final mod10 = count % 10;
        final mod100 = count % 100;
        if (mod10 == 1 && mod100 != 11) return 0;
        if (mod10 >= 2 && mod10 <= 4 && (mod100 < 10 || mod100 >= 20)) return 1;
        return 2;
      default:
        return count == 1 ? 0 : 1;
    }
  }

  /// Add translations to this catalog
  void addTranslations(Map<String, String> newTranslations) {
    translations.addAll(newTranslations);
  }

  /// Add plural translations to this catalog
  void addPluralTranslations(
      String singular, String plural, List<String> pluralForms) {
    final key = '$singular\u0000$plural';
    pluralTranslations[key] = pluralForms;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'translations': translations,
      'plural_translations': pluralTranslations,
    };
  }

  /// Create from JSON
  static TranslationCatalog fromJson(Map<String, dynamic> data) {
    final translations = <String, String>{};
    if (data['translations'] != null) {
      final translationData = data['translations'];
      if (translationData is Map) {
        translationData.forEach((key, value) {
          if (key is String && value is String) {
            translations[key] = value;
          }
        });
      }
    }

    final pluralTranslations = <String, List<String>>{};
    if (data['plural_translations'] != null) {
      final pluralData = data['plural_translations'];
      if (pluralData is Map) {
        pluralData.forEach((key, value) {
          if (key is String && value is List) {
            pluralTranslations[key] = List<String>.from(value);
          }
        });
      }
    }

    return TranslationCatalog(translations,
        pluralTranslations: pluralTranslations);
  }
}

/// Information about a locale
class LocaleInfo {
  final String code;
  final String name;
  final String nativeName;
  final TextDirection direction;
  final String pluralForms;

  LocaleInfo({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.direction,
    required this.pluralForms,
  });
}

/// Text direction for locale
enum TextDirection {
  ltr,
  rtl,
}

/// Lazy translation that gets evaluated at runtime
class LazyTranslation {
  final String messageId;
  final Map<String, dynamic>? args;
  final String? domain;

  LazyTranslation(this.messageId, {this.args, this.domain});

  @override
  String toString() {
    return I18n.instance.translate(messageId, args: args, domain: domain);
  }
}

/// Middleware for language detection from HTTP requests
class LocaleMiddleware {
  static const String languageHeader = 'Accept-Language';
  static const String languageCookie = 'django_language';
  static const String languageSession = 'django_language';

  /// Detect language from HTTP request
  static String detectLanguage(
    Map<String, String> headers,
    Map<String, String> cookies,
    Map<String, dynamic> session,
    List<String> availableLanguages,
  ) {
    // 1. Check session
    final sessionLang = session[languageSession] as String?;
    if (sessionLang != null && availableLanguages.contains(sessionLang)) {
      return sessionLang;
    }

    // 2. Check cookie
    final cookieLang = cookies[languageCookie];
    if (cookieLang != null && availableLanguages.contains(cookieLang)) {
      return cookieLang;
    }

    // 3. Check Accept-Language header
    final acceptLang = headers[languageHeader];
    if (acceptLang != null) {
      final preferred = _parseAcceptLanguage(acceptLang);
      for (final lang in preferred) {
        if (availableLanguages.contains(lang)) {
          return lang;
        }
        // Try language without region (e.g., 'en' from 'en-US')
        final baseLang = lang.split('-')[0];
        if (availableLanguages.contains(baseLang)) {
          return baseLang;
        }
      }
    }

    // 4. Fall back to default
    return I18n.instance.defaultLanguage;
  }

  /// Parse Accept-Language header
  static List<String> _parseAcceptLanguage(String acceptLanguage) {
    final languages = <String>[];
    final parts = acceptLanguage.split(',');

    for (final part in parts) {
      final trimmed = part.trim();
      final lang = trimmed.split(';')[0].trim();
      if (lang.isNotEmpty) {
        languages.add(lang);
      }
    }

    return languages;
  }
}

/// Utilities for date and number formatting
class LocaleUtils {
  /// Format date according to locale
  static String formatDate(DateTime date, String languageCode) {
    // Simple implementation - can be extended with proper locale formatting
    switch (languageCode) {
      case 'en':
        return '${date.month}/${date.day}/${date.year}';
      case 'de':
        return '${date.day}.${date.month}.${date.year}';
      case 'fr':
        return '${date.day}/${date.month}/${date.year}';
      case 'ar':
        return '${date.year}/${date.month}/${date.day}';
      default:
        return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }

  /// Format number according to locale
  static String formatNumber(num number, String languageCode) {
    // Simple implementation - can be extended with proper locale formatting
    switch (languageCode) {
      case 'de':
        return number.toString().replaceAll('.', ',');
      case 'fr':
        return number.toString().replaceAll('.', ',');
      default:
        return number.toString();
    }
  }

  /// Format currency according to locale
  static String formatCurrency(
      num amount, String currencyCode, String languageCode) {
    final formattedAmount = formatNumber(amount, languageCode);

    switch (languageCode) {
      case 'en':
        return '\$${formattedAmount}';
      case 'de':
        return '${formattedAmount} €';
      case 'fr':
        return '${formattedAmount} €';
      case 'ar':
        return '${formattedAmount} ${currencyCode}';
      default:
        return '${formattedAmount} ${currencyCode}';
    }
  }
}

/// Initialize the i18n system
Future<void> initializeI18n({
  String? defaultLanguage,
  String? localeDirectory,
  List<String>? fallbackLanguages,
}) async {
  await I18n.instance.initialize(
    defaultLanguage: defaultLanguage,
    localeDirectory: localeDirectory,
    fallbackLanguages: fallbackLanguages,
  );
}

/// Get available languages
List<String> getAvailableLanguages() {
  return I18n.instance.availableLanguages;
}

/// Get current language
String getCurrentLanguage() {
  return I18n.instance.currentLanguage;
}

/// Set current language
Future<void> setLanguage(String languageCode) async {
  await I18n.instance.setLanguage(languageCode);
}
