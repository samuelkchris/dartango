import 'package:test/test.dart';
import 'package:dartango/src/core/urls/resolver.dart';
import 'package:dartango/src/core/http/request.dart';
import 'package:dartango/src/core/http/response.dart';

void main() {
  group('URLResolver', () {
    test('should resolve simple path', () {
      final patterns = [
        path('/', (request, kwargs) => HttpResponse.ok('Home')),
        path('/about/', (request, kwargs) => HttpResponse.ok('About')),
      ];
      
      final resolver = URLResolver(urlPatterns: patterns);
      
      final match = resolver.resolve('/');
      expect(match, isNotNull);
      expect(match!.kwargs, isEmpty);
      expect(match.args, isEmpty);
    });

    test('should resolve path with parameters', () {
      final patterns = [
        path('/user/<int:id>/', (request, kwargs) => HttpResponse.ok('User ${kwargs['id']}')),
      ];
      
      final resolver = URLResolver(urlPatterns: patterns);
      
      final match = resolver.resolve('/user/123/');
      expect(match, isNotNull);
      expect(match!.kwargs['id'], equals('123'));
    });

    test('should resolve path with multiple parameters', () {
      final patterns = [
        path('/user/<int:id>/posts/<slug:slug>/', 
            (request, kwargs) => HttpResponse.ok('User ${kwargs['id']} post ${kwargs['slug']}')),
      ];
      
      final resolver = URLResolver(urlPatterns: patterns);
      
      final match = resolver.resolve('/user/123/posts/hello-world/');
      expect(match, isNotNull);
      expect(match!.kwargs['id'], equals('123'));
      expect(match.kwargs['slug'], equals('hello-world'));
    });

    test('should return null for non-matching path', () {
      final patterns = [
        path('/users/', (request, kwargs) => HttpResponse.ok('Users')),
      ];
      
      final resolver = URLResolver(urlPatterns: patterns);
      
      final match = resolver.resolve('/posts/');
      expect(match, isNull);
    });

    test('should cache resolved paths', () {
      final patterns = [
        path('/cached/', (request, kwargs) => HttpResponse.ok('Cached')),
      ];
      
      final resolver = URLResolver(urlPatterns: patterns);
      
      final match1 = resolver.resolve('/cached/');
      final match2 = resolver.resolve('/cached/');
      
      expect(match1, isNotNull);
      expect(match2, isNotNull);
      expect(identical(match1, match2), isTrue);
    });

    test('should clear cache', () {
      final patterns = [
        path('/cached/', (request, kwargs) => HttpResponse.ok('Cached')),
      ];
      
      final resolver = URLResolver(urlPatterns: patterns);
      
      final match1 = resolver.resolve('/cached/');
      resolver.clearCache();
      final match2 = resolver.resolve('/cached/');
      
      expect(match1, isNotNull);
      expect(match2, isNotNull);
      expect(identical(match1, match2), isFalse);
    });

    test('should reverse simple URL', () {
      final patterns = [
        path('/users/', (request, kwargs) => HttpResponse.ok('Users'), name: 'users'),
      ];
      
      final resolver = URLResolver(urlPatterns: patterns);
      
      final url = resolver.reverse('users');
      expect(url, equals('/users/'));
    });

    test('should reverse URL with parameters', () {
      final patterns = [
        path('/user/<int:id>/', (request, kwargs) => HttpResponse.ok('User'), name: 'user-detail'),
      ];
      
      final resolver = URLResolver(urlPatterns: patterns);
      
      final url = resolver.reverse('user-detail', kwargs: {'id': '123'});
      expect(url, equals('/user/123/'));
    });

    test('should return null for non-existent view name', () {
      final patterns = [
        path('/users/', (request, kwargs) => HttpResponse.ok('Users'), name: 'users'),
      ];
      
      final resolver = URLResolver(urlPatterns: patterns);
      
      final url = resolver.reverse('non-existent');
      expect(url, isNull);
    });
  });

  group('Route', () {
    test('should compile simple pattern', () {
      final route = Route(
        pattern: '/users/',
        view: (request, kwargs) => HttpResponse.ok('Users'),
      );
      
      expect(route.pattern, equals('/users/'));
      expect(route.name, isNull);
    });

    test('should compile pattern with parameters', () {
      final route = Route(
        pattern: '/user/<int:id>/',
        view: (request, kwargs) => HttpResponse.ok('User'),
        name: 'user-detail',
      );
      
      expect(route.pattern, equals('/user/<int:id>/'));
      expect(route.name, equals('user-detail'));
    });

    test('should resolve matching path', () {
      final route = Route(
        pattern: '/user/<int:id>/',
        view: (request, kwargs) => HttpResponse.ok('User'),
        name: 'user-detail',
      );
      
      final match = route.resolve('/user/123/');
      expect(match, isNotNull);
      expect(match!.kwargs['id'], equals('123'));
      expect(match.urlName, equals('user-detail'));
    });

    test('should not resolve non-matching path', () {
      final route = Route(
        pattern: '/user/<int:id>/',
        view: (request, kwargs) => HttpResponse.ok('User'),
      );
      
      final match = route.resolve('/users/');
      expect(match, isNull);
    });

    test('should reverse with kwargs', () {
      final route = Route(
        pattern: '/user/<int:id>/',
        view: (request, kwargs) => HttpResponse.ok('User'),
        name: 'user-detail',
      );
      
      final url = route.reverse('user-detail', kwargs: {'id': '123'});
      expect(url, equals('/user/123/'));
    });

    test('should return null for reverse with missing kwargs', () {
      final route = Route(
        pattern: '/user/<int:id>/',
        view: (request, kwargs) => HttpResponse.ok('User'),
        name: 'user-detail',
      );
      
      final url = route.reverse('user-detail');
      expect(url, isNull);
    });

    test('should return null for reverse with wrong name', () {
      final route = Route(
        pattern: '/user/<int:id>/',
        view: (request, kwargs) => HttpResponse.ok('User'),
        name: 'user-detail',
      );
      
      final url = route.reverse('wrong-name', kwargs: {'id': '123'});
      expect(url, isNull);
    });
  });

  group('Include', () {
    test('should resolve path with prefix', () {
      final subPatterns = [
        path('list/', (request, kwargs) => HttpResponse.ok('User List')),
        path('<int:id>/', (request, kwargs) => HttpResponse.ok('User Detail')),
      ];
      
      final subResolver = URLResolver(urlPatterns: subPatterns);
      final includePattern = Include(prefix: '/users/', resolver: subResolver);
      
      final match = includePattern.resolve('/users/list/');
      expect(match, isNotNull);
      expect(match!.kwargs, isEmpty);
    });

    test('should resolve path with prefix and parameters', () {
      final subPatterns = [
        path('<int:id>/', (request, kwargs) => HttpResponse.ok('User Detail')),
      ];
      
      final subResolver = URLResolver(urlPatterns: subPatterns);
      final includePattern = Include(prefix: '/users/', resolver: subResolver);
      
      final match = includePattern.resolve('/users/123/');
      expect(match, isNotNull);
      expect(match!.kwargs['id'], equals('123'));
    });

    test('should not resolve path without prefix', () {
      final subPatterns = [
        path('list/', (request, kwargs) => HttpResponse.ok('User List')),
      ];
      
      final subResolver = URLResolver(urlPatterns: subPatterns);
      final includePattern = Include(prefix: '/users/', resolver: subResolver);
      
      final match = includePattern.resolve('/posts/list/');
      expect(match, isNull);
    });

    test('should reverse included URL', () {
      final subPatterns = [
        path('list/', (request, kwargs) => HttpResponse.ok('User List'), name: 'user-list'),
      ];
      
      final subResolver = URLResolver(urlPatterns: subPatterns);
      final includePattern = Include(prefix: '/users/', resolver: subResolver);
      
      final url = includePattern.reverse('user-list');
      expect(url, equals('/users/list/'));
    });
  });

  group('URLConfiguration', () {
    test('should resolve path through configuration', () {
      final patterns = [
        path('/home/', (request, kwargs) => HttpResponse.ok('Home')),
        path('/about/', (request, kwargs) => HttpResponse.ok('About')),
      ];
      
      final config = URLConfiguration(patterns);
      
      final match = config.resolve('/home/');
      expect(match, isNotNull);
    });

    test('should reverse URL through configuration', () {
      final patterns = [
        path('/home/', (request, kwargs) => HttpResponse.ok('Home'), name: 'home'),
      ];
      
      final config = URLConfiguration(patterns);
      
      final url = config.reverse('home');
      expect(url, equals('/home/'));
    });

    test('should clear cache through configuration', () {
      final patterns = [
        path('/home/', (request, kwargs) => HttpResponse.ok('Home')),
      ];
      
      final config = URLConfiguration(patterns);
      
      final match1 = config.resolve('/home/');
      config.clearCache();
      final match2 = config.resolve('/home/');
      
      expect(match1, isNotNull);
      expect(match2, isNotNull);
      expect(identical(match1, match2), isFalse);
    });
  });

  group('Helper Functions', () {
    test('path helper should create Route', () {
      final route = path('/test/', (request, kwargs) => HttpResponse.ok('Test'));
      
      expect(route, isA<Route>());
      expect(route.pattern, equals('/test/'));
    });

    test('re_path helper should create Route', () {
      final route = re_path(r'/test/(\d+)/', (request, kwargs) => HttpResponse.ok('Test'));
      
      expect(route, isA<Route>());
      expect(route.pattern, equals(r'/test/(\d+)/'));
    });

    test('include helper should create Include', () {
      final subResolver = URLResolver(urlPatterns: []);
      final includePattern = include('/api/', subResolver);
      
      expect(includePattern, isA<Include>());
      expect((includePattern as Include).prefix, equals('/api/'));
    });
  });

  group('ResolverMatch', () {
    test('should create resolver match with all properties', () {
      final func = (HttpRequest request, Map<String, String> kwargs) => HttpResponse.ok('Test');
      final route = Route(pattern: '/test/', view: func, name: 'test');
      
      final match = ResolverMatch(
        func: func,
        args: ['arg1'],
        kwargs: {'key': 'value'},
        urlName: 'test',
        appName: 'myapp',
        namespace: 'api',
        namespaces: ['api', 'v1'],
        route: route,
      );
      
      expect(match.func, equals(func));
      expect(match.args, equals(['arg1']));
      expect(match.kwargs, equals({'key': 'value'}));
      expect(match.urlName, equals('test'));
      expect(match.appName, equals('myapp'));
      expect(match.namespace, equals('api'));
      expect(match.namespaces, equals(['api', 'v1']));
      expect(match.route, equals(route));
    });

    test('should provide string representation', () {
      final func = (HttpRequest request, Map<String, String> kwargs) => HttpResponse.ok('Test');
      final route = Route(pattern: '/test/', view: func, name: 'test');
      
      final match = ResolverMatch(
        func: func,
        args: [],
        kwargs: {},
        urlName: 'test',
        appName: 'myapp',
        namespace: 'api',
        namespaces: ['api'],
        route: route,
      );
      
      final str = match.toString();
      expect(str, contains('ResolverMatch'));
      expect(str, contains('url_name: test'));
      expect(str, contains('app_name: myapp'));
      expect(str, contains('namespace: api'));
    });
  });
}