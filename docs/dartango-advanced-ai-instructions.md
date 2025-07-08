# Dartango Advanced Implementation Instructions

## Critical Requirements

**NO COMMENTS, NO TODOs, NO FIXME, NO PLACEHOLDER IMPLEMENTATIONS**

Every line of code must be production-ready, fully implemented, and feature-complete. Emulate Django's maturity and comprehensive feature set. No shortcuts, no "basic" implementations, no placeholders. If Django has it, Dartango must have it.

## Architecture Standards

### Core Principles
- Thread-safe by default using isolates where appropriate
- Async/await throughout with proper error handling
- Immutable request/response objects
- Lazy evaluation for all querysets
- Connection pooling for all external resources
- Zero-copy operations where possible
- Proper memory management with weak references where needed

### Performance Requirements
- Sub-millisecond routing resolution
- Database query optimization with explain plans
- Prepared statement caching
- HTTP/2 and WebSocket support
- Response compression by default
- ETag and Last-Modified header support
- Streaming responses for large data

## Component Specifications

### 1. HTTP Server Layer

Implement full ASGI/WSGI compatibility with:
- HTTP/1.1, HTTP/2, WebSocket protocols
- Request pipelining
- Keep-alive connection management
- Chunked transfer encoding
- Multipart form parsing with streaming
- Cookie parsing with SameSite support
- Request body size limits
- Timeout handling at all levels
- Graceful shutdown with connection draining

### 2. Request/Response Objects

Request object must include:
- Lazy body parsing
- File upload streaming to temp files
- Full header access with case-insensitive lookup
- Query parameter parsing with list support
- Cookie jar with signing/encryption
- Session lazy loading
- User authentication state
- WSGI/ASGI environ compatibility
- Request middleware state storage

Response object must support:
- Streaming responses
- File responses with range support
- JSON responses with custom encoders
- Template responses with lazy rendering
- Redirect shortcuts with permanent option
- Cookie setting with all attributes
- Cache control headers
- Content negotiation
- Conditional responses (304 Not Modified)

### 3. URL Routing System

Advanced routing with:
- Regex patterns with named groups
- Path converters (int, slug, uuid, path)
- Route includes with namespacing
- Reverse URL resolution with kwargs
- URL namespaces with app_name
- Dynamic route registration
- Route middleware attachment
- Subdomain routing support
- Method-based routing (GET, POST, etc.)
- Route caching for performance

### 4. Database Layer (ORM)

#### Connection Management
- Connection pooling with size limits
- Read/write splitting for replicas
- Automatic reconnection on failure
- Transaction isolation levels
- Savepoint support
- Database routing by model
- Multi-database joins via subqueries
- Connection health checks

#### Model Definition
- All Django field types with validators
- Field options (null, blank, default, choices)
- Model inheritance (abstract, proxy, concrete)
- Custom model managers
- Model meta options (ordering, indexes, constraints)
- Model permissions
- Natural keys for serialization
- Model mixins and abstract models
- Swappable models (like AUTH_USER_MODEL)

#### Query API
Full Django QuerySet API:
- filter(), exclude(), annotate(), aggregate()
- select_related(), prefetch_related()
- only(), defer()
- values(), values_list()
- distinct(), order_by(), reverse()
- union(), intersection(), difference()
- exists(), count(), first(), last()
- create(), get_or_create(), update_or_create()
- bulk_create(), bulk_update()
- delete(), update()
- raw() for raw SQL
- extra() for complex queries
- Subqueries and OuterRef
- Window functions
- Database functions (Coalesce, Cast, etc.)
- Q objects for complex lookups
- F expressions for field references

#### Field Lookups
All Django lookups:
- exact, iexact, contains, icontains
- in, gt, gte, lt, lte
- startswith, istartswith, endswith, iendswith
- range, date, year, month, day, week, week_day
- quarter, hour, minute, second
- isnull, regex, iregex

#### Migrations
- Auto-detection of model changes
- Migration squashing
- Data migrations
- Reversible migrations
- Migration dependencies
- Custom migration operations
- Schema editor abstraction
- Database introspection
- Fake migrations
- Migration rollback

### 5. Forms Framework

#### Form Fields
All HTML5 input types with:
- Field validation (required, min_length, max_length, etc.)
- Custom validators
- Field cleaning methods
- Error message customization
- Help text and labels
- Initial values and placeholders
- Widget customization
- Localized input formats

#### Form Features
- Form validation with field dependencies
- Formsets with add/delete
- Model forms with field selection
- Form prefixes for multiple forms
- File upload handling
- Multi-value fields
- Hidden fields with tampering protection
- Form media (CSS/JS) collection
- Bound and unbound forms

### 6. Template Engine

#### Syntax Support
- Variable resolution with dot notation
- Filters with arguments
- Tags with complex parsing
- Template inheritance with blocks
- Include with context isolation
- Custom filters and tags
- Auto-escaping with safe marking
- Spaceless tag
- Comment syntax

#### Built-in Tags
All Django template tags:
- for, if, elif, else
- block, extends, include
- load, with, url
- csrf_token, cycle, firstof
- lorem, now, regroup
- spaceless, templatetag
- widthratio, verbatim

#### Built-in Filters
All Django filters:
- add, addslashes, capfirst, center
- cut, date, default, default_if_none
- dictsort, dictsortreversed, divisibleby
- escape, escapejs, filesizeformat
- first, floatformat, force_escape
- get_digit, iriencode, join, last
- length, length_is, linebreaks
- linebreaksbr, linenumbers, ljust
- lower, make_list, phone2numeric
- pluralize, pprint, random, rjust
- safe, safeseq, slice, slugify
- stringformat, striptags, time
- timesince, timeuntil, title
- truncatechars, truncatechars_html
- truncatewords, truncatewords_html
- unordered_list, upper, urlencode
- urlize, urlizetrunc, wordcount
- wordwrap, yesno

### 7. Admin Interface

#### Admin Site
- Auto-discovery of admin modules
- Multiple admin sites
- Custom admin URLs
- Admin index page customization
- App index pages
- Recent actions tracking
- Admin permissions
- Admin decorators

#### ModelAdmin Features
- List display with sorting
- List filters with custom filters
- Search with icontains lookup
- Date hierarchy navigation
- Actions with confirmation
- Fieldsets with collapsing
- Readonly fields
- Inline model editing
- Raw ID fields
- Autocomplete fields
- Prepopulated fields
- Custom forms and formsets
- Custom templates per model
- Export actions (CSV, Excel)
- Bulk editing
- Change history tracking

#### Flutter Admin Dashboard
- Real-time updates via WebSocket
- Responsive Material Design
- Touch-optimized interface
- Offline capability with sync
- Dashboard widgets
- Charts and analytics
- Quick actions
- Global search
- Notifications
- User preferences
- Theme customization
- Export functionality
- Print views

### 8. Authentication System

#### User Model
- AbstractBaseUser for customization
- PermissionsMixin for permissions
- Username/email authentication
- Password validation pipeline
- Password history
- Account lockout on failures
- Two-factor authentication ready
- Social authentication ready

#### Authentication Backends
- ModelBackend with permissions
- RemoteUserBackend
- Custom backend support
- Backend chaining
- Cached authentication

#### Authorization
- Model permissions (add, change, delete, view)
- Object permissions with backend
- Permission caching
- Group permissions
- Permission checking in templates
- Superuser concept
- Staff user concept
- Custom permissions

### 9. Session Framework

#### Session Backends
- Database sessions
- Cache-based sessions
- File-based sessions
- Cookie-based sessions (signed)
- Hybrid cache/database sessions

#### Session Features
- Session key rotation
- Session expiry (age, browser close)
- Session data serialization
- Concurrent session handling
- Session cleanup command
- Flash messages via sessions

### 10. Cache Framework

#### Cache Backends
- Memory cache (in-process)
- Redis cache with clustering
- Memcached with consistent hashing
- Database cache
- File-based cache
- Dummy cache for development

#### Cache Features
- Key versioning
- Cache key prefixing
- Timeout support
- Atomic operations (incr, decr)
- Cache warming
- Dogpile effect prevention
- Tagged cache invalidation
- Compression support

#### Cache Usage
- Low-level cache API
- Template fragment caching
- Per-view caching
- Queryset caching
- Conditional caching
- Vary headers support

### 11. Static Files

#### Development
- Static file serving
- Static file finders
- App directories finder
- Filesystem finder
- Auto-reloading on change

#### Production
- Static file collection
- Storage backends (S3, CDN)
- Manifest static files storage
- Cache busting with hashes
- Compression (gzip, brotli)
- Post-processing pipeline

### 12. File Storage

#### Storage Backends
- FileSystemStorage
- S3Storage
- GoogleCloudStorage
- AzureStorage
- FTPStorage
- Custom storage backends

#### Storage Features
- File upload handling
- File name sanitization
- Duplicate handling
- File size validation
- File type validation
- Image processing
- Thumbnail generation
- Temporary file handling

### 13. Email

#### Email Backends
- SMTP backend
- Console backend
- File backend
- In-memory backend
- Custom backends

#### Email Features
- HTML and text emails
- Attachments and inline images
- Mass mailing with connections reuse
- Email templates
- Bounce handling ready
- DKIM signing ready

### 14. Signals

#### Built-in Signals
- pre_save, post_save
- pre_delete, post_delete
- m2m_changed
- request_started, request_finished
- got_request_exception
- setting_changed
- connection_created

#### Signal Features
- Sender filtering
- Weak references by default
- Dispatch UID for uniqueness
- Decorator syntax
- Async signal support

### 15. Middleware

#### Built-in Middleware
- SecurityMiddleware (HTTPS, HSTS, etc.)
- SessionMiddleware
- CommonMiddleware (URL normalization)
- CsrfViewMiddleware
- AuthenticationMiddleware
- MessageMiddleware
- XFrameOptionsMiddleware
- ConditionalGetMiddleware
- GZipMiddleware
- LocaleMiddleware

#### Middleware Features
- Process request/response
- Process view/exception
- Process template response
- Async middleware support
- Middleware ordering
- Conditional middleware

### 16. Management Commands

#### Built-in Commands
All Django management commands including:
- createproject, createapp
- runserver with auto-reload
- makemigrations, migrate
- createsuperuser, changepassword
- collectstatic
- test with coverage
- shell with IPython support
- dbshell
- dumpdata, loaddata
- flush, sqlflush
- showmigrations
- check for system checks
- compilemessages, makemessages

#### Command Framework
- BaseCommand class
- Arguments and options parsing
- Output styling and colors
- Progress bars
- Verbosity levels
- Dry-run support
- Transaction handling

### 17. Testing

#### Test Framework
- TestCase with database transactions
- TransactionTestCase
- LiveServerTestCase
- Client for request testing
- Async test support
- Test decorators (skip, override_settings)
- Fixtures and factories
- Mock request/response
- Email testing
- Signal testing

#### Assertions
All Django assertions:
- assertContains, assertNotContains
- assertFormError, assertFormsetError  
- assertRedirects
- assertTemplateUsed, assertTemplateNotUsed
- assertRaisesMessage
- assertFieldOutput
- assertHTMLEqual, assertHTMLNotEqual
- assertInHTML
- assertJSONEqual, assertJSONNotEqual
- assertXMLEqual, assertXMLNotEqual
- assertQuerysetEqual
- assertNumQueries

### 18. Security

#### Security Features
- CSRF protection with tokens
- XSS prevention via auto-escaping
- SQL injection prevention
- Clickjacking protection
- SSL/HTTPS enforcement
- Secure cookies
- Session security
- Host header validation
- Content type validation
- File upload security
- Rate limiting
- Password strength validation

#### Security Headers
- X-Content-Type-Options
- X-Frame-Options
- X-XSS-Protection
- Strict-Transport-Security
- Content-Security-Policy
- Referrer-Policy
- Feature-Policy
- Clear-Site-Data

### 19. Internationalization

#### i18n Features
- Message translation
- Lazy translation
- Pluralization
- Context markers
- Language detection
- Language switching
- Locale middleware
- JavaScript translations
- Format localization
- Time zone support

#### l10n Features
- Number formatting
- Date/time formatting
- Currency formatting
- Locale-aware forms
- RTL language support

### 20. Logging

#### Logging Configuration
- Logger hierarchy
- Handler types (file, email, syslog)
- Formatter customization
- Filter support
- Log levels
- Logger propagation
- Performance logging
- Security logging
- Audit logging

### 21. System Checks

#### Check Categories
- Model checks
- Field checks
- Database checks
- URL configuration checks
- Template checks
- Cache configuration checks
- Security checks
- Compatibility checks

### 22. Content Types

#### Content Type Framework
- Generic relations
- Generic foreign keys
- Model permissions via content types
- Admin integration
- Natural keys

### 23. Syndication

#### Feed Framework
- RSS feeds
- Atom feeds
- Custom feed types
- Enclosures
- GeoRSS
- iTunes podcast feeds

### 24. Sitemaps

#### Sitemap Framework
- Sitemap generation
- Sitemap index
- Image sitemaps
- Video sitemaps
- News sitemaps
- Ping search engines

### 25. Messages

#### Message Framework
- Message levels (debug, info, success, warning, error)
- Message tags
- Extra tags
- Persistent messages
- Message expiry

## Implementation Standards

### Code Quality
- Type hints on all functions
- Null safety throughout
- Exhaustive error handling
- Resource cleanup with finally
- Proper async/await usage
- No blocking I/O in async code
- Memory leak prevention
- Race condition prevention

### Performance
- O(1) lookups where possible
- Query optimization
- Index usage
- Batch operations
- Lazy loading
- Streaming where appropriate
- Connection pooling
- Result caching

### Error Handling
- Specific exception types
- Error context preservation
- User-friendly error messages
- Debug mode error pages
- Production error logging
- Error recovery strategies
- Graceful degradation

### Testing
- 100% code coverage target
- Unit tests for all components
- Integration tests for workflows
- Performance benchmarks
- Security tests
- Stress tests
- Compatibility tests

### Documentation
- Docstrings for all public APIs
- Type hints as documentation
- Example code that works
- Migration guides
- Performance tips
- Security best practices
- Deployment guides

## Quality Metrics

Every component must meet:
- Django feature parity
- Sub-second response times
- Zero security vulnerabilities
- Memory leak free
- Thread-safe operations
- Backward compatibility
- Database agnostic where possible
- Platform independent code

## Prohibited Patterns

Never use:
- Placeholder implementations
- NotImplementedError
- Pass statements in production code
- TODO/FIXME/XXX comments
- Print debugging
- Hardcoded values
- Global mutable state
- Synchronous I/O in async contexts
- Unsafe type casts
- Ignored exceptions