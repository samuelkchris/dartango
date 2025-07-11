import '../../../../packages/dartango/lib/src/core/database/models.dart';
import '../../../../packages/dartango/lib/src/core/database/fields.dart';

class Product extends Model {
  final AutoField idField = AutoField();
  final CharField nameField = CharField(maxLength: 200);
  final TextField descriptionField = TextField(blank: true);
  final DecimalField priceField = DecimalField(maxDigits: 10, decimalPlaces: 2);
  final IntegerField stockField = IntegerField(defaultValue: 0);
  final BooleanField isActiveField = BooleanField(defaultValue: true);
  final CharField categoryField = CharField(maxLength: 100, blank: true);
  final CharField skuField = CharField(maxLength: 50, unique: true);
  final ImageField imageField = ImageField(blank: true);
  final DateTimeField createdAtField = DateTimeField(autoNowAdd: true);
  final DateTimeField updatedAtField = DateTimeField(autoNow: true);

  @override
  ModelMeta get meta => const ModelMeta(
    tableName: 'shop_products',
    verboseName: 'Product',
    verboseNamePlural: 'Products',
    ordering: ['-created_at'],
  );

  int get id => getField('id') ?? 0;
  set id(int value) => setField('id', value);

  String get name => getField('name') ?? '';
  set name(String value) => setField('name', value);

  String get description => getField('description') ?? '';
  set description(String value) => setField('description', value);

  double get price => getField('price') ?? 0.0;
  set price(double value) => setField('price', value);

  int get stock => getField('stock') ?? 0;
  set stock(int value) => setField('stock', value);

  bool get isActive => getField('is_active') ?? true;
  set isActive(bool value) => setField('is_active', value);

  String get category => getField('category') ?? '';
  set category(String value) => setField('category', value);

  String get sku => getField('sku') ?? '';
  set sku(String value) => setField('sku', value);

  String get image => getField('image') ?? '';
  set image(String value) => setField('image', value);

  DateTime get createdAt => getField('created_at') ?? DateTime.now();
  set createdAt(DateTime value) => setField('created_at', value);

  DateTime get updatedAt => getField('updated_at') ?? DateTime.now();
  set updatedAt(DateTime value) => setField('updated_at', value);

  @override
  String toString() => name;

  // Business logic methods
  bool get inStock => stock > 0;
  
  String get formattedPrice => '\$${price.toStringAsFixed(2)}';

  void decreaseStock(int quantity) {
    if (stock >= quantity) {
      stock -= quantity;
    } else {
      throw Exception('Insufficient stock');
    }
  }

  void increaseStock(int quantity) {
    stock += quantity;
  }
}