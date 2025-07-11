import 'package:test/test.dart';

import '../lib/src/core/i18n/i18n.dart';

// Define convenience functions for testing
String testTranslate(String messageId,
    {Map<String, dynamic>? args, String? domain}) {
  return I18n.instance.translate(messageId, args: args, domain: domain);
}

LazyTranslation testLazy(String messageId,
    {Map<String, dynamic>? args, String? domain}) {
  return LazyTranslation(messageId, args: args, domain: domain);
}

String testNgettext(String singular, String plural, int count,
    {Map<String, dynamic>? args, String? domain}) {
  return I18n.instance
      .ngettext(singular, plural, count, args: args, domain: domain);
}

String testPgettext(String context, String messageId,
    {Map<String, dynamic>? args, String? domain}) {
  return I18n.instance.pgettext(context, messageId, args: args, domain: domain);
}

String testNpgettext(String context, String singular, String plural, int count,
    {Map<String, dynamic>? args, String? domain}) {
  return I18n.instance
      .npgettext(context, singular, plural, count, args: args, domain: domain);
}

void main() {
  group('I18n System Tests', () {
    late I18n i18n;

    setUp(() async {
      i18n = I18n.instance;
      await i18n.initialize(defaultLanguage: 'en');
    });

    tearDown(() async {
      await i18n.setLanguage('en');
    });

    group('Basic Translation', () {
      test('should translate simple messages', () async {
        i18n.addTranslations('es', {
          'Hello': 'Hola',
          'Goodbye': 'Adiós',
          'Welcome': 'Bienvenido',
        });

        await i18n.setLanguage('es');

        expect(testTranslate('Hello'), equals('Hola'));
        expect(testTranslate('Goodbye'), equals('Adiós'));
        expect(testTranslate('Welcome'), equals('Bienvenido'));
      });

      test('should return original message if translation not found', () async {
        await i18n.setLanguage('fr');

        expect(testTranslate('Hello'), equals('Hello'));
        expect(testTranslate('Unknown message'), equals('Unknown message'));
      });

      test('should support message interpolation', () async {
        i18n.addTranslations('es', {
          'Hello {name}': 'Hola {name}',
          'Welcome {name} to {place}': 'Bienvenido {name} a {place}',
        });

        await i18n.setLanguage('es');

        expect(testTranslate('Hello {name}', args: {'name': 'Juan'}),
            equals('Hola Juan'));
        expect(
            testTranslate('Welcome {name} to {place}',
                args: {'name': 'Maria', 'place': 'Madrid'}),
            equals('Bienvenido Maria a Madrid'));
      });

      test('should support positional placeholders', () async {
        i18n.addTranslations('es', {
          'Hello %s': 'Hola %s',
          'Welcome %s to %s': 'Bienvenido %s a %s',
        });

        await i18n.setLanguage('es');

        expect(testTranslate('Hello %s', args: {'0': 'Juan'}),
            equals('Hola Juan'));
        expect(
            testTranslate('Welcome %s to %s',
                args: {'0': 'Maria', '1': 'Madrid'}),
            equals('Bienvenido Maria a Madrid'));
      });
    });

    group('Pluralization', () {
      test('should handle simple pluralization', () async {
        i18n.addPluralTranslations(
            'es', 'item', 'items', ['artículo', 'artículos']);

        await i18n.setLanguage('es');

        expect(testNgettext('item', 'items', 1), equals('artículo'));
        expect(testNgettext('item', 'items', 2), equals('artículos'));
        expect(testNgettext('item', 'items', 0), equals('artículos'));
      });

      test('should handle pluralization with interpolation', () async {
        i18n.addPluralTranslations('es', '{count} item', '{count} items',
            ['{count} artículo', '{count} artículos']);

        await i18n.setLanguage('es');

        expect(
            testNgettext('{count} item', '{count} items', 1,
                args: {'count': 1}),
            equals('1 artículo'));
        expect(
            testNgettext('{count} item', '{count} items', 5,
                args: {'count': 5}),
            equals('5 artículos'));
      });

      test('should handle complex pluralization rules', () async {
        // Test Russian pluralization (0: few, 1: one, 2-4: few, 5+: many)
        final catalog = TranslationCatalog({}, pluralTranslations: {
          'item\u0000items': ['предмет', 'предмета', 'предметов']
        });

        i18n.importTranslations('ru', catalog.toJson());
        await i18n.setLanguage('ru');

        expect(testNgettext('item', 'items', 1), equals('предмет'));
        expect(testNgettext('item', 'items', 2), equals('предмета'));
        expect(testNgettext('item', 'items', 5), equals('предметов'));
      });
    });

    group('Context-aware Translation', () {
      test('should handle contextual translations', () async {
        i18n.addTranslations('es', {
          'button\u0004Save': 'Guardar',
          'file\u0004Save': 'Guardar archivo',
          'Save': 'Salvar',
        });

        await i18n.setLanguage('es');

        expect(testPgettext('button', 'Save'), equals('Guardar'));
        expect(testPgettext('file', 'Save'), equals('Guardar archivo'));
        expect(testPgettext('unknown', 'Save'), equals('Salvar'));
      });

      test('should handle contextual pluralization', () async {
        i18n.addTranslations('es', {
          'email\u0004message': 'mensaje',
          'email\u0004messages': 'mensajes',
          'message': 'mensaje genérico',
          'messages': 'mensajes genéricos',
        });

        await i18n.setLanguage('es');

        expect(testNpgettext('email', 'message', 'messages', 1),
            equals('mensaje'));
        expect(testNpgettext('email', 'message', 'messages', 2),
            equals('mensajes'));
        expect(testNpgettext('unknown', 'message', 'messages', 1),
            equals('mensaje genérico'));
      });
    });

    group('Lazy Translation', () {
      test('should support lazy translation', () async {
        i18n.addTranslations('es', {
          'Hello': 'Hola',
        });

        final lazy = testLazy('Hello');

        // Should return English initially
        await i18n.setLanguage('en');
        expect(lazy.toString(), equals('Hello'));

        // Should return Spanish after language change
        await i18n.setLanguage('es');
        expect(lazy.toString(), equals('Hola'));
      });
    });

    group('Domains', () {
      test('should support translation domains', () async {
        i18n.addTranslations(
            'es',
            {
              'Save': 'Guardar',
            },
            domain: 'buttons');

        i18n.addTranslations(
            'es',
            {
              'Save': 'Guardar archivo',
            },
            domain: 'files');

        await i18n.setLanguage('es');

        expect(testTranslate('Save', domain: 'buttons'), equals('Guardar'));
        expect(
            testTranslate('Save', domain: 'files'), equals('Guardar archivo'));
      });
    });

    group('Locale Information', () {
      test('should provide locale information', () async {
        await i18n.setLanguage('ar');

        final locale = i18n.currentLocale;
        expect(locale, isNotNull);
        expect(locale!.code, equals('ar'));
        expect(locale.name, equals('Arabic'));
        expect(locale.direction, equals(TextDirection.rtl));
      });

      test('should list available languages', () async {
        i18n.addTranslations('fr', {'Hello': 'Bonjour'});
        i18n.addTranslations('de', {'Hello': 'Hallo'});

        final languages = i18n.availableLanguages;
        expect(languages, contains('en'));
        expect(languages, contains('fr'));
        expect(languages, contains('de'));
      });
    });

    group('Language Detection', () {
      test('should detect language from Accept-Language header', () async {
        final headers = {'Accept-Language': 'es-ES,es;q=0.9,en;q=0.8'};
        final cookies = <String, String>{};
        final session = <String, dynamic>{};
        final available = ['en', 'es', 'fr'];

        final detected = LocaleMiddleware.detectLanguage(
            headers, cookies, session, available);
        expect(detected, equals('es'));
      });

      test('should detect language from cookie', () async {
        final headers = <String, String>{};
        final cookies = {'django_language': 'fr'};
        final session = <String, dynamic>{};
        final available = ['en', 'es', 'fr'];

        final detected = LocaleMiddleware.detectLanguage(
            headers, cookies, session, available);
        expect(detected, equals('fr'));
      });

      test('should detect language from session', () async {
        final headers = <String, String>{};
        final cookies = <String, String>{};
        final session = {'django_language': 'de'};
        final available = ['en', 'es', 'fr', 'de'];

        final detected = LocaleMiddleware.detectLanguage(
            headers, cookies, session, available);
        expect(detected, equals('de'));
      });

      test('should fall back to default language', () async {
        final headers = <String, String>{};
        final cookies = <String, String>{};
        final session = <String, dynamic>{};
        final available = ['en', 'es', 'fr'];

        final detected = LocaleMiddleware.detectLanguage(
            headers, cookies, session, available);
        expect(detected, equals('en'));
      });
    });

    group('Locale Utilities', () {
      test('should format dates according to locale', () async {
        final date = DateTime(2023, 12, 25);

        expect(LocaleUtils.formatDate(date, 'en'), equals('12/25/2023'));
        expect(LocaleUtils.formatDate(date, 'de'), equals('25.12.2023'));
        expect(LocaleUtils.formatDate(date, 'fr'), equals('25/12/2023'));
      });

      test('should format numbers according to locale', () async {
        expect(LocaleUtils.formatNumber(1234.56, 'en'), equals('1234.56'));
        expect(LocaleUtils.formatNumber(1234.56, 'de'), equals('1234,56'));
        expect(LocaleUtils.formatNumber(1234.56, 'fr'), equals('1234,56'));
      });

      test('should format currency according to locale', () async {
        expect(LocaleUtils.formatCurrency(123.45, 'USD', 'en'),
            equals('\$123.45'));
        expect(LocaleUtils.formatCurrency(123.45, 'EUR', 'de'),
            equals('123,45 €'));
        expect(LocaleUtils.formatCurrency(123.45, 'EUR', 'fr'),
            equals('123,45 €'));
      });
    });

    group('Import/Export', () {
      test('should export translations to JSON', () async {
        i18n.addTranslations('es', {
          'Hello': 'Hola',
          'Goodbye': 'Adiós',
        });

        final exported = i18n.exportTranslations('es');
        expect(exported['translations']['Hello'], equals('Hola'));
        expect(exported['translations']['Goodbye'], equals('Adiós'));
      });

      test('should import translations from JSON', () async {
        final translations = {
          'translations': {
            'Hello': 'Bonjour',
            'Goodbye': 'Au revoir',
          },
          'plural_translations': {},
        };

        i18n.importTranslations('fr', translations);
        await i18n.setLanguage('fr');

        expect(testTranslate('Hello'), equals('Bonjour'));
        expect(testTranslate('Goodbye'), equals('Au revoir'));
      });
    });

    group('Fallback Languages', () {
      test('should use fallback languages when translation not found',
          () async {
        await i18n.initialize(
          defaultLanguage: 'en',
          fallbackLanguages: ['en', 'es'],
        );

        i18n.addTranslations('es', {
          'Hello': 'Hola',
        });

        await i18n.setLanguage('fr');

        // Should fall back to Spanish translation
        expect(testTranslate('Hello'), equals('Hola'));
        expect(testTranslate('Unknown'), equals('Unknown'));
      });
    });
  });
}
