import '../../../../packages/dartango/lib/src/core/admin/admin.dart';
import '../models/product.dart';

class ProductAdmin extends ModelAdmin<Product> {
  ProductAdmin({required super.adminSite}) : super(modelType: Product) {
    // Configure list display
    listDisplay = [
      'name',
      'category',
      'price',
      'stock',
      'is_active',
      'created_at'
    ];

    // Configure filters
    listFilter = ['category', 'is_active'];

    // Configure search fields
    searchFields = ['name', 'description', 'sku'];

    // Configure ordering
    orderingFields = ['name', 'price', 'stock', 'created_at'];

    // Configure fieldsets for add/edit forms
    fieldsets = {
      'Basic Information': ['name', 'description', 'category', 'sku'],
      'Pricing & Inventory': ['price', 'stock', 'is_active'],
      'Media': ['image'],
    };

    // Readonly fields for edit view
    readonlyFields = ['created_at', 'updated_at'];

    // Configure actions
    actions.addAll([
      AdminAction(
        name: 'mark_as_active',
        description: 'Mark selected products as active',
        function: markAsActive,
      ),
      AdminAction(
        name: 'mark_as_inactive',
        description: 'Mark selected products as inactive',
        function: markAsInactive,
      ),
      AdminAction(
        name: 'restock_products',
        description: 'Add stock to selected products',
        function: restockProducts,
      ),
    ]);
  }

  @override
  Future<List<Product>> getQueryset({
    String? search,
    Map<String, dynamic> filters = const {},
    String? ordering,
    int? limit,
    int? offset,
  }) async {
    // Implementation would use QuerySet to fetch products
    // For demo purposes, return mock data
    return [
      Product()
        ..id = 1
        ..name = 'Wireless Headphones'
        ..description = 'High-quality wireless headphones with noise cancellation'
        ..price = 199.99
        ..stock = 15
        ..category = 'Electronics'
        ..sku = 'WH-001'
        ..isActive = true,
      Product()
        ..id = 2
        ..name = 'Smartphone Case'
        ..description = 'Protective case for smartphones'
        ..price = 24.99
        ..stock = 50
        ..category = 'Accessories'
        ..sku = 'SC-002'
        ..isActive = true,
      Product()
        ..id = 3
        ..name = 'Laptop Stand'
        ..description = 'Adjustable laptop stand for ergonomic use'
        ..price = 79.99
        ..stock = 0
        ..category = 'Office'
        ..sku = 'LS-003'
        ..isActive = false,
    ];
  }

  @override
  Future<Product?> getObject(dynamic pk) async {
    final products = await getQueryset();
    try {
      return products.firstWhere((p) => p.id == int.parse(pk.toString()));
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Product> createObject(Map<String, dynamic> data) async {
    final product = Product()
      ..name = data['name'] ?? ''
      ..description = data['description'] ?? ''
      ..price = double.tryParse(data['price']?.toString() ?? '0') ?? 0.0
      ..stock = int.tryParse(data['stock']?.toString() ?? '0') ?? 0
      ..category = data['category'] ?? ''
      ..sku = data['sku'] ?? ''
      ..isActive = data['is_active'] == true || data['is_active'] == 'true'
      ..image = data['image'] ?? '';

    // In real implementation, this would save to database
    await product.save();
    return product;
  }

  @override
  Future<Product> updateObject(Product instance, Map<String, dynamic> data) async {
    if (data.containsKey('name')) instance.name = data['name'];
    if (data.containsKey('description')) instance.description = data['description'];
    if (data.containsKey('price')) {
      instance.price = double.tryParse(data['price']?.toString() ?? '0') ?? 0.0;
    }
    if (data.containsKey('stock')) {
      instance.stock = int.tryParse(data['stock']?.toString() ?? '0') ?? 0;
    }
    if (data.containsKey('category')) instance.category = data['category'];
    if (data.containsKey('sku')) instance.sku = data['sku'];
    if (data.containsKey('is_active')) {
      instance.isActive = data['is_active'] == true || data['is_active'] == 'true';
    }
    if (data.containsKey('image')) instance.image = data['image'];

    // In real implementation, this would update in database
    await instance.save();
    return instance;
  }

  @override
  Future<void> deleteObject(Product instance) async {
    // In real implementation, this would delete from database
    await instance.delete();
  }

  // Custom admin actions
  Future<void> markAsActive(List<Product> products) async {
    for (final product in products) {
      product.isActive = true;
      await product.save();
    }
  }

  Future<void> markAsInactive(List<Product> products) async {
    for (final product in products) {
      product.isActive = false;
      await product.save();
    }
  }

  Future<void> restockProducts(List<Product> products) async {
    for (final product in products) {
      product.stock += 10; // Add 10 units to stock
      await product.save();
    }
  }

  @override
  String getObjectName(Product instance) {
    return '${instance.name} (${instance.sku})';
  }

  @override
  String getAppLabel() {
    return 'shop';
  }
}