import 'package:test/test.dart';

import '../../../lib/src/core/templates/context.dart';
import '../../../lib/src/core/templates/loader.dart';
import '../../../lib/src/core/templates/exceptions.dart';

void main() {
  group('Template Edge Cases and Boundary Conditions', () {
    group('TemplateContext Edge Cases', () {
      test('should handle initialization with null values in map', () {
        final context = TemplateContext({'key': null, 'valid': 'value'});
        expect(context['key'], isNull);
        expect(context['valid'], equals('value'));
      });

      test('should handle setting null values', () {
        final context = TemplateContext();
        context['key'] = null;
        expect(context['key'], isNull);
      });

      test('should handle empty context', () {
        final context = TemplateContext({});
        expect(context.isEmpty(), isTrue);
        expect(context.length, equals(0));
      });

      test('should handle get with default value for non-existent key', () {
        final context = TemplateContext();
        expect(context.get('missing', 'default'), equals('default'));
      });

      test('should handle get with null default value', () {
        final context = TemplateContext();
        expect(context.get('missing', null), isNull);
      });

      test('should handle very deep context stack', () {
        final context = TemplateContext();

        for (int i = 0; i < 100; i++) {
          context.push({'level': i});
        }

        expect(context['level'], equals(99));

        for (int i = 0; i < 99; i++) {
          context.pop();
        }

        expect(context['level'], equals(0));
      });

      test('should handle popping last context', () {
        final context = TemplateContext({'initial': 'value'});

        expect(
          () => context.pop(),
          throwsA(isA<StateError>()),
        );
      });

      test('should handle empty string keys', () {
        final context = TemplateContext();
        context[''] = 'empty-key-value';
        expect(context[''], equals('empty-key-value'));
      });

      test('should handle keys with special characters', () {
        final context = TemplateContext();
        context['key.with.dots'] = 'value1';
        context['key:with:colons'] = 'value2';
        context['key-with-dashes'] = 'value3';

        expect(context['key.with.dots'], equals('value1'));
        expect(context['key:with:colons'], equals('value2'));
        expect(context['key-with-dashes'], equals('value3'));
      });

      test('should handle flattening large context', () {
        final context = TemplateContext();

        for (int i = 0; i < 10; i++) {
          final layer = <String, dynamic>{};
          for (int j = 0; j < 100; j++) {
            layer['key${i}_$j'] = 'value${i}_$j';
          }
          context.push(layer);
        }

        final flattened = context.flatten();
        expect(flattened.length, greaterThanOrEqualTo(100));
      });

      test('should handle copy of context with globals', () {
        final context = TemplateContext({'local': 'value'});
        context.setGlobal('global', 'global-value');

        final copy = context.copy();
        expect(copy['local'], equals('value'));
        expect(copy.getGlobal('global'), equals('global-value'));

        /// Modify copy should not affect original
        copy['local'] = 'modified';
        expect(context['local'], equals('value'));
      });

      test('should handle updating context with empty map', () {
        final context = TemplateContext({'key': 'value'});
        context.update({});
        expect(context['key'], equals('value'));
      });

      test('should handle updating context with overlapping keys', () {
        final context = TemplateContext({'key': 'original'});
        context.update({'key': 'updated', 'new': 'value'});
        expect(context['key'], equals('updated'));
        expect(context['new'], equals('value'));
      });
    });

    group('ContextVariable Edge Cases', () {
      test('should handle resolving empty variable name', () {
        final context = TemplateContext();
        final variable = ContextVariable('');
        final result = variable.resolve(context);
        expect(result, isNull);
      });

      test('should handle resolving null variable in context', () {
        final context = TemplateContext({'null_var': null});
        final variable = ContextVariable('null_var');
        final result = variable.resolve(context);
        expect(result, isNull);
      });

      test('should handle nested attribute access on null', () {
        final context = TemplateContext({'obj': null});
        final variable = ContextVariable('obj.nested.deep');
        final result = variable.resolve(context);
        expect(result, isNull);
      });

      test('should handle list index out of bounds', () {
        final context = TemplateContext({
          'list': [1, 2, 3]
        });
        final variable = ContextVariable('list.10');
        final result = variable.resolve(context);
        expect(result, isNull);
      });

      test('should handle negative list index', () {
        final context = TemplateContext({
          'list': [1, 2, 3]
        });
        final variable = ContextVariable('list.-1');
        final result = variable.resolve(context);
        expect(result, isNull);
      });

      test('should handle accessing non-existent map key', () {
        final context = TemplateContext({
          'map': {'key': 'value'}
        });
        final variable = ContextVariable('map.missing');
        final result = variable.resolve(context);
        expect(result, isNull);
      });

      test('should handle empty filter list', () {
        final context = TemplateContext({'key': 'value'});
        final variable = ContextVariable('key', []);
        final result = variable.resolve(context);
        expect(result, equals('value'));
      });

      test('should parse variable with multiple filters', () {
        final variable = ContextVariable.parse('name|upper|truncate:10');
        expect(variable.name, equals('name'));
        expect(variable.filters.length, equals(2));
        expect(variable.filters[0], equals('upper'));
        expect(variable.filters[1], equals('truncate:10'));
      });

      test('should parse variable with no filters', () {
        final variable = ContextVariable.parse('simple_name');
        expect(variable.name, equals('simple_name'));
        expect(variable.filters, isEmpty);
      });

      test('should handle whitespace in variable expression', () {
        final variable = ContextVariable.parse('  name  |  upper  ');
        expect(variable.name, equals('name'));
        expect(variable.filters.length, equals(1));
        expect(variable.filters[0], equals('upper'));
      });
    });

    group('Template Loader Edge Cases', () {
      test('should handle StringLoader with empty template name', () {
        final loader = StringLoader({'': 'empty-name-template'});
        final source = loader.loadTemplate('');
        expect(source.source, equals('empty-name-template'));
      });

      test('should handle StringLoader with empty template content', () {
        final loader = StringLoader({'template': ''});
        final source = loader.loadTemplate('template');
        expect(source.source, equals(''));
      });

      test('should handle StringLoader loading non-existent template', () {
        final loader = StringLoader({'exists': 'content'});

        expect(
          () => loader.loadTemplate('missing'),
          throwsA(isA<TemplateNotFoundException>()),
        );
      });

      test('should handle MemoryLoader with null origin', () {
        final loader = MemoryLoader();
        loader.addTemplate('test', 'content', origin: null);

        final source = loader.loadTemplate('test');
        expect(source.origin, equals('memory:test'));
      });

      test('should handle MemoryLoader clear', () {
        final loader = MemoryLoader();
        loader.addTemplate('t1', 'content1');
        loader.addTemplate('t2', 'content2');

        loader.clear();

        expect(
          () => loader.loadTemplate('t1'),
          throwsA(isA<TemplateNotFoundException>()),
        );
        expect(loader.listTemplates(), isEmpty);
      });

      test('should handle CachedLoader with expired cache', () async {
        final baseLoader = StringLoader({'test': 'content'});
        final cachedLoader = CachedLoader(
          baseLoader,
          cacheTimeout: const Duration(milliseconds: 100),
        );

        /// First load - cache miss
        final source1 = cachedLoader.loadTemplate('test');
        expect(source1.source, equals('content'));

        /// Wait for cache to expire
        await Future.delayed(const Duration(milliseconds: 150));

        /// Second load - should reload from base loader
        final source2 = cachedLoader.loadTemplate('test');
        expect(source2.source, equals('content'));
      });

      test('should handle CachedLoader clearCache', () {
        final baseLoader = StringLoader({'test': 'content'});
        final cachedLoader = CachedLoader(baseLoader);

        cachedLoader.loadTemplate('test');
        cachedLoader.clearCache();

        /// Next load should hit base loader again
        final source = cachedLoader.loadTemplate('test');
        expect(source.source, equals('content'));
      });

      test('should handle CachedLoader removeCached', () {
        final baseLoader = StringLoader({'t1': 'c1', 't2': 'c2'});
        final cachedLoader = CachedLoader(baseLoader);

        cachedLoader.loadTemplate('t1');
        cachedLoader.loadTemplate('t2');

        cachedLoader.removeCached('t1');

        /// t1 should be reloaded, t2 still cached
        final source = cachedLoader.loadTemplate('t1');
        expect(source.source, equals('c1'));
      });

      test('should handle ChainLoader with empty loader list', () {
        final chainLoader = ChainLoader([]);

        expect(
          () => chainLoader.loadTemplate('test'),
          throwsA(isA<TemplateNotFoundException>()),
        );
      });

      test('should handle ChainLoader with all loaders failing', () {
        final loader1 = StringLoader({'other': 'content'});
        final loader2 = StringLoader({'another': 'content'});
        final chainLoader = ChainLoader([loader1, loader2]);

        expect(
          () => chainLoader.loadTemplate('missing'),
          throwsA(isA<TemplateNotFoundException>()),
        );
      });

      test('should handle ChainLoader exists check', () {
        final loader1 = StringLoader({'t1': 'c1'});
        final loader2 = StringLoader({'t2': 'c2'});
        final chainLoader = ChainLoader([loader1, loader2]);

        expect(chainLoader.exists('t1'), isTrue);
        expect(chainLoader.exists('t2'), isTrue);
        expect(chainLoader.exists('missing'), isFalse);
      });

      test('should handle ChainLoader listTemplates with duplicates', () {
        final loader1 = StringLoader({'shared': 'c1', 't1': 'c1'});
        final loader2 = StringLoader({'shared': 'c2', 't2': 'c2'});
        final chainLoader = ChainLoader([loader1, loader2]);

        final templates = chainLoader.listTemplates();

        /// Should not have duplicates
        expect(templates.toSet().length, equals(templates.length));
        expect(templates, containsAll(['shared', 't1', 't2']));
      });

      test('should handle CompoundLoader with empty prefix', () {
        final baseLoader = StringLoader({'test': 'content'});
        final compoundLoader = CompoundLoader({'': baseLoader});

        final source = compoundLoader.loadTemplate(':test');
        expect(source.source, equals('content'));
      });

      test('should handle CompoundLoader with missing namespace', () {
        final loader = StringLoader({'test': 'content'});
        final compoundLoader = CompoundLoader({'app': loader});

        expect(
          () => compoundLoader.loadTemplate('test'),
          throwsA(isA<TemplateNotFoundException>()),
        );
      });

      test('should handle CompoundLoader with malformed template name', () {
        final loader = StringLoader({'test': 'content'});
        final compoundLoader = CompoundLoader({'app': loader});

        expect(
          () => compoundLoader.loadTemplate('no-colon-separator'),
          throwsA(isA<TemplateNotFoundException>()),
        );
      });

      test('should handle CompoundLoader exists check', () {
        final loader = StringLoader({'test': 'content'});
        final compoundLoader = CompoundLoader({'app': loader});

        expect(compoundLoader.exists('app:test'), isTrue);
        expect(compoundLoader.exists('app:missing'), isFalse);
        expect(compoundLoader.exists('missing:test'), isFalse);
        expect(compoundLoader.exists('no-namespace'), isFalse);
      });

      test('should handle CompoundLoader listTemplates', () {
        final loader1 = StringLoader({'t1': 'c1', 't2': 'c2'});
        final loader2 = StringLoader({'t3': 'c3'});
        final compoundLoader = CompoundLoader({
          'app': loader1,
          'lib': loader2,
        });

        final templates = compoundLoader.listTemplates();

        expect(templates, containsAll(['app:t1', 'app:t2', 'lib:t3']));
        expect(templates.length, equals(3));
      });
    });

    group('DatabaseLoader Edge Cases', () {
      test('should handle DatabaseLoader with default configuration', () {
        final loader = DatabaseLoader();

        /// Should not throw on construction
        expect(loader.tableName, equals('templates'));
        expect(loader.nameColumn, equals('name'));
        expect(loader.contentColumn, equals('content'));
      });

      test('should handle DatabaseLoader loading non-existent template', () {
        final loader = DatabaseLoader();

        expect(
          () => loader.loadTemplate('missing'),
          throwsA(isA<TemplateNotFoundException>()),
        );
      });

      test('should handle DatabaseLoader exists check', () {
        final loader = DatabaseLoader();

        expect(loader.exists('any-template'), isFalse);
      });

      test('should handle DatabaseLoader listTemplates', () {
        final loader = DatabaseLoader();

        expect(loader.listTemplates(), isEmpty);
      });
    });

    group('TemplateContextProcessor Edge Cases', () {
      test('should handle processor returning null', () {
        final processor = TemplateContextProcessor(
          'test',
          (request) => <String, dynamic>{},
        );

        final result = processor.process(null);
        expect(result, isNotNull);
        expect(result, isEmpty);
      });

      test('should handle processor throwing exception', () {
        final processor = TemplateContextProcessor(
          'failing',
          (request) => throw Exception('processor error'),
        );

        expect(
          () => processor.process(null),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle manager with no processors', () {
        final manager = TemplateContextProcessorManager();
        final result = manager.processAll(null);
        expect(result, isEmpty);
      });

      test('should handle manager with failing processor', () {
        final manager = TemplateContextProcessorManager();

        manager.addProcessor(TemplateContextProcessor(
          'success',
          (request) => {'key': 'value'},
        ));

        manager.addProcessor(TemplateContextProcessor(
          'failing',
          (request) => throw Exception('error'),
        ));

        manager.addProcessor(TemplateContextProcessor(
          'another',
          (request) => {'another': 'value'},
        ));

        /// Should continue processing even if one fails
        final result = manager.processAll(null);
        expect(result['key'], equals('value'));
        expect(result['another'], equals('value'));
      });

      test('should handle removing non-existent processor', () {
        final manager = TemplateContextProcessorManager();

        manager.addProcessor(TemplateContextProcessor(
          'exists',
          (request) => {},
        ));

        /// Should not throw
        manager.removeProcessor('non-existent');

        final result = manager.processAll(null);
        expect(result, isNotNull);
      });

      test('should handle multiple processors with overlapping keys', () {
        final manager = TemplateContextProcessorManager();

        manager.addProcessor(TemplateContextProcessor(
          'first',
          (request) => {'shared': 'first-value', 'unique1': 'value1'},
        ));

        manager.addProcessor(TemplateContextProcessor(
          'second',
          (request) => {'shared': 'second-value', 'unique2': 'value2'},
        ));

        final result = manager.processAll(null);

        /// Later processors should override earlier ones
        expect(result['shared'], equals('second-value'));
        expect(result['unique1'], equals('value1'));
        expect(result['unique2'], equals('value2'));
      });
    });
  });
}
