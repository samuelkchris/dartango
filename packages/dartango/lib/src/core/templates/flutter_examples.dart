import 'flutter_renderer.dart';
import 'flutter_template_engine.dart';

/// Example Flutter templates demonstrating the system
class FlutterTemplateExamples {
  
  /// Blog post template
  static FlutterWidget blogPost(Map<String, dynamic> context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blog'),
        backgroundColor: const Color(0xFF2196F3),
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '{{ title }}',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: const Text(
                'By {{ author }} on {{ date }}',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.only(top: 16),
              child: const Text(
                '{{ content }}',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.only(top: 24),
              child: const Row(
                children: [
                  ElevatedButton(
                    onPressed: null,
                    child: Text('← Back to Posts'),
                  ),
                  ElevatedButton(
                    onPressed: null,
                    child: Text('Share'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// E-commerce product list template
  static FlutterWidget productList(Map<String, dynamic> context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        backgroundColor: const Color(0xFF4CAF50),
        actions: [
          ElevatedButton(
            onPressed: null,
            child: const Text('Cart ({{ cart_count }})'),
          ),
        ],
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Search bar
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFFF5F5F5),
              ),
              child: Text('Search products...'),
            ),
            
            // Product grid
            Container(
              padding: EdgeInsets.only(top: 16),
              child: Column(
                children: [
                  // This would be dynamically generated from products list
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ProductCard({
                        'name': 'Product 1',
                        'price': '\$29.99',
                        'image': 'product1.jpg',
                      }),
                      ProductCard({
                        'name': 'Product 2',
                        'price': '\$39.99',
                        'image': 'product2.jpg',
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Dashboard with analytics
  static FlutterWidget dashboard(Map<String, dynamic> context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: const Color(0xFF673AB7),
        actions: [
          ElevatedButton(
            onPressed: null,
            child: const Text('Settings'),
          ),
        ],
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Stats cards
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                StatsCard({
                  'title': 'Users',
                  'value': '{{ user_count }}',
                  'color': '0xFF2196F3',
                }),
                StatsCard({
                  'title': 'Orders',
                  'value': '{{ order_count }}',
                  'color': '0xFF4CAF50',
                }),
                StatsCard({
                  'title': 'Revenue',
                  'value': '{{ revenue }}',
                  'color': '0xFFFF9800',
                }),
              ],
            ),
            
            // Chart placeholder
            Container(
              padding: EdgeInsets.only(top: 24),
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFFF5F5F5),
                ),
                child: const Text(
                  'Chart: Sales over time',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            
            // Recent activity
            Container(
              padding: EdgeInsets.only(top: 24),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Activity',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ActivityItem({
                    'title': 'New user registered',
                    'time': '2 minutes ago',
                  }),
                  ActivityItem({
                    'title': 'Order #1234 completed',
                    'time': '5 minutes ago',
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Form template with validation
  static FlutterWidget userForm(Map<String, dynamic> context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
        backgroundColor: const Color(0xFF795548),
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Form fields
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFFF5F5F5),
              ),
              child: const Column(
                children: [
                  FormField({'label': 'Name', 'value': '{{ name }}'}),
                  FormField({'label': 'Email', 'value': '{{ email }}'}),
                  FormField({'label': 'Phone', 'value': '{{ phone }}'}),
                ],
              ),
            ),
            
            // Actions
            Container(
              padding: EdgeInsets.only(top: 16),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: null,
                    child: Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: null,
                    child: Text('Save'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Register all example templates
  static void registerAll(FlutterTemplateEngine engine) {
    engine.registerTemplate('blog_post', blogPost);
    engine.registerTemplate('product_list', productList);
    engine.registerTemplate('dashboard', dashboard);
    engine.registerTemplate('user_form', userForm);
  }
}

/// Product card component
class ProductCard extends TemplateComponent {
  const ProductCard(super.props);
  
  @override
  FlutterWidget build(Map<String, dynamic> context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFFFFFFFF),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFFE0E0E0),
            ),
            child: const Text('📦 Image'),
          ),
          Text(
            context['name']?.toString() ?? '',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            context['price']?.toString() ?? '',
            style: const TextStyle(
              fontSize: 18,
              color: Color(0xFF4CAF50),
              fontWeight: FontWeight.bold,
            ),
          ),
          ElevatedButton(
            onPressed: null,
            child: const Text('Add to Cart'),
          ),
        ],
      ),
    );
  }
}

/// Stats card component
class StatsCard extends TemplateComponent {
  const StatsCard(super.props);
  
  @override
  FlutterWidget build(Map<String, dynamic> context) {
    final colorStr = context['color']?.toString() ?? '0xFF2196F3';
    final color = Color(int.parse(colorStr));
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
      ),
      child: Column(
        children: [
          Text(
            context['title']?.toString() ?? '',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFFFFFFFF),
            ),
          ),
          Text(
            context['value']?.toString() ?? '',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFFFFF),
            ),
          ),
        ],
      ),
    );
  }
}

/// Activity item component
class ActivityItem extends TemplateComponent {
  const ActivityItem(super.props);
  
  @override
  FlutterWidget build(Map<String, dynamic> context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFF2196F3),
            ),
            child: const Text('•'),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context['title']?.toString() ?? '',
                style: const TextStyle(fontSize: 14),
              ),
              Text(
                context['time']?.toString() ?? '',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF666666),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Form field component
class FormField extends TemplateComponent {
  const FormField(super.props);
  
  @override
  FlutterWidget build(Map<String, dynamic> context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context['label']?.toString() ?? '',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFFFFFFFF),
            ),
            child: Text(
              context['value']?.toString() ?? '',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}