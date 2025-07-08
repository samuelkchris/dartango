# Dartango

A full-featured, production-ready web framework for Dart inspired by Django's design philosophy and comprehensive feature set.

## Features

### Core Framework
- **MTV Architecture**: Model-Template-View pattern with clear separation of concerns
- **ORM with Active Record**: Full-featured database abstraction with migrations
- **Request/Response Pipeline**: Middleware system with pre/post processing
- **URL Routing**: Regex-based routing with named patterns and reversing
- **Template Engine**: Django-compatible template syntax with inheritance
- **Static File Handling**: Development and production static file serving

### Database Layer
- **Multiple Database Backends**: PostgreSQL, MySQL, SQLite support
- **Connection Pooling**: Efficient database connection management
- **Query Builder**: Chainable, lazy-evaluated queries with prefetching
- **Migrations**: Automatic schema migrations with rollback support
- **Raw SQL Support**: Execute raw queries when needed
- **Database Routing**: Route models to different databases

### Models & ORM
- **Field Types**: All Django field types including JSONField, ArrayField
- **Model Inheritance**: Abstract, proxy, and multi-table inheritance
- **Model Meta Options**: Ordering, indexes, constraints, permissions
- **Model Managers**: Custom querysets and manager methods
- **Model Signals**: Pre/post save, delete, m2m changed signals
- **Model Validation**: Field and model-level validation

### Admin Interface
- **Auto-generated Admin**: Flutter-based responsive admin dashboard
- **Model Registration**: Automatic CRUD interface generation
- **Customization**: Custom forms, fieldsets, inlines, actions
- **Permissions**: Object-level and model-level permissions
- **Search & Filtering**: Full-text search and filter sidebar
- **Bulk Actions**: Delete, update multiple objects at once

### Forms Framework
- **Form Classes**: Declarative form definitions with validation
- **Model Forms**: Automatic form generation from models
- **Form Fields**: All HTML5 input types with Dart validation
- **Formsets**: Multiple form instances with add/remove
- **File Uploads**: Secure file and image upload handling
- **CSRF Protection**: Automatic CSRF token generation/validation

### Authentication & Authorization
- **User Model**: Extensible user model with permissions
- **Authentication Backends**: Multiple authentication methods
- **Password Management**: Bcrypt hashing with salt
- **Session Framework**: Database and cache-backed sessions
- **Permission System**: Model and object-level permissions
- **Groups & Roles**: Role-based access control

### Views & Templates
- **Function-Based Views**: Simple request handlers
- **Class-Based Views**: Reusable generic views (ListView, DetailView, etc.)
- **Template Language**: Variables, filters, tags, inheritance
- **Context Processors**: Global template context
- **Template Loaders**: Filesystem and package template loading
- **Auto-escaping**: XSS protection by default

### Caching
- **Cache Backends**: Memory, Redis, Memcached support
- **Cache Middleware**: Full-page caching
- **Template Fragment Caching**: Cache expensive template parts
- **Low-level Cache API**: Cache arbitrary objects
- **Cache Invalidation**: Tag-based cache invalidation

### Security
- **HTTPS Support**: Secure cookies, HSTS headers
- **Security Headers**: XSS, clickjacking protection
- **SQL Injection Protection**: Parameterized queries
- **Rate Limiting**: Prevent brute force attacks
- **Content Security Policy**: CSP header support

### Development Tools
- **CLI Management**: Project and app scaffolding
- **Development Server**: Auto-reload development server
- **Debug Toolbar**: SQL queries, templates, cache usage
- **Testing Framework**: Unit and integration testing utilities
- **Fixtures**: Data loading for tests and development
- **Shell**: Interactive Dart shell with framework loaded

### Production Features
- **ASGI Server**: Production-ready async server
- **Static File Collection**: Collect static files for CDN
- **Database Connection Pooling**: Efficient connection reuse
- **Logging**: Configurable logging with multiple handlers
- **Error Pages**: Custom 404, 500 error pages
- **Health Checks**: Database and cache health endpoints

## Installation

```bash
dart pub global activate melos
git clone https://github.com/samuelkchris/dartango.git
cd dartango
melos bootstrap
```

## Quick Start

```bash
# Create a new project
dartango create project mysite

# Create an app
cd mysite
dartango create app blog

# Run migrations
dartango migrate

# Create superuser
dartango createsuperuser

# Run development server
dartango runserver
```

## Project Structure

```
myproject/
├── myproject/
│   ├── settings.dart      # Project settings
│   ├── urls.dart          # URL configuration
│   ├── wsgi.dart          # WSGI application
│   └── asgi.dart          # ASGI application
├── apps/
│   └── myapp/
│       ├── models.dart    # Database models
│       ├── views.dart     # View functions/classes
│       ├── urls.dart      # App URL patterns
│       ├── admin.dart     # Admin configuration
│       ├── forms.dart     # Form definitions
│       └── migrations/    # Database migrations
├── templates/             # HTML templates
├── static/               # Static files
├── media/                # User uploads
└── pubspec.yaml          # Dependencies

```

## Example Model

```dart
@model
class Article extends Model {
  @CharField(maxLength: 200)
  late String title;
  
  @SlugField(uniqueWith: ['publishDate'])
  late String slug;
  
  @TextField()
  late String content;
  
  @ForeignKey('auth.User', onDelete: OnDelete.cascade)
  late User author;
  
  @DateTimeField(defaultNow: true)
  late DateTime publishDate;
  
  @ManyToManyField('Tag', related: 'articles')
  late QuerySet<Tag> tags;
  
  static final objects = Manager<Article>();
  
  String get absoluteUrl => '/articles/$slug/';
  
  @override
  Meta get meta => Meta(
    ordering: ['-publishDate'],
    indexes: [
      Index(fields: ['slug', 'publishDate']),
    ],
    permissions: [
      Permission('can_publish', 'Can publish articles'),
    ],
  );
}
```

## Example View

```dart
@requireLogin
class ArticleListView extends ListView<Article> {
  @override
  String get templateName => 'blog/article_list.html';
  
  @override
  QuerySet<Article> get queryset => Article.objects
      .filter(status: 'published')
      .selectRelated(['author'])
      .prefetchRelated(['tags']);
  
  @override
  int get paginateBy => 10;
}

@route('/articles/<slug:slug>/')
Future<Response> articleDetail(Request request, String slug) async {
  final article = await Article.objects.getOr404(slug: slug);
  return render(request, 'blog/article_detail.html', {
    'article': article,
    'related': await article.tags.similar(),
  });
}
```

## Admin Configuration

```dart
@admin.register(Article)
class ArticleAdmin extends ModelAdmin<Article> {
  @override
  List<String> get listDisplay => ['title', 'author', 'publishDate', 'status'];
  
  @override
  List<String> get listFilter => ['status', 'publishDate', 'author'];
  
  @override
  List<String> get searchFields => ['title', 'content'];
  
  @override
  Map<String, List<String>> get fieldsets => {
    'Content': ['title', 'slug', 'content'],
    'Publishing': ['author', 'publishDate', 'status'],
    'Metadata': ['tags'],
  };
  
  @override
  List<InlineAdmin> get inlines => [CommentInline()];
  
  @override
  List<AdminAction> get actions => [makePublished, makeDraft];
}
```

## Template Example

```django
{% extends "base.html" %}
{% load blog_tags %}

{% block title %}{{ article.title }} - {{ block.super }}{% endblock %}

{% block content %}
<article>
  <h1>{{ article.title }}</h1>
  <p class="meta">
    By {{ article.author.getFullName }} on {{ article.publishDate|date:"F j, Y" }}
  </p>
  
  {{ article.content|markdown|safe }}
  
  <div class="tags">
    {% for tag in article.tags.all %}
      <a href="{% url 'tag_detail' tag.slug %}">#{{ tag.name }}</a>
    {% endfor %}
  </div>
</article>

{% include "blog/includes/comments.html" with comments=article.comments.all %}
{% endblock %}

{% block sidebar %}
  {% related_articles article as related %}
  <h3>Related Articles</h3>
  <ul>
  {% for item in related %}
    <li><a href="{{ item.getAbsoluteUrl }}">{{ item.title }}</a></li>
  {% endfor %}
  </ul>
{% endblock %}
```

## CLI Commands

```bash
# Project management
dartango create project <name>
dartango create app <name>

# Database
dartango makemigrations
dartango migrate
dartango dbshell

# Development
dartango runserver [port]
dartango shell
dartango test

# Static files
dartango collectstatic

# Cache
dartango clearcache

# Users
dartango createsuperuser
dartango changepassword <username>
```

## Configuration

```dart
// settings.dart
final settings = Settings(
  secretKey: env['SECRET_KEY'],
  debug: env['DEBUG'] == 'true',
  allowedHosts: ['example.com'],
  
  databases: {
    'default': {
      'engine': 'postgresql',
      'name': 'myproject',
      'user': 'postgres',
      'password': env['DB_PASSWORD'],
      'host': 'localhost',
      'port': 5432,
    }
  },
  
  installedApps: [
    'dartango.contrib.admin',
    'dartango.contrib.auth',
    'dartango.contrib.contenttypes',
    'dartango.contrib.sessions',
    'dartango.contrib.messages',
    'dartango.contrib.staticfiles',
    'blog',
  ],
  
  middleware: [
    'dartango.middleware.security.SecurityMiddleware',
    'dartango.contrib.sessions.middleware.SessionMiddleware',
    'dartango.middleware.common.CommonMiddleware',
    'dartango.middleware.csrf.CsrfViewMiddleware',
    'dartango.contrib.auth.middleware.AuthenticationMiddleware',
    'dartango.contrib.messages.middleware.MessageMiddleware',
  ],
  
  templates: [
    {
      'backend': 'dartango.template.backends.dartango.DartangoTemplates',
      'dirs': ['templates'],
      'appDirs': true,
      'options': {
        'contextProcessors': [
          'dartango.template.contextProcessors.debug',
          'dartango.template.contextProcessors.request',
          'dartango.contrib.auth.contextProcessors.auth',
          'dartango.contrib.messages.contextProcessors.messages',
        ],
      },
    },
  ],
);
```

## Documentation

Full documentation available at [https://dartango.dev](https://dartango.dev)

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## License

BSD 3-Clause License