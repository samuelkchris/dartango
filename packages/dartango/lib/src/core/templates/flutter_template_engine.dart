import 'dart:io';
import 'flutter_renderer.dart';

/// Template engine that uses Flutter widgets for rendering
class FlutterTemplateEngine {
  final Map<String, FlutterWidget Function(Map<String, dynamic>)> _templates = {};
  final Map<String, String> _templateCache = {};
  final String _templateDir;
  final bool _debug;
  
  FlutterTemplateEngine({
    required String templateDir,
    bool debug = false,
  }) : _templateDir = templateDir, _debug = debug;
  
  /// Register a template widget
  void registerTemplate(String name, FlutterWidget Function(Map<String, dynamic>) builder) {
    _templates[name] = builder;
  }
  
  /// Render a template with context
  String render(String templateName, Map<String, dynamic> context) {
    // Check for registered template first
    if (_templates.containsKey(templateName)) {
      final widget = _templates[templateName]!(context);
      return widget.render(context);
    }
    
    // Try to load from file
    final templatePath = '$_templateDir/$templateName.dart';
    if (File(templatePath).existsSync()) {
      return _renderFromFile(templatePath, context);
    }
    
    // Fallback to simple text rendering
    return _renderFallback(templateName, context);
  }
  
  /// Render template from Dart file
  String _renderFromFile(String filePath, Map<String, dynamic> context) {
    try {
      // In a real implementation, this would compile and execute Dart code
      // For now, we'll return a placeholder
      return '''
        <div class="flutter-template">
          <h1>Flutter Template: ${filePath}</h1>
          <pre>${context.toString()}</pre>
        </div>
      ''';
    } catch (e) {
      if (_debug) {
        return '''
          <div class="template-error">
            <h3>Template Error</h3>
            <p>Failed to render template: $filePath</p>
            <pre>$e</pre>
          </div>
        ''';
      }
      return '<div class="template-error">Template rendering failed</div>';
    }
  }
  
  /// Fallback rendering for basic templates
  String _renderFallback(String templateName, Map<String, dynamic> context) {
    return '''
      <div class="fallback-template">
        <h2>$templateName</h2>
        <div class="context">
          ${context.entries.map((e) => '<div><strong>${e.key}:</strong> ${e.value}</div>').join('')}
        </div>
      </div>
    ''';
  }
  
  /// Clear template cache
  void clearCache() {
    _templateCache.clear();
  }
}

/// Template registry for predefined templates
class TemplateRegistry {
  static final Map<String, FlutterWidget Function(Map<String, dynamic>)> _registry = {};
  
  /// Register a template
  static void register(String name, FlutterWidget Function(Map<String, dynamic>) builder) {
    _registry[name] = builder;
  }
  
  /// Get registered template
  static FlutterWidget Function(Map<String, dynamic>)? get(String name) {
    return _registry[name];
  }
  
  /// List all registered templates
  static List<String> listTemplates() {
    return _registry.keys.toList();
  }
  
  /// Register common templates
  static void registerDefaults() {
    // Basic page template
    register('base', (context) => Scaffold(
      appBar: AppBar(
        title: Text(context['title']?.toString() ?? 'Dartango App'),
        backgroundColor: const Color(0xFF2196F3),
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context['content']?.toString() ?? 'Welcome to Dartango!',
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    ));
    
    // Login form template
    register('login', (context) => Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: const Color(0xFF2196F3),
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Color(0xFFF5F5F5),
              ),
              child: Column(
                children: [
                  const Text(
                    'Login to your account',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  // Form fields would go here
                  const Text('Username: {{ username }}'),
                  const Text('Password: {{ password }}'),
                  ElevatedButton(
                    onPressed: null,
                    child: const Text('Login'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
    
    // Admin dashboard template
    register('admin_dashboard', (context) => Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: const Color(0xFF4CAF50),
        actions: [
          ElevatedButton(
            onPressed: null,
            child: const Text('Logout'),
          ),
        ],
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFFE3F2FD),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Users',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text('{{ user_count }}'),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFFE8F5E8),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Models',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text('{{ model_count }}'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ));
    
    // Error page template
    register('error', (context) => Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
        backgroundColor: const Color(0xFFD32F2F),
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Error {{ status_code }}',
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Color(0xFFD32F2F)),
            ),
            Text(
              '{{ error_message }}',
              style: const TextStyle(fontSize: 18),
            ),
            ElevatedButton(
              onPressed: null,
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ));
  }
}

/// Template builder for creating widgets from context
class TemplateBuilder {
  /// Build a basic page layout
  static FlutterWidget buildBasicPage({
    required String title,
    required FlutterWidget body,
    List<FlutterWidget>? actions,
    Color? backgroundColor,
  }) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
        backgroundColor: backgroundColor ?? const Color(0xFF2196F3),
      ),
      body: body,
      backgroundColor: backgroundColor ?? const Color(0xFFFFFFFF),
    );
  }
  
  /// Build a form layout
  static FlutterWidget buildForm({
    required String title,
    required List<FlutterWidget> fields,
    required List<FlutterWidget> actions,
  }) {
    return buildBasicPage(
      title: title,
      body: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            ...fields,
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: actions,
            ),
          ],
        ),
      ),
    );
  }
  
  /// Build a list layout
  static FlutterWidget buildList({
    required String title,
    required List<FlutterWidget> items,
    FlutterWidget? emptyWidget,
  }) {
    return buildBasicPage(
      title: title,
      body: Container(
        padding: EdgeInsets.all(16),
        child: items.isNotEmpty
            ? Column(children: items)
            : (emptyWidget ?? const Text('No items found')),
      ),
    );
  }
  
  /// Build a dashboard layout
  static FlutterWidget buildDashboard({
    required String title,
    required List<FlutterWidget> widgets,
    int columns = 2,
  }) {
    return buildBasicPage(
      title: title,
      body: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          children: _buildGrid(widgets, columns),
        ),
      ),
    );
  }
  
  /// Build a grid layout
  static List<FlutterWidget> _buildGrid(List<FlutterWidget> items, int columns) {
    final rows = <FlutterWidget>[];
    for (int i = 0; i < items.length; i += columns) {
      final rowItems = items.sublist(i, (i + columns).clamp(0, items.length));
      rows.add(Row(children: rowItems));
    }
    return rows;
  }
}

/// Template context helper
class TemplateContext {
  final Map<String, dynamic> _data = {};
  
  TemplateContext([Map<String, dynamic>? initialData]) {
    if (initialData != null) {
      _data.addAll(initialData);
    }
  }
  
  /// Add data to context
  void add(String key, dynamic value) {
    _data[key] = value;
  }
  
  /// Add multiple values
  void addAll(Map<String, dynamic> data) {
    _data.addAll(data);
  }
  
  /// Get value from context
  T? get<T>(String key) {
    return _data[key] as T?;
  }
  
  /// Check if key exists
  bool has(String key) {
    return _data.containsKey(key);
  }
  
  /// Get all data
  Map<String, dynamic> toMap() {
    return Map.from(_data);
  }
  
  /// Clear context
  void clear() {
    _data.clear();
  }
}

/// Template component for reusable widgets
abstract class TemplateComponent extends FlutterWidget {
  final Map<String, dynamic> props;
  
  const TemplateComponent(this.props);
  
  @override
  String render(Map<String, dynamic> context) {
    final mergedContext = {...context, ...props};
    return build(mergedContext).render(mergedContext);
  }
  
  /// Build the component widget
  FlutterWidget build(Map<String, dynamic> context);
}

/// Card component example
class CardComponent extends TemplateComponent {
  const CardComponent(super.props);
  
  @override
  FlutterWidget build(Map<String, dynamic> context) {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Color(0xFFFFFFFF),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context['title']?.toString() ?? '',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            context['content']?.toString() ?? '',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}

/// Button component example
class ButtonComponent extends TemplateComponent {
  const ButtonComponent(super.props);
  
  @override
  FlutterWidget build(Map<String, dynamic> context) {
    return ElevatedButton(
      onPressed: null,
      child: Text(context['text']?.toString() ?? 'Button'),
    );
  }
}