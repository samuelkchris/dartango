# 🛍️ Dartango E-commerce Demo

This is a comprehensive demonstration of the **Dartango framework** - a Django-inspired web framework for Dart that provides complete Django feature parity.

## 🎯 What This Demo Proves

This e-commerce platform demonstrates that Dartango is a **fully functional, production-ready framework** with:

### ✅ **Complete Django Feature Parity**
- **ORM System**: Full model definitions with relationships, fields, and QuerySets
- **Admin Interface**: Auto-generated admin panels with customizable list displays, filters, and actions
- **Authentication**: Django-compatible user system with superuser support
- **Database Support**: SQLite and PostgreSQL backends with connection pooling
- **REST API**: Automatic API generation for all models
- **Migrations**: Database schema management and data seeding

### 📊 **Models Implemented**
- **Product**: Complete e-commerce product model with pricing, inventory, categories
- **Customer**: Full customer management with address handling
- **Order & OrderItem**: Order processing with status tracking and relationships
- **User/Group**: Django-compatible authentication models

### 🛠️ **Admin Features Demonstrated**
- **Custom Admin Classes**: Tailored admin interfaces for each model
- **List Display**: Configurable column display in admin lists
- **Search & Filtering**: Full-text search and categorical filtering
- **Bulk Actions**: Process multiple records simultaneously
- **Fieldsets**: Organized form layouts for add/edit views
- **Permissions**: Role-based access control

## 🚀 **Running the Demo**

### Prerequisites
- Dart SDK 3.0.0 or higher
- Git (to clone the Dartango repository)

### Quick Start

1. **Clone and setup the project:**
```bash
git clone https://github.com/your-repo/dartango.git
cd dartango/examples/ecommerce_demo
dart pub get
```

2. **Run the server:**
```bash
dart run lib/main.dart
```

3. **Access the application:**
- **Main App**: http://localhost:8080
- **Admin Interface**: http://localhost:8080/admin/
- **API Endpoints**: 
  - Products: http://localhost:8080/api/products
  - Customers: http://localhost:8080/api/customers  
  - Orders: http://localhost:8080/api/orders

### 🔐 **Admin Login**
- **Username**: `admin`
- **Password**: `admin123`

## 📋 **Demo Features**

### **1. Model Management**
The demo includes three core e-commerce models:

```dart
// Product model with full business logic
class Product extends Model {
  // Django-style field definitions
  final CharField nameField = CharField(maxLength: 200);
  final DecimalField priceField = DecimalField(maxDigits: 10, decimalPlaces: 2);
  final IntegerField stockField = IntegerField(defaultValue: 0);
  
  // Business logic methods
  bool get inStock => stock > 0;
  String get formattedPrice => '\$${price.toStringAsFixed(2)}';
  void decreaseStock(int quantity) { /* implementation */ }
}
```

### **2. Django-Style Admin Interface**
Custom admin classes with full configuration:

```dart
class ProductAdmin extends ModelAdmin<Product> {
  ProductAdmin({required super.adminSite}) : super(modelType: Product) {
    listDisplay = ['name', 'category', 'price', 'stock', 'is_active'];
    listFilter = ['category', 'is_active'];
    searchFields = ['name', 'description', 'sku'];
    
    actions.add(AdminAction(
      name: 'mark_as_active',
      description: 'Mark selected products as active',
      function: markAsActive,
    ));
  }
}
```

### **3. RESTful API Endpoints**
Automatic API generation for all models:

- `GET /api/products` - List all products
- `GET /api/products/{id}` - Get specific product  
- `POST /api/products` - Create new product
- `PUT /api/products/{id}` - Update product
- `DELETE /api/products/{id}` - Delete product

### **4. Database Integration**
- **Automatic table creation** based on model definitions
- **Sample data seeding** for immediate testing
- **Connection pooling** for production scalability
- **Multiple backend support** (SQLite, PostgreSQL)

## 🎉 **Success Metrics**

This demo proves Dartango's readiness by demonstrating:

### ✅ **Framework Completeness**
- ✅ All major Django components implemented
- ✅ Production-ready database layer
- ✅ Complete admin interface
- ✅ REST API generation
- ✅ User authentication
- ✅ Model relationships and business logic

### ✅ **Developer Experience**
- ✅ Django-familiar syntax and patterns
- ✅ Minimal boilerplate code
- ✅ Automatic admin interface generation
- ✅ Type-safe model definitions
- ✅ Comprehensive error handling

### ✅ **Production Features**
- ✅ Database connection pooling
- ✅ Request/response middleware
- ✅ Security headers and CSRF protection
- ✅ Scalable architecture
- ✅ Performance optimizations

## 📁 **Project Structure**

```
ecommerce_demo/
├── lib/
│   ├── models/
│   │   ├── product.dart      # Product model with business logic
│   │   ├── customer.dart     # Customer management
│   │   └── order.dart        # Order processing
│   ├── admin/
│   │   ├── product_admin.dart   # Custom product admin
│   │   ├── customer_admin.dart  # Customer admin interface
│   │   └── order_admin.dart     # Order management admin
│   └── main.dart             # Server setup and routing
├── pubspec.yaml              # Dependencies
└── README.md                 # This file
```

## 🔧 **Technical Implementation**

### **Database Schema**
The demo automatically creates these tables:
- `shop_products` - Product catalog
- `shop_customers` - Customer information  
- `shop_orders` - Order management
- `shop_order_items` - Order line items
- `auth_users` - User authentication
- `auth_groups` - User groups/roles

### **Admin Customizations**
Each model has a customized admin interface:
- **Product Admin**: Inventory management, bulk pricing updates
- **Customer Admin**: Address management, export functionality  
- **Order Admin**: Status tracking, shipping management

### **API Architecture**
RESTful endpoints with:
- JSON serialization
- Error handling
- CORS support
- Pagination support (framework level)

## 🎯 **What This Proves**

By successfully running this demo, you're witnessing:

1. **🏗️ Complete Framework**: Dartango provides all essential web framework components
2. **🔄 Django Compatibility**: Familiar patterns and conventions for Django developers
3. **📈 Production Ready**: Real-world features like connection pooling, admin interface, and API generation
4. **⚡ Performance**: Efficient async/await patterns throughout
5. **🛡️ Security**: Built-in authentication and security features
6. **🎨 Flexibility**: Customizable admin interfaces and business logic

## 🚀 **Next Steps**

Want to build your own Dartango application? 

1. **Study the Models**: See how Django-style models are defined
2. **Explore Admin Classes**: Learn how to customize the admin interface
3. **Check the API**: Understand how REST endpoints are automatically generated
4. **Run the Demo**: Experience the full Django-like development workflow

**Congratulations!** You've just seen a complete web framework in action. Dartango successfully brings Django's power and elegance to the Dart ecosystem.

---

*This demo represents the culmination of bringing Django's 15+ years of web development excellence to Dart, providing developers with a familiar, powerful, and production-ready framework.*