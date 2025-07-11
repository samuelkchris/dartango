import '../../../../packages/dartango/lib/src/core/admin/admin.dart';
import '../models/customer.dart';

class CustomerAdmin extends ModelAdmin<Customer> {
  CustomerAdmin({required super.adminSite}) : super(modelType: Customer) {
    // Configure list display
    listDisplay = [
      'full_name',
      'email',
      'phone',
      'city',
      'state',
      'is_active',
      'created_at'
    ];

    // Configure filters
    listFilter = ['is_active', 'country', 'state'];

    // Configure search fields
    searchFields = ['first_name', 'last_name', 'email', 'phone'];

    // Configure ordering
    orderingFields = ['last_name', 'first_name', 'email', 'created_at'];

    // Configure fieldsets for add/edit forms
    fieldsets = {
      'Personal Information': ['first_name', 'last_name', 'email', 'phone'],
      'Address': ['address', 'city', 'state', 'zip_code', 'country'],
      'Status': ['is_active'],
    };

    // Readonly fields for edit view
    readonlyFields = ['created_at', 'updated_at'];

    // Configure actions
    actions.addAll([
      AdminAction(
        name: 'activate_customers',
        description: 'Activate selected customers',
        function: activateCustomers,
      ),
      AdminAction(
        name: 'deactivate_customers',
        description: 'Deactivate selected customers',
        function: deactivateCustomers,
      ),
      AdminAction(
        name: 'export_customer_list',
        description: 'Export customer list to CSV',
        function: exportCustomerList,
      ),
    ]);
  }

  @override
  Future<List<Customer>> getQueryset({
    String? search,
    Map<String, dynamic> filters = const {},
    String? ordering,
    int? limit,
    int? offset,
  }) async {
    // Implementation would use QuerySet to fetch customers
    // For demo purposes, return mock data
    return [
      Customer()
        ..id = 1
        ..firstName = 'John'
        ..lastName = 'Doe'
        ..email = 'john.doe@example.com'
        ..phone = '+1-555-0123'
        ..address = '123 Main St'
        ..city = 'New York'
        ..state = 'NY'
        ..zipCode = '10001'
        ..country = 'US'
        ..isActive = true
        ..createdAt = DateTime.now().subtract(const Duration(days: 30)),
      Customer()
        ..id = 2
        ..firstName = 'Jane'
        ..lastName = 'Smith'
        ..email = 'jane.smith@example.com'
        ..phone = '+1-555-0456'
        ..address = '456 Oak Ave'
        ..city = 'Los Angeles'
        ..state = 'CA'
        ..zipCode = '90210'
        ..country = 'US'
        ..isActive = true
        ..createdAt = DateTime.now().subtract(const Duration(days: 15)),
      Customer()
        ..id = 3
        ..firstName = 'Bob'
        ..lastName = 'Johnson'
        ..email = 'bob.johnson@example.com'
        ..phone = '+1-555-0789'
        ..address = '789 Pine St'
        ..city = 'Chicago'
        ..state = 'IL'
        ..zipCode = '60601'
        ..country = 'US'
        ..isActive = false
        ..createdAt = DateTime.now().subtract(const Duration(days: 45)),
    ];
  }

  @override
  Future<Customer?> getObject(dynamic pk) async {
    final customers = await getQueryset();
    try {
      return customers.firstWhere((c) => c.id == int.parse(pk.toString()));
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Customer> createObject(Map<String, dynamic> data) async {
    final customer = Customer()
      ..firstName = data['first_name'] ?? ''
      ..lastName = data['last_name'] ?? ''
      ..email = data['email'] ?? ''
      ..phone = data['phone'] ?? ''
      ..address = data['address'] ?? ''
      ..city = data['city'] ?? ''
      ..state = data['state'] ?? ''
      ..zipCode = data['zip_code'] ?? ''
      ..country = data['country'] ?? 'US'
      ..isActive = data['is_active'] == true || data['is_active'] == 'true';

    // In real implementation, this would save to database
    await customer.save();
    return customer;
  }

  @override
  Future<Customer> updateObject(Customer instance, Map<String, dynamic> data) async {
    if (data.containsKey('first_name')) instance.firstName = data['first_name'];
    if (data.containsKey('last_name')) instance.lastName = data['last_name'];
    if (data.containsKey('email')) instance.email = data['email'];
    if (data.containsKey('phone')) instance.phone = data['phone'];
    if (data.containsKey('address')) instance.address = data['address'];
    if (data.containsKey('city')) instance.city = data['city'];
    if (data.containsKey('state')) instance.state = data['state'];
    if (data.containsKey('zip_code')) instance.zipCode = data['zip_code'];
    if (data.containsKey('country')) instance.country = data['country'];
    if (data.containsKey('is_active')) {
      instance.isActive = data['is_active'] == true || data['is_active'] == 'true';
    }

    // In real implementation, this would update in database
    await instance.save();
    return instance;
  }

  @override
  Future<void> deleteObject(Customer instance) async {
    // In real implementation, this would delete from database
    await instance.delete();
  }

  // Custom admin actions
  Future<void> activateCustomers(List<Customer> customers) async {
    for (final customer in customers) {
      customer.isActive = true;
      await customer.save();
    }
  }

  Future<void> deactivateCustomers(List<Customer> customers) async {
    for (final customer in customers) {
      customer.isActive = false;
      await customer.save();
    }
  }

  Future<void> exportCustomerList(List<Customer> customers) async {
    // In real implementation, this would generate a CSV file
    final csvData = StringBuffer();
    csvData.writeln('ID,Name,Email,Phone,City,State,Active');
    
    for (final customer in customers) {
      csvData.writeln(
        '${customer.id},"${customer.fullName}","${customer.email}",'
        '"${customer.phone}","${customer.city}","${customer.state}",'
        '${customer.isActive}'
      );
    }
    
    // Here you would save the CSV data to a file or return it to the user
    print('Exported ${customers.length} customers to CSV');
  }

  @override
  String getObjectName(Customer instance) {
    return instance.fullName;
  }

  @override
  String getAppLabel() {
    return 'shop';
  }
}