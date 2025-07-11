import 'package:test/test.dart';
import 'package:dartango/src/core/database/models.dart';

// Simple test model
class SimpleModel extends Model {
  SimpleModel();

  SimpleModel.fromMap(Map<String, dynamic> data) : super.fromMap(data);

  @override
  ModelMeta get meta => const ModelMeta(tableName: 'simple_models');

  String get name => getField('name') ?? '';
  set name(String value) => setField('name', value);
}

void main() {
  test('Test Model creation and fromMap', () async {
    print('Step 1: Creating empty model...');

    print('Empty model created');

    print('Step 2: Creating model from map...');

    final data = {'id': 1, 'name': 'Test'};
    print('About to call SimpleModel.fromMap with data: $data');

    final model2 = SimpleModel.fromMap(data);
    print('Model created from map');
    print('Model name: ${model2.name}');

    expect(model2.name, equals('Test'));
  });
}
