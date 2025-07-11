import '../../../../packages/dartango/lib/src/core/database/models.dart';
import '../../../../packages/dartango/lib/src/core/database/fields.dart';
import 'customer.dart';
import 'product.dart';

enum OrderStatus {
  pending,
  processing,
  shipped,
  delivered,
  cancelled,
  refunded
}

class Order extends Model {
  final AutoField idField = AutoField();
  final ForeignKeyField customerField = ForeignKeyField(Customer);
  final CharField statusField = CharField(maxLength: 20, defaultValue: 'pending');
  final DecimalField totalAmountField = DecimalField(maxDigits: 10, decimalPlaces: 2);
  final DecimalField shippingCostField = DecimalField(maxDigits: 10, decimalPlaces: 2, defaultValue: 0.0);
  final DecimalField taxAmountField = DecimalField(maxDigits: 10, decimalPlaces: 2, defaultValue: 0.0);
  final TextField notesField = TextField(blank: true);
  final CharField trackingNumberField = CharField(maxLength: 100, blank: true);
  final DateTimeField orderDateField = DateTimeField(autoNowAdd: true);
  final DateTimeField shippedDateField = DateTimeField(allowNull: true);
  final DateTimeField deliveredDateField = DateTimeField(allowNull: true);
  final DateTimeField createdAtField = DateTimeField(autoNowAdd: true);
  final DateTimeField updatedAtField = DateTimeField(autoNow: true);

  @override
  ModelMeta get meta => const ModelMeta(
    tableName: 'shop_orders',
    verboseName: 'Order',
    verboseNamePlural: 'Orders',
    ordering: ['-order_date'],
  );

  int get id => getField('id') ?? 0;
  set id(int value) => setField('id', value);

  int get customerId => getField('customer_id') ?? 0;
  set customerId(int value) => setField('customer_id', value);

  String get status => getField('status') ?? 'pending';
  set status(String value) => setField('status', value);

  double get totalAmount => getField('total_amount') ?? 0.0;
  set totalAmount(double value) => setField('total_amount', value);

  double get shippingCost => getField('shipping_cost') ?? 0.0;
  set shippingCost(double value) => setField('shipping_cost', value);

  double get taxAmount => getField('tax_amount') ?? 0.0;
  set taxAmount(double value) => setField('tax_amount', value);

  String get notes => getField('notes') ?? '';
  set notes(String value) => setField('notes', value);

  String get trackingNumber => getField('tracking_number') ?? '';
  set trackingNumber(String value) => setField('tracking_number', value);

  DateTime get orderDate => getField('order_date') ?? DateTime.now();
  set orderDate(DateTime value) => setField('order_date', value);

  DateTime? get shippedDate => getField('shipped_date');
  set shippedDate(DateTime? value) => setField('shipped_date', value);

  DateTime? get deliveredDate => getField('delivered_date');
  set deliveredDate(DateTime? value) => setField('delivered_date', value);

  DateTime get createdAt => getField('created_at') ?? DateTime.now();
  set createdAt(DateTime value) => setField('created_at', value);

  DateTime get updatedAt => getField('updated_at') ?? DateTime.now();
  set updatedAt(DateTime value) => setField('updated_at', value);

  @override
  String toString() => 'Order #$id';

  String get formattedTotal => '\$${totalAmount.toStringAsFixed(2)}';
  
  OrderStatus get orderStatus => OrderStatus.values.firstWhere(
    (e) => e.name == status,
    orElse: () => OrderStatus.pending,
  );

  bool get canBeCancelled => ['pending', 'processing'].contains(status);
  bool get isShipped => ['shipped', 'delivered'].contains(status);
  bool get isCompleted => status == 'delivered';

  void markAsProcessing() {
    status = 'processing';
  }

  void markAsShipped({String? trackingNumber}) {
    status = 'shipped';
    shippedDate = DateTime.now();
    if (trackingNumber != null) {
      this.trackingNumber = trackingNumber;
    }
  }

  void markAsDelivered() {
    status = 'delivered';
    deliveredDate = DateTime.now();
  }

  void cancel() {
    if (canBeCancelled) {
      status = 'cancelled';
    } else {
      throw Exception('Order cannot be cancelled in current status');
    }
  }
}

class OrderItem extends Model {
  final AutoField idField = AutoField();
  final ForeignKeyField orderField = ForeignKeyField(Order);
  final ForeignKeyField productField = ForeignKeyField(Product);
  final IntegerField quantityField = IntegerField();
  final DecimalField unitPriceField = DecimalField(maxDigits: 10, decimalPlaces: 2);
  final DecimalField totalPriceField = DecimalField(maxDigits: 10, decimalPlaces: 2);

  @override
  ModelMeta get meta => const ModelMeta(
    tableName: 'shop_order_items',
    verboseName: 'Order Item',
    verboseNamePlural: 'Order Items',
  );

  int get id => getField('id') ?? 0;
  set id(int value) => setField('id', value);

  int get orderId => getField('order_id') ?? 0;
  set orderId(int value) => setField('order_id', value);

  int get productId => getField('product_id') ?? 0;
  set productId(int value) => setField('product_id', value);

  int get quantity => getField('quantity') ?? 0;
  set quantity(int value) => setField('quantity', value);

  double get unitPrice => getField('unit_price') ?? 0.0;
  set unitPrice(double value) => setField('unit_price', value);

  double get totalPrice => getField('total_price') ?? 0.0;
  set totalPrice(double value) => setField('total_price', value);

  @override
  String toString() => 'OrderItem #$id';

  String get formattedUnitPrice => '\$${unitPrice.toStringAsFixed(2)}';
  String get formattedTotalPrice => '\$${totalPrice.toStringAsFixed(2)}';

  void calculateTotal() {
    totalPrice = unitPrice * quantity;
  }
}