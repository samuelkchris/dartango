import 'package:test/test.dart';

import '../../../lib/src/core/templates/context.dart';
import '../../../lib/src/core/templates/loader.dart';
import '../../../lib/src/core/templates/filters.dart';
import '../../../lib/src/core/templates/exceptions.dart';

void main() {
  group('TemplateContext', () {
    test('should create empty context', () {
      final context = TemplateContext();

      expect(context.keys, isEmpty);
      expect(context.isEmpty(), isFalse);
    });

    test('should create context with initial values', () {
      final context = TemplateContext({'name': 'John', 'age': 30});

      expect(context['name'], equals('John'));
      expect(context['age'], equals(30));
      expect(context.containsKey('name'), isTrue);
    });

    test('should get and set values', () {
      final context = TemplateContext();

      context['username'] = 'alice';
      expect(context['username'], equals('alice'));

      context['count'] = 42;
      expect(context['count'], equals(42));
    });

    test('should return null for non-existent keys', () {
      final context = TemplateContext();

      expect(context['nonexistent'], isNull);
      expect(context.containsKey('nonexistent'), isFalse);
    });

    test('should push and pop context layers', () {
      final context = TemplateContext({'level': 0});

      context.push({'level': 1});
      expect(context['level'], equals(1));

      context.push({'level': 2});
      expect(context['level'], equals(2));

      context.pop();
      expect(context['level'], equals(1));

      context.pop();
      expect(context['level'], equals(0));
    });

    test('should not pop the last context', () {
      final context = TemplateContext();

      expect(() => context.pop(), throwsStateError);
    });

    test('should handle global variables', () {
      final context = TemplateContext({'local': 'value'});

      context.setGlobal('global', 'global_value');

      context.push({'local': 'new_value'});

      expect(context['local'], equals('new_value'));
      expect(context['global'], equals('global_value'));
      expect(context.getGlobal('global'), equals('global_value'));
    });

    test('should prioritize globals over locals', () {
      final context = TemplateContext({'key': 'local'});
      context.setGlobal('key', 'global');

      expect(context['key'], equals('global'));
    });

    test('should remove variables', () {
      final context = TemplateContext({'name': 'John'});

      context.remove('name');
      expect(context.containsKey('name'), isFalse);
    });

    test('should remove global variables', () {
      final context = TemplateContext();
      context.setGlobal('global', 'value');

      context.removeGlobal('global');
      expect(context.getGlobal('global'), isNull);
    });

    test('should handle auto escape setting', () {
      final context = TemplateContext();

      expect(context.autoEscape, isTrue);

      context.setAutoEscape(false);
      expect(context.autoEscape, isFalse);

      context.setAutoEscape(true);
      expect(context.autoEscape, isTrue);
    });

    test('should flatten context stack', () {
      final context = TemplateContext({'level0': 'value0'});
      context.push({'level1': 'value1'});
      context.push({'level2': 'value2'});
      context.setGlobal('global', 'global_value');

      final flat = context.flatten();

      expect(flat['level0'], equals('value0'));
      expect(flat['level1'], equals('value1'));
      expect(flat['level2'], equals('value2'));
      expect(flat['global'], equals('global_value'));
    });

    test('should copy context', () {
      final original = TemplateContext({'key': 'value'});
      original.setGlobal('global', 'global_value');
      original.setAutoEscape(false);

      final copy = original.copy();

      expect(copy['key'], equals('value'));
      expect(copy.getGlobal('global'), equals('global_value'));
      expect(copy.autoEscape, isFalse);

      copy['key'] = 'modified';
      expect(original['key'], equals('value'));
    });

    test('should update context', () {
      final context = TemplateContext({'existing': 'value'});

      context.update({'new': 'value', 'another': 'data'});

      expect(context['existing'], equals('value'));
      expect(context['new'], equals('value'));
      expect(context['another'], equals('data'));
    });

    test('should return all keys', () {
      final context = TemplateContext({'a': 1, 'b': 2});
      context.push({'c': 3});
      context.setGlobal('d', 4);

      final keys = context.keys.toList();

      expect(keys, containsAll(['a', 'b', 'c', 'd']));
    });

    test('should convert to string', () {
      final context = TemplateContext({'name': 'Test'});
      final str = context.toString();

      expect(str, contains('TemplateContext'));
      expect(str, contains('name'));
    });
  });

  group('TemplateContext Extensions', () {
    test('should set and get with extension methods', () {
      final context = TemplateContext();

      context.set('key', 'value');
      expect(context.get('key'), equals('value'));
    });

    test('should get with default value', () {
      final context = TemplateContext();

      expect(context.get('nonexistent', 'default'), equals('default'));
      expect(context.get('nonexistent'), isNull);
    });

    test('should check if empty', () {
      final emptyContext = TemplateContext();
      expect(emptyContext.isEmpty(), isTrue);

      final nonEmptyContext = TemplateContext({'key': 'value'});
      expect(nonEmptyContext.isEmpty(), isFalse);
    });

    test('should return length', () {
      final context = TemplateContext({'a': 1, 'b': 2});
      context.push({'c': 3});

      expect(context.length, equals(3));
    });

    test('should execute with context', () {
      final context = TemplateContext({'outer': 'value'});
      var innerValue;

      context.withContext({'inner': 'temp'}, () {
        innerValue = context['inner'];
      });

      expect(innerValue, equals('temp'));
      expect(context.containsKey('inner'), isFalse);
    });

    test('should execute with context and return result', () {
      final context = TemplateContext({'x': 10});

      final result = context.withContextResult({'y': 20}, () {
        return (context['x'] as int) + (context['y'] as int);
      });

      expect(result, equals(30));
      expect(context.containsKey('y'), isFalse);
    });
  });

  group('ContextVariable', () {
    late TemplateContext context;

    setUp(() {
      context = TemplateContext({
        'name': 'John',
        'user': {
          'username': 'john_doe',
          'profile': {'bio': 'Developer'}
        },
        'items': ['a', 'b', 'c']
      });
    });

    test('should resolve simple variable', () {
      final variable = ContextVariable('name');

      expect(variable.resolve(context), equals('John'));
    });

    test('should resolve nested map variable', () {
      final variable = ContextVariable('user.username');

      expect(variable.resolve(context), equals('john_doe'));
    });

    test('should resolve deeply nested variable', () {
      final variable = ContextVariable('user.profile.bio');

      expect(variable.resolve(context), equals('Developer'));
    });

    test('should resolve list index', () {
      final variable = ContextVariable('items.1');

      expect(variable.resolve(context), equals('b'));
    });

    test('should return null for non-existent variable', () {
      final variable = ContextVariable('nonexistent');

      expect(variable.resolve(context), isNull);
    });

    test('should return null for invalid nested path', () {
      final variable = ContextVariable('user.invalid.path');

      expect(variable.resolve(context), isNull);
    });

    test('should parse variable from expression', () {
      final variable = ContextVariable.parse('name');

      expect(variable.name, equals('name'));
      expect(variable.filters, isEmpty);
    });

    test('should parse variable with filters', () {
      final variable = ContextVariable.parse('name|upper|truncate:10');

      expect(variable.name, equals('name'));
      expect(variable.filters, hasLength(2));
      expect(variable.filters[0], equals('upper'));
      expect(variable.filters[1], equals('truncate:10'));
    });

    test('should parse expression with whitespace', () {
      final variable = ContextVariable.parse(' name | upper ');

      expect(variable.name, equals('name'));
      expect(variable.filters, contains('upper'));
    });
  });

  group('TemplateContextProcessor', () {
    test('should create and execute processor', () {
      final processor = TemplateContextProcessor('test', (request) {
        return {'processed': true, 'request_id': request};
      });

      final result = processor.process('test-request');

      expect(result['processed'], isTrue);
      expect(result['request_id'], equals('test-request'));
    });

    test('should have name property', () {
      final processor = TemplateContextProcessor('my_processor', (request) {
        return {};
      });

      expect(processor.name, equals('my_processor'));
    });
  });

  group('TemplateContextProcessorManager', () {
    test('should add and execute processors', () {
      final manager = TemplateContextProcessorManager();

      manager.addProcessor(TemplateContextProcessor('proc1', (request) {
        return {'key1': 'value1'};
      }));

      manager.addProcessor(TemplateContextProcessor('proc2', (request) {
        return {'key2': 'value2'};
      }));

      final result = manager.processAll(null);

      expect(result['key1'], equals('value1'));
      expect(result['key2'], equals('value2'));
    });

    test('should remove processor by name', () {
      final manager = TemplateContextProcessorManager();

      manager.addProcessor(TemplateContextProcessor('proc1', (request) {
        return {'key1': 'value1'};
      }));

      manager.removeProcessor('proc1');

      final result = manager.processAll(null);

      expect(result.containsKey('key1'), isFalse);
    });

    test('should handle processor exceptions gracefully', () {
      final manager = TemplateContextProcessorManager();

      manager.addProcessor(TemplateContextProcessor('failing', (request) {
        throw Exception('Processor error');
      }));

      manager.addProcessor(TemplateContextProcessor('working', (request) {
        return {'works': true};
      }));

      final result = manager.processAll(null);

      expect(result['works'], isTrue);
      expect(result.containsKey('failing'), isFalse);
    });

    test('should merge results from multiple processors', () {
      final manager = TemplateContextProcessorManager();

      manager.addProcessor(TemplateContextProcessor('user', (request) {
        return {'user': 'john', 'role': 'admin'};
      }));

      manager.addProcessor(TemplateContextProcessor('settings', (request) {
        return {'theme': 'dark', 'lang': 'en'};
      }));

      final result = manager.processAll(null);

      expect(result, hasLength(4));
      expect(result['user'], equals('john'));
      expect(result['role'], equals('admin'));
      expect(result['theme'], equals('dark'));
      expect(result['lang'], equals('en'));
    });
  });

  group('StringLoader', () {
    test('should load template from map', () {
      final loader = StringLoader({
        'test.html': '<h1>Hello World</h1>',
        'base.html': '<html></html>',
      });

      final source = loader.loadTemplate('test.html');

      expect(source.name, equals('test.html'));
      expect(source.source, equals('<h1>Hello World</h1>'));
      expect(source.origin, equals('string:test.html'));
    });

    test('should check template existence', () {
      final loader = StringLoader({'test.html': 'content'});

      expect(loader.exists('test.html'), isTrue);
      expect(loader.exists('nonexistent.html'), isFalse);
    });

    test('should list all templates', () {
      final loader = StringLoader({
        'a.html': 'a',
        'b.html': 'b',
        'c.html': 'c',
      });

      final templates = loader.listTemplates();

      expect(templates, hasLength(3));
      expect(templates, containsAll(['a.html', 'b.html', 'c.html']));
    });

    test('should throw TemplateNotFoundException for missing template', () {
      final loader = StringLoader({});

      expect(
        () => loader.loadTemplate('missing.html'),
        throwsA(isA<TemplateNotFoundException>()),
      );
    });

    test('should add template dynamically', () {
      final loader = StringLoader({});

      loader.addTemplate('new.html', '<div>New</div>');

      expect(loader.exists('new.html'), isTrue);
      final source = loader.loadTemplate('new.html');
      expect(source.source, equals('<div>New</div>'));
    });

    test('should remove template', () {
      final loader = StringLoader({'test.html': 'content'});

      loader.removeTemplate('test.html');

      expect(loader.exists('test.html'), isFalse);
    });
  });

  group('MemoryLoader', () {
    test('should load template from memory', () {
      final loader = MemoryLoader();
      loader.addTemplate('test.html', '<p>Test</p>');

      final source = loader.loadTemplate('test.html');

      expect(source.name, equals('test.html'));
      expect(source.source, equals('<p>Test</p>'));
      expect(source.origin, equals('memory:test.html'));
    });

    test('should support custom origin', () {
      final loader = MemoryLoader();
      loader.addTemplate('test.html', 'content', origin: 'custom:origin');

      final source = loader.loadTemplate('test.html');

      expect(source.origin, equals('custom:origin'));
    });

    test('should check existence', () {
      final loader = MemoryLoader();
      loader.addTemplate('exists.html', 'content');

      expect(loader.exists('exists.html'), isTrue);
      expect(loader.exists('missing.html'), isFalse);
    });

    test('should list templates', () {
      final loader = MemoryLoader();
      loader.addTemplate('a.html', 'a');
      loader.addTemplate('b.html', 'b');

      final templates = loader.listTemplates();

      expect(templates, containsAll(['a.html', 'b.html']));
    });

    test('should remove template', () {
      final loader = MemoryLoader();
      loader.addTemplate('test.html', 'content');

      loader.removeTemplate('test.html');

      expect(loader.exists('test.html'), isFalse);
    });

    test('should clear all templates', () {
      final loader = MemoryLoader();
      loader.addTemplate('a.html', 'a');
      loader.addTemplate('b.html', 'b');

      loader.clear();

      expect(loader.listTemplates(), isEmpty);
    });

    test('should throw TemplateNotFoundException', () {
      final loader = MemoryLoader();

      expect(
        () => loader.loadTemplate('missing.html'),
        throwsA(isA<TemplateNotFoundException>()),
      );
    });
  });

  group('CachedLoader', () {
    test('should cache loaded templates', () {
      final baseLoader = StringLoader({'test.html': 'content'});
      final cachedLoader = CachedLoader(
        baseLoader,
        cacheTimeout: const Duration(seconds: 10),
      );

      final source1 = cachedLoader.loadTemplate('test.html');
      final source2 = cachedLoader.loadTemplate('test.html');

      expect(source1.source, equals(source2.source));
    });

    test('should respect cache timeout', () async {
      final baseLoader = StringLoader({'test.html': 'content'});
      final cachedLoader = CachedLoader(
        baseLoader,
        cacheTimeout: const Duration(milliseconds: 100),
      );

      cachedLoader.loadTemplate('test.html');
      await Future.delayed(const Duration(milliseconds: 150));

      cachedLoader.loadTemplate('test.html');
    });

    test('should delegate exists to base loader', () {
      final baseLoader = StringLoader({'test.html': 'content'});
      final cachedLoader = CachedLoader(baseLoader);

      expect(cachedLoader.exists('test.html'), isTrue);
      expect(cachedLoader.exists('missing.html'), isFalse);
    });

    test('should delegate listTemplates to base loader', () {
      final baseLoader = StringLoader({'a.html': 'a', 'b.html': 'b'});
      final cachedLoader = CachedLoader(baseLoader);

      final templates = cachedLoader.listTemplates();

      expect(templates, containsAll(['a.html', 'b.html']));
    });

    test('should clear cache', () {
      final baseLoader = StringLoader({'test.html': 'content'});
      final cachedLoader = CachedLoader(baseLoader);

      cachedLoader.loadTemplate('test.html');
      cachedLoader.clearCache();

      cachedLoader.loadTemplate('test.html');
    });

    test('should remove specific cached template', () {
      final baseLoader = StringLoader({'test.html': 'content'});
      final cachedLoader = CachedLoader(baseLoader);

      cachedLoader.loadTemplate('test.html');
      cachedLoader.removeCached('test.html');

      cachedLoader.loadTemplate('test.html');
    });
  });

  group('ChainLoader', () {
    test('should try loaders in order', () {
      final loader1 = StringLoader({'a.html': 'from loader1'});
      final loader2 = StringLoader({'b.html': 'from loader2'});
      final chainLoader = ChainLoader([loader1, loader2]);

      final source = chainLoader.loadTemplate('b.html');

      expect(source.source, equals('from loader2'));
    });

    test('should use first successful loader', () {
      final loader1 = StringLoader({'test.html': 'first'});
      final loader2 = StringLoader({'test.html': 'second'});
      final chainLoader = ChainLoader([loader1, loader2]);

      final source = chainLoader.loadTemplate('test.html');

      expect(source.source, equals('first'));
    });

    test('should throw if no loader has template', () {
      final loader1 = StringLoader({});
      final loader2 = StringLoader({});
      final chainLoader = ChainLoader([loader1, loader2]);

      expect(
        () => chainLoader.loadTemplate('missing.html'),
        throwsA(isA<TemplateNotFoundException>()),
      );
    });

    test('should check existence across all loaders', () {
      final loader1 = StringLoader({'a.html': 'a'});
      final loader2 = StringLoader({'b.html': 'b'});
      final chainLoader = ChainLoader([loader1, loader2]);

      expect(chainLoader.exists('a.html'), isTrue);
      expect(chainLoader.exists('b.html'), isTrue);
      expect(chainLoader.exists('c.html'), isFalse);
    });

    test('should list templates from all loaders', () {
      final loader1 = StringLoader({'a.html': 'a', 'b.html': 'b'});
      final loader2 = StringLoader({'b.html': 'b2', 'c.html': 'c'});
      final chainLoader = ChainLoader([loader1, loader2]);

      final templates = chainLoader.listTemplates();

      expect(templates, hasLength(3));
      expect(templates.toSet(), containsAll(['a.html', 'b.html', 'c.html']));
    });
  });

  group('CompoundLoader', () {
    test('should load templates with namespace prefix', () {
      final loader1 = StringLoader({'test.html': 'from app1'});
      final loader2 = StringLoader({'test.html': 'from app2'});

      final compoundLoader = CompoundLoader({
        'app1': loader1,
        'app2': loader2,
      });

      final source1 = compoundLoader.loadTemplate('app1:test.html');
      final source2 = compoundLoader.loadTemplate('app2:test.html');

      expect(source1.source, equals('from app1'));
      expect(source2.source, equals('from app2'));
    });

    test('should throw for unknown prefix', () {
      final compoundLoader = CompoundLoader({
        'app': StringLoader({'test.html': 'content'})
      });

      expect(
        () => compoundLoader.loadTemplate('unknown:test.html'),
        throwsA(isA<TemplateNotFoundException>()),
      );
    });

    test('should check existence with prefix', () {
      final compoundLoader = CompoundLoader({
        'app': StringLoader({'test.html': 'content'})
      });

      expect(compoundLoader.exists('app:test.html'), isTrue);
      expect(compoundLoader.exists('app:missing.html'), isFalse);
      expect(compoundLoader.exists('unknown:test.html'), isFalse);
    });

    test('should list templates with prefixes', () {
      final compoundLoader = CompoundLoader({
        'app1': StringLoader({'a.html': 'a', 'b.html': 'b'}),
        'app2': StringLoader({'c.html': 'c'}),
      });

      final templates = compoundLoader.listTemplates();

      expect(templates, containsAll(['app1:a.html', 'app1:b.html', 'app2:c.html']));
    });
  });

  group('Template Filters', () {
    late TemplateContext context;

    setUp(() {
      context = TemplateContext();
    });

    test('DefaultFilter should return default for null', () {
      final filter = DefaultFilter();

      expect(filter.apply(null, ['default'], context), equals('default'));
      expect(filter.apply('', ['default'], context), equals('default'));
      expect(filter.apply('value', ['default'], context), equals('value'));
      expect(filter.apply(null, [], context), equals(''));
    });

    test('LengthFilter should return length', () {
      final filter = LengthFilter();

      expect(filter.apply('hello', [], context), equals(5));
      expect(filter.apply([1, 2, 3], [], context), equals(3));
      expect(filter.apply({'a': 1, 'b': 2}, [], context), equals(2));
      expect(filter.apply(null, [], context), equals(0));
    });

    test('UpperFilter should convert to uppercase', () {
      final filter = UpperFilter();

      expect(filter.apply('hello', [], context), equals('HELLO'));
      expect(filter.apply('MiXeD', [], context), equals('MIXED'));
      expect(filter.apply(null, [], context), equals(''));
    });

    test('LowerFilter should convert to lowercase', () {
      final filter = LowerFilter();

      expect(filter.apply('HELLO', [], context), equals('hello'));
      expect(filter.apply('MiXeD', [], context), equals('mixed'));
      expect(filter.apply(null, [], context), equals(''));
    });

    test('TitleFilter should convert to title case', () {
      final filter = TitleFilter();

      expect(filter.apply('hello world', [], context), equals('Hello World'));
      expect(filter.apply('HELLO WORLD', [], context), equals('Hello World'));
      expect(filter.apply(null, [], context), equals(''));
    });

    test('DateFilter should format dates', () {
      final filter = DateFilter();
      final date = DateTime(2024, 3, 15, 14, 30, 45);

      expect(filter.apply(date, ['yyyy-MM-dd'], context), equals('2024-03-15'));
      expect(filter.apply(date, ['dd/MM/yyyy'], context), equals('15/03/2024'));
      expect(filter.apply('invalid', [], context), equals('invalid'));
    });

    test('TimeFilter should format time', () {
      final filter = TimeFilter();
      final date = DateTime(2024, 3, 15, 14, 30, 45);

      expect(filter.apply(date, ['HH:mm:ss'], context), equals('14:30:45'));
      expect(filter.apply(date, ['HH:mm'], context), equals('14:30'));
    });

    test('TruncateFilter should truncate strings', () {
      final filter = TruncateFilter();

      expect(filter.apply('hello world', ['5'], context), equals('hello...'));
      expect(filter.apply('short', ['10'], context), equals('short'));
      expect(filter.apply('hello world', [], context), contains('...'));
    });

    test('EscapeFilter should escape HTML', () {
      final filter = EscapeFilter();

      final result = filter.apply('<script>alert("XSS")</script>', [], context);

      expect(result, contains('&lt;'));
      expect(result, contains('&gt;'));
      expect(result, isNot(contains('<script>')));
    });
  });

  group('Template Exceptions', () {
    test('should create TemplateNotFoundException', () {
      final exception = TemplateNotFoundException('test.html not found');

      expect(exception.toString(), contains('test.html not found'));
    });

    test('should throw TemplateNotFoundException', () {
      expect(
        () => throw TemplateNotFoundException('error'),
        throwsA(isA<TemplateNotFoundException>()),
      );
    });
  });
}
