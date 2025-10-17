# Dartango Framework SDK

> Django for Dart developers - A comprehensive web framework with Flutter admin interface

## 🚀 Quick Installation

### macOS/Linux
```bash
curl -fsSL https://raw.githubusercontent.com/dartango/framework/main/install.sh | bash
```

### Windows
```powershell
# Download and run install.bat
iwr -Uri "https://raw.githubusercontent.com/dartango/framework/main/install.bat" -OutFile install.bat
./install.bat
```

### Manual Installation
```bash
git clone https://github.com/dartango/framework.git
cd framework
chmod +x install.sh
./install.sh
```

## ✅ Prerequisites

- **Dart SDK** (≥3.0.0) - [Install Dart](https://dart.dev/get-dart)
- **Flutter** (≥3.10.0) - [Install Flutter](https://flutter.dev/docs/get-started/install) *(for admin interface)*

## 📦 What Gets Installed

The Dartango SDK installs to `~/.dartango/` and includes:

```
~/.dartango/
├── packages/
│   ├── dartango/           # Core framework
│   ├── dartango_cli/       # Command line tools
│   ├── dartango_admin/     # Flutter admin interface
│   └── dartango_shared/    # Shared utilities
├── examples/               # Example projects
├── docs/                   # Documentation
└── bin/dartango           # Global CLI
```

## 🎯 Quick Start

### 1. Verify Installation
```bash
dartango --version
```

### 2. Create Your First Project
```bash
dartango create my_blog
cd my_blog
```

### 3. Start Development
```bash
# Terminal 1: Backend server
dartango serve

# Terminal 2: Flutter admin interface  
cd admin
flutter run -d chrome
```

### 4. Access Your App
- **Backend API**: http://localhost:8000
- **Flutter Admin**: http://localhost:8080 (or Chrome debug port)
- **Default Login**: admin / admin123

## 🛠️ Available Commands

```bash
dartango create <project>   # Create new project
dartango serve             # Start development server
dartango startapp <app>    # Create new app within project
dartango generate <type>   # Generate boilerplate code
dartango build            # Build for production
dartango test             # Run tests
dartango doctor           # Check system dependencies
```

## 🏗️ Project Structure

When you create a new project, you get:

```
my_blog/
├── bin/
│   └── main.dart          # Server entry point
├── lib/
│   ├── app.dart          # Main application
│   ├── models/           # Data models
│   ├── views/            # View controllers
│   ├── admin/            # Admin configurations
│   └── urls.dart         # URL routing
├── admin/                # Flutter admin interface
│   ├── lib/
│   ├── web/
│   └── pubspec.yaml
├── templates/            # HTML templates
└── pubspec.yaml         # Dependencies
```

## 🎨 Features

### Backend (Dart)
- **Django-style ORM** with Model classes
- **URL routing** with pattern matching
- **Admin interface** with automatic CRUD
- **Authentication** and permissions
- **Template system** with inheritance
- **Database migrations**
- **REST API** endpoints
- **WebSocket** support
- **Middleware** pipeline
- **Forms** and validation

### Frontend (Flutter)
- **Material Design** admin interface
- **Responsive** layout for all devices
- **Real-time updates** via WebSocket
- **CRUD operations** for all models
- **Dashboard** with analytics
- **Authentication** flow
- **Data visualization** with charts
- **Export functionality**

## 📚 Examples

### Creating a Blog Model
```dart
// lib/models/blog_post.dart
import 'package:dartango/dartango.dart';

class BlogPost extends Model {
  BlogPost();
  
  @override
  ModelMeta get meta => const ModelMeta(
    tableName: 'blog_posts',
    appLabel: 'blog',
  );
  
  String get title => getField<String>('title') ?? '';
  set title(String value) => setField('title', value);
  
  String get content => getField<String>('content') ?? '';
  set content(String value) => setField('content', value);
  
  bool get published => getField<bool>('published') ?? false;
  set published(bool value) => setField('published', value);
}
```

### Registering with Admin
```dart
// lib/admin/blog_post_admin.dart
import 'package:dartango/dartango.dart';
import '../models/blog_post.dart';

class BlogPostAdmin extends ModelAdmin<BlogPost> {
  BlogPostAdmin({required super.adminSite}) : super(modelType: BlogPost);
  
  @override
  List<String> get listDisplay => ['title', 'published', 'createdAt'];
  
  @override
  List<String> get searchFields => ['title', 'content'];
}
```

### URL Routing
```dart
// lib/urls.dart
import 'package:dartango/dartango.dart';
import 'views/blog_view.dart';

final urlPatterns = [
  path('/', HomeView.asView(), name: 'home'),
  path('/blog/', BlogView.asView(), name: 'blog'),
];
```

## 🔧 Configuration

### Database Setup
```dart
// lib/app.dart
@override
Map<String, dynamic> get settings => {
  'DEBUG': true,
  'DATABASE_URL': 'sqlite:///myapp.db',
  // or 'postgresql://user:pass@localhost:5432/mydb'
  'SECRET_KEY': 'your-secret-key',
};
```

### Admin Registration
```dart
@override
Future<void> setupAdmin(AdminSite adminSite) async {
  adminSite.register<BlogPost>(BlogPost, BlogPostAdmin(adminSite: adminSite));
  adminSite.register<User>(User, UserAdmin(adminSite: adminSite));
}
```

## 🌍 Deployment

### Building for Production
```bash
# Build backend
dartango build

# Build Flutter admin
cd admin
flutter build web
```

### Docker Deployment
```dockerfile
FROM dart:stable

WORKDIR /app
COPY . .
RUN dart pub get
RUN dart compile exe bin/main.dart -o server

FROM ubuntu:20.04
COPY --from=0 /app/server /app/server
COPY --from=0 /app/admin/build/web /app/admin

EXPOSE 8000
CMD ["/app/server"]
```

## 🆘 Support

- **Documentation**: [dartango.dev/docs](https://dartango.dev/docs)
- **Examples**: `~/.dartango/examples/`
- **Issues**: [GitHub Issues](https://github.com/dartango/framework/issues)
- **Discord**: [Dartango Community](https://discord.gg/dartango)

## 🔄 Updating

```bash
# Check for updates
dartango doctor

# Reinstall latest version
curl -fsSL https://raw.githubusercontent.com/dartango/framework/main/install.sh | bash
```

## 🗑️ Uninstalling

```bash
rm -rf ~/.dartango
# Remove from your shell profile: ~/.zshrc, ~/.bashrc, etc.
# Remove the lines:
# export DARTANGO_HOME="$HOME/.dartango" 
# export PATH="$DARTANGO_HOME/bin:$PATH"
```

---

**🐍 Django for Dart developers** - Build modern web applications with the power of Dart and the elegance of Django!