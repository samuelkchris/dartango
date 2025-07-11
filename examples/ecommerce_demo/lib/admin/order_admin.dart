import '../../../../packages/dartango/lib/src/core/admin/admin.dart';
import '../models/order.dart';
import '../models/customer.dart';

class OrderAdmin extends ModelAdmin<Order> {
  OrderAdmin({required super.adminSite}) : super(modelType: Order) {
    // Configure list display
    listDisplay = [
      'id',
      'customer_name',
      'status',
      'total_amount',
      'order_date',
      'tracking_number'
    ];

    // Configure filters
    listFilter = ['status', 'order_date'];

    // Configure search fields
    searchFields = ['id', 'tracking_number', 'customer__email'];

    // Configure ordering
    orderingFields = ['order_date', 'total_amount', 'status'];

    // Configure fieldsets for add/edit forms
    fieldsets = {
      'Order Information': ['customer_id', 'status', 'notes'],
      'Financial Details': ['total_amount', 'shipping_cost', 'tax_amount'],
      'Shipping': ['tracking_number', 'shipped_date', 'delivered_date'],
    };

    // Readonly fields for edit view
    readonlyFields = ['order_date', 'created_at', 'updated_at'];

    // Configure actions
    actions.addAll([
      AdminAction(
        name: 'mark_as_processing',
        description: 'Mark selected orders as processing',
        function: markAsProcessing,
      ),
      AdminAction(
        name: 'mark_as_shipped',
        description: 'Mark selected orders as shipped',
        function: markAsShipped,
      ),
      AdminAction(
        name: 'cancel_orders',
        description: 'Cancel selected orders',
        function: cancelOrders,
      ),
    ]);
  }

  @override
  Future<List<Order>> getQueryset({
    String? search,
    Map<String, dynamic> filters = const {},
    String? ordering,
    int? limit,
    int? offset,
  }) async {
    // Implementation would use QuerySet to fetch orders with related customers
    // For demo purposes, return mock data
    return [
      Order()
        ..id = 1001
        ..customerId = 1
        ..status = 'pending'
        ..totalAmount = 249.98
        ..shippingCost = 9.99
        ..taxAmount = 20.00
        ..orderDate = DateTime.now().subtract(const Duration(days: 1)),
      Order()
        ..id = 1002
        ..customerId = 2
        ..status = 'shipped'
        ..totalAmount = 79.99
        ..shippingCost = 5.99
        ..taxAmount = 6.40
        ..trackingNumber = 'TRK123456789'
        ..orderDate = DateTime.now().subtract(const Duration(days: 3))
        ..shippedDate = DateTime.now().subtract(const Duration(days: 1)),
      Order()
        ..id = 1003
        ..customerId = 1
        ..status = 'delivered'
        ..totalAmount = 199.99
        ..shippingCost = 0.00
        ..taxAmount = 16.00
        ..trackingNumber = 'TRK987654321'
        ..orderDate = DateTime.now().subtract(const Duration(days: 7))
        ..shippedDate = DateTime.now().subtract(const Duration(days: 5))
        ..deliveredDate = DateTime.now().subtract(const Duration(days: 2)),
    ];
  }

  @override
  Future<Order?> getObject(dynamic pk) async {
    final orders = await getQueryset();
    try {
      return orders.firstWhere((o) => o.id == int.parse(pk.toString()));
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Order> createObject(Map<String, dynamic> data) async {
    final order = Order()
      ..customerId = int.tryParse(data['customer_id']?.toString() ?? '0') ?? 0
      ..status = data['status'] ?? 'pending'
      ..totalAmount = double.tryParse(data['total_amount']?.toString() ?? '0') ?? 0.0
      ..shippingCost = double.tryParse(data['shipping_cost']?.toString() ?? '0') ?? 0.0
      ..taxAmount = double.tryParse(data['tax_amount']?.toString() ?? '0') ?? 0.0
      ..notes = data['notes'] ?? ''
      ..trackingNumber = data['tracking_number'] ?? '';

    // Set dates if provided
    if (data['shipped_date'] != null) {
      order.shippedDate = DateTime.tryParse(data['shipped_date']);
    }
    if (data['delivered_date'] != null) {
      order.deliveredDate = DateTime.tryParse(data['delivered_date']);
    }

    // In real implementation, this would save to database
    await order.save();
    return order;
  }

  @override
  Future<Order> updateObject(Order instance, Map<String, dynamic> data) async {
    if (data.containsKey('customer_id')) {
      instance.customerId = int.tryParse(data['customer_id']?.toString() ?? '0') ?? 0;
    }
    if (data.containsKey('status')) instance.status = data['status'];
    if (data.containsKey('total_amount')) {
      instance.totalAmount = double.tryParse(data['total_amount']?.toString() ?? '0') ?? 0.0;
    }
    if (data.containsKey('shipping_cost')) {
      instance.shippingCost = double.tryParse(data['shipping_cost']?.toString() ?? '0') ?? 0.0;
    }
    if (data.containsKey('tax_amount')) {
      instance.taxAmount = double.tryParse(data['tax_amount']?.toString() ?? '0') ?? 0.0;
    }
    if (data.containsKey('notes')) instance.notes = data['notes'];
    if (data.containsKey('tracking_number')) instance.trackingNumber = data['tracking_number'];

    // Set dates if provided
    if (data.containsKey('shipped_date')) {
      instance.shippedDate = data['shipped_date'] != null 
          ? DateTime.tryParse(data['shipped_date']) 
          : null;
    }
    if (data.containsKey('delivered_date')) {
      instance.deliveredDate = data['delivered_date'] != null 
          ? DateTime.tryParse(data['delivered_date']) 
          : null;
    }

    // In real implementation, this would update in database
    await instance.save();
    return instance;
  }

  @override
  Future<void> deleteObject(Order instance) async {
    // In real implementation, this would delete from database
    await instance.delete();
  }

  // Custom admin actions
  Future<void> markAsProcessing(List<Order> orders) async {
    for (final order in orders) {
      if (order.status == 'pending') {
        order.markAsProcessing();
        await order.save();
      }
    }
  }

  Future<void> markAsShipped(List<Order> orders) async {
    for (final order in orders) {
      if (['pending', 'processing'].contains(order.status)) {
        order.markAsShipped();
        await order.save();
      }
    }
  }

  Future<void> cancelOrders(List<Order> orders) async {
    for (final order in orders) {
      try {
        order.cancel();
        await order.save();
      } catch (e) {
        // Skip orders that can't be cancelled
        continue;
      }
    }
  }

  @override
  String getObjectName(Order instance) {
    return 'Order #${instance.id}';
  }

  @override
  String getAppLabel() {
    return 'shop';
  }

  // Custom method to get customer name for list display
  String getCustomerName(Order order) {
    // In real implementation, this would join with customer table
    return 'Customer #${order.customerId}';
  }
}