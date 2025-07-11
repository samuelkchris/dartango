import '../../../../packages/dartango/lib/src/core/database/models.dart';
import '../../../../packages/dartango/lib/src/core/database/fields.dart';

class Customer extends Model {
  final AutoField idField = AutoField();
  final CharField firstNameField = CharField(maxLength: 100);
  final CharField lastNameField = CharField(maxLength: 100);
  final EmailField emailField = EmailField(unique: true);
  final CharField phoneField = CharField(maxLength: 20, blank: true);
  final TextField addressField = TextField(blank: true);
  final CharField cityField = CharField(maxLength: 100, blank: true);
  final CharField stateField = CharField(maxLength: 100, blank: true);
  final CharField zipCodeField = CharField(maxLength: 20, blank: true);
  final CharField countryField = CharField(maxLength: 100, defaultValue: 'US');
  final BooleanField isActiveField = BooleanField(defaultValue: true);
  final DateTimeField createdAtField = DateTimeField(autoNowAdd: true);
  final DateTimeField updatedAtField = DateTimeField(autoNow: true);

  @override
  ModelMeta get meta => const ModelMeta(
    tableName: 'shop_customers',
    verboseName: 'Customer',
    verboseNamePlural: 'Customers',
    ordering: ['-created_at'],
  );

  int get id => getField('id') ?? 0;
  set id(int value) => setField('id', value);

  String get firstName => getField('first_name') ?? '';
  set firstName(String value) => setField('first_name', value);

  String get lastName => getField('last_name') ?? '';
  set lastName(String value) => setField('last_name', value);

  String get email => getField('email') ?? '';
  set email(String value) => setField('email', value);

  String get phone => getField('phone') ?? '';
  set phone(String value) => setField('phone', value);

  String get address => getField('address') ?? '';
  set address(String value) => setField('address', value);

  String get city => getField('city') ?? '';
  set city(String value) => setField('city', value);

  String get state => getField('state') ?? '';
  set state(String value) => setField('state', value);

  String get zipCode => getField('zip_code') ?? '';
  set zipCode(String value) => setField('zip_code', value);

  String get country => getField('country') ?? 'US';
  set country(String value) => setField('country', value);

  bool get isActive => getField('is_active') ?? true;
  set isActive(bool value) => setField('is_active', value);

  DateTime get createdAt => getField('created_at') ?? DateTime.now();
  set createdAt(DateTime value) => setField('created_at', value);

  DateTime get updatedAt => getField('updated_at') ?? DateTime.now();
  set updatedAt(DateTime value) => setField('updated_at', value);

  @override
  String toString() => '$firstName $lastName';

  String get fullName => '$firstName $lastName';
  
  String get fullAddress {
    final parts = <String>[];
    if (address.isNotEmpty) parts.add(address);
    if (city.isNotEmpty) parts.add(city);
    if (state.isNotEmpty) parts.add(state);
    if (zipCode.isNotEmpty) parts.add(zipCode);
    if (country.isNotEmpty) parts.add(country);
    return parts.join(', ');
  }
}