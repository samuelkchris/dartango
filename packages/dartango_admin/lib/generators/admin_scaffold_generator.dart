import 'dart:async';
import 'dart:convert';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:yaml/yaml.dart';

/// Generator for creating admin scaffolding code
Builder adminScaffoldGenerator(BuilderOptions options) {
  return AdminScaffoldBuilder();
}

class AdminScaffoldBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => {
    '.admin.yaml': ['.admin.dart']
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final inputId = buildStep.inputId;
    final contents = await buildStep.readAsString(inputId);
    
    try {
      final yamlDoc = loadYaml(contents) as Map;
      final config = AdminConfig.fromYaml(yamlDoc);
      
      final generatedCode = _generateAdminCode(config);
      final outputId = inputId.changeExtension('.admin.dart');
      
      await buildStep.writeAsString(outputId, generatedCode);
    } catch (e) {
      print('Error generating admin code for ${inputId.path}: $e');
    }
  }

  String _generateAdminCode(AdminConfig config) {
    final buffer = StringBuffer();
    
    // File header
    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    buffer.writeln('// Generated from ${config.name}.admin.yaml');
    buffer.writeln();
    
    // Imports
    buffer.writeln('import \'package:flutter/material.dart\';');
    buffer.writeln('import \'package:flutter_bloc/flutter_bloc.dart\';');
    buffer.writeln('import \'package:flutter_form_builder/flutter_form_builder.dart\';');
    buffer.writeln('import \'package:form_builder_validators/form_builder_validators.dart\';');
    buffer.writeln();
    buffer.writeln('import \'../blocs/models/models_bloc.dart\';');
    buffer.writeln('import \'../models/admin_models.dart\';');
    buffer.writeln('import \'../widgets/common/data_table.dart\';');
    buffer.writeln('import \'../widgets/common/loading_button.dart\';');
    buffer.writeln();
    
    // Generate list screen
    buffer.writeln(_generateListScreen(config));
    buffer.writeln();
    
    // Generate detail screen
    buffer.writeln(_generateDetailScreen(config));
    buffer.writeln();
    
    // Generate form screen
    buffer.writeln(_generateFormScreen(config));
    buffer.writeln();
    
    // Generate model class
    buffer.writeln(_generateModelClass(config));
    
    return buffer.toString();
  }

  String _generateListScreen(AdminConfig config) {
    final className = '${config.name}ListScreen';
    final modelName = config.name.toLowerCase();
    
    return '''
class $className extends StatelessWidget {
  final String appLabel = '${config.appLabel}';
  final String modelName = '$modelName';

  const $className({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${config.verboseNamePlural}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToAdd(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshList(context),
          ),
        ],
      ),
      body: BlocBuilder<ModelsBloc, ModelsState>(
        builder: (context, state) {
          if (state.listLoading && state.modelList.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.listError != null && state.modelList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: \${state.listError}'),
                  ElevatedButton(
                    onPressed: () => _refreshList(context),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              if (state.hasSelection) _buildBulkActionsBar(context, state),
              Expanded(
                child: AdminDataTable<Map<String, dynamic>>(
                  items: state.modelList,
                  columns: _buildColumns(),
                  onRowTap: (item) => _navigateToDetail(context, item['id'].toString()),
                  selectable: true,
                  selectedItems: state.selectedItems,
                  onSelectionChanged: (id, selected) {
                    context.read<ModelsBloc>().toggleItemSelection(id);
                  },
                  loading: state.listLoading,
                ),
              ),
              if (state.totalPages > 1) _buildPagination(context, state),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAdd(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  List<DataColumn> _buildColumns() {
    return [
${config.listDisplay.map((field) => "      DataColumn(label: Text('${_humanize(field)}')),").join('\n')}
    ];
  }

  Widget _buildBulkActionsBar(BuildContext context, ModelsState state) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Row(
        children: [
          Text('\${state.selectedCount} selected'),
          const Spacer(),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete),
            label: const Text('Delete Selected'),
            onPressed: () => _confirmBulkDelete(context, state.selectedIds),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination(BuildContext context, ModelsState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: state.canLoadPrevious ? () => _loadPage(context, state.currentPage - 1) : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Text('Page \${state.currentPage} of \${state.totalPages}'),
        IconButton(
          onPressed: state.canLoadMore ? () => _loadPage(context, state.currentPage + 1) : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  void _navigateToDetail(BuildContext context, String id) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ${config.name}DetailScreen(id: id),
      ),
    );
  }

  void _navigateToAdd(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ${config.name}FormScreen(),
      ),
    );
  }

  void _refreshList(BuildContext context) {
    context.read<ModelsBloc>().add(
      ModelsEvent.loadModelList(appLabel, modelName),
    );
  }

  void _loadPage(BuildContext context, int page) {
    context.read<ModelsBloc>().add(
      ModelsEvent.loadModelList(appLabel, modelName, page: page),
    );
  }

  void _confirmBulkDelete(BuildContext context, List<String> ids) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete \${ids.length} items?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ModelsBloc>().add(
                ModelsEvent.bulkDeleteModels(appLabel, modelName, ids),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}''';
  }

  String _generateDetailScreen(AdminConfig config) {
    final className = '${config.name}DetailScreen';
    
    return '''
class $className extends StatelessWidget {
  final String id;

  const $className({Key? key, required this.id}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${config.verboseName} Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _navigateToEdit(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: BlocBuilder<ModelsBloc, ModelsState>(
        builder: (context, state) {
          if (state.detailLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.detailError != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: \${state.detailError}'),
                  ElevatedButton(
                    onPressed: () => _loadDetail(context),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final item = state.modelDetail;
          if (item == null) {
            return const Center(child: Text('No data available'));
          }

          return _buildDetailView(item);
        },
      ),
    );
  }

  Widget _buildDetailView(Map<String, dynamic> item) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
${config.fieldsets.entries.map((fieldset) => '''
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${fieldset.key}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
${fieldset.value.map((field) => '''
                _buildDetailField('${_humanize(field)}', item['$field']),''').join('\n')}
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),''').join('\n')}
      ],
    );
  }

  Widget _buildDetailField(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value?.toString() ?? 'N/A'),
          ),
        ],
      ),
    );
  }

  void _navigateToEdit(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ${config.name}FormScreen(id: id),
      ),
    );
  }

  void _loadDetail(BuildContext context) {
    context.read<ModelsBloc>().add(
      ModelsEvent.loadModelDetail('${config.appLabel}', '${config.name.toLowerCase()}', id),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ModelsBloc>().add(
                ModelsEvent.deleteModel('${config.appLabel}', '${config.name.toLowerCase()}', id),
              );
              Navigator.pop(context); // Go back to list
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}''';
  }

  String _generateFormScreen(AdminConfig config) {
    final className = '${config.name}FormScreen';
    
    return '''
class $className extends StatefulWidget {
  final String? id; // null for create, set for edit

  const $className({Key? key, this.id}) : super(key: key);

  @override
  _${className}State createState() => _${className}State();
}

class _${className}State extends State<$className> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  void initState() {
    super.initState();
    if (widget.id != null) {
      // Load existing data for editing
      context.read<ModelsBloc>().add(
        ModelsEvent.loadModelDetail('${config.appLabel}', '${config.name.toLowerCase()}', widget.id!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.id == null ? 'Add ${config.verboseName}' : 'Edit ${config.verboseName}'),
        actions: [
          LoadingButton(
            onPressed: _saveForm,
            icon: const Icon(Icons.save),
            label: const Text('Save'),
          ),
        ],
      ),
      body: BlocConsumer<ModelsBloc, ModelsState>(
        listener: (context, state) {
          if (state.saveSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Saved successfully')),
            );
            Navigator.pop(context);
          } else if (state.saveError != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: \${state.saveError}')),
            );
          }
        },
        builder: (context, state) {
          if (state.detailLoading && widget.id != null) {
            return const Center(child: CircularProgressIndicator());
          }

          return _buildForm(state);
        },
      ),
    );
  }

  Widget _buildForm(ModelsState state) {
    final initialData = widget.id != null ? state.modelDetail : <String, dynamic>{};

    return FormBuilder(
      key: _formKey,
      initialValue: initialData ?? {},
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
${config.fieldsets.entries.map((fieldset) => '''
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${fieldset.key}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
${fieldset.value.map((field) => _generateFormField(field, config)).join('\n')}
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),''').join('\n')}
        ],
      ),
    );
  }

  void _saveForm() {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final formData = _formKey.currentState!.value;
      
      if (widget.id == null) {
        // Create new
        context.read<ModelsBloc>().add(
          ModelsEvent.createModel('${config.appLabel}', '${config.name.toLowerCase()}', formData),
        );
      } else {
        // Update existing
        context.read<ModelsBloc>().add(
          ModelsEvent.updateModel('${config.appLabel}', '${config.name.toLowerCase()}', widget.id!, formData),
        );
      }
    }
  }
}''';
  }

  String _generateFormField(String fieldName, AdminConfig config) {
    final fieldConfig = config.fields[fieldName];
    final fieldType = fieldConfig?.type ?? 'text';
    final isRequired = fieldConfig?.required ?? false;
    final isReadonly = config.readonlyFields.contains(fieldName);
    
    final validators = <String>[];
    if (isRequired) validators.add('FormBuilderValidators.required()');
    if (fieldType == 'email') validators.add('FormBuilderValidators.email()');
    
    final validatorString = validators.isNotEmpty 
        ? 'validator: FormBuilderValidators.compose([${validators.join(', ')}]),'
        : '';

    switch (fieldType) {
      case 'boolean':
        return '''
                  FormBuilderCheckbox(
                    name: '$fieldName',
                    title: Text('${_humanize(fieldName)}'),
                    enabled: ${!isReadonly},
                    $validatorString
                  ),
                  const SizedBox(height: 16),''';
      
      case 'choice':
        final choices = fieldConfig?.choices ?? {};
        final choiceItems = choices.entries
            .map((e) => 'DropdownMenuItem(value: \'${e.key}\', child: Text(\'${e.value}\'))')
            .join(', ');
        
        return '''
                  FormBuilderDropdown(
                    name: '$fieldName',
                    decoration: InputDecoration(labelText: '${_humanize(fieldName)}'),
                    enabled: ${!isReadonly},
                    items: [$choiceItems],
                    $validatorString
                  ),
                  const SizedBox(height: 16),''';
      
      case 'text':
        return '''
                  FormBuilderTextField(
                    name: '$fieldName',
                    decoration: InputDecoration(labelText: '${_humanize(fieldName)}'),
                    maxLines: 4,
                    enabled: ${!isReadonly},
                    $validatorString
                  ),
                  const SizedBox(height: 16),''';
      
      case 'integer':
      case 'float':
        return '''
                  FormBuilderTextField(
                    name: '$fieldName',
                    decoration: InputDecoration(labelText: '${_humanize(fieldName)}'),
                    keyboardType: TextInputType.number,
                    enabled: ${!isReadonly},
                    $validatorString
                  ),
                  const SizedBox(height: 16),''';
      
      case 'datetime':
        return '''
                  FormBuilderDateTimePicker(
                    name: '$fieldName',
                    decoration: InputDecoration(labelText: '${_humanize(fieldName)}'),
                    enabled: ${!isReadonly},
                    $validatorString
                  ),
                  const SizedBox(height: 16),''';
      
      case 'date':
        return '''
                  FormBuilderDateTimePicker(
                    name: '$fieldName',
                    inputType: InputType.date,
                    decoration: InputDecoration(labelText: '${_humanize(fieldName)}'),
                    enabled: ${!isReadonly},
                    $validatorString
                  ),
                  const SizedBox(height: 16),''';
      
      default:
        return '''
                  FormBuilderTextField(
                    name: '$fieldName',
                    decoration: InputDecoration(labelText: '${_humanize(fieldName)}'),
                    enabled: ${!isReadonly},
                    $validatorString
                  ),
                  const SizedBox(height: 16),''';
    }
  }

  String _generateModelClass(AdminConfig config) {
    return '''
/// Generated model class for ${config.name}
class ${config.name}Model {
  ${config.fields.entries.map((field) => 'final ${_getDartType(field.value.type)} ${field.key};').join('\n  ')}

  ${config.name}Model({
    ${config.fields.entries.map((field) => '${field.value.required ? 'required ' : ''}this.${field.key},').join('\n    ')}
  });

  factory ${config.name}Model.fromJson(Map<String, dynamic> json) {
    return ${config.name}Model(
      ${config.fields.entries.map((field) => '${field.key}: json[\'${field.key}\'],').join('\n      ')}
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ${config.fields.entries.map((field) => '\'${field.key}\': ${field.key},').join('\n      ')}
    };
  }
}''';
  }

  String _humanize(String input) {
    return input
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (match) => '${match.group(1)} ${match.group(2)}')
        .replaceAll('_', ' ')
        .toLowerCase()
        .split(' ')
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : word)
        .join(' ');
  }

  String _getDartType(String fieldType) {
    switch (fieldType) {
      case 'boolean':
        return 'bool?';
      case 'integer':
        return 'int?';
      case 'float':
        return 'double?';
      case 'datetime':
      case 'date':
        return 'DateTime?';
      default:
        return 'String?';
    }
  }
}

/// Configuration class for admin generation
class AdminConfig {
  final String name;
  final String appLabel;
  final String verboseName;
  final String verboseNamePlural;
  final List<String> listDisplay;
  final List<String> listFilter;
  final List<String> searchFields;
  final List<String> readonlyFields;
  final Map<String, List<String>> fieldsets;
  final Map<String, FieldConfig> fields;

  AdminConfig({
    required this.name,
    required this.appLabel,
    required this.verboseName,
    required this.verboseNamePlural,
    required this.listDisplay,
    required this.listFilter,
    required this.searchFields,
    required this.readonlyFields,
    required this.fieldsets,
    required this.fields,
  });

  factory AdminConfig.fromYaml(Map yamlMap) {
    final fields = <String, FieldConfig>{};
    final yamlFields = yamlMap['fields'] as Map? ?? {};
    
    for (final entry in yamlFields.entries) {
      fields[entry.key] = FieldConfig.fromYaml(entry.value);
    }

    return AdminConfig(
      name: yamlMap['name'] as String,
      appLabel: yamlMap['app_label'] as String,
      verboseName: yamlMap['verbose_name'] as String,
      verboseNamePlural: yamlMap['verbose_name_plural'] as String,
      listDisplay: List<String>.from(yamlMap['list_display'] ?? []),
      listFilter: List<String>.from(yamlMap['list_filter'] ?? []),
      searchFields: List<String>.from(yamlMap['search_fields'] ?? []),
      readonlyFields: List<String>.from(yamlMap['readonly_fields'] ?? []),
      fieldsets: _parseFieldsets(yamlMap['fieldsets']),
      fields: fields,
    );
  }

  static Map<String, List<String>> _parseFieldsets(dynamic fieldsets) {
    if (fieldsets is Map) {
      return fieldsets.map((key, value) => MapEntry(key.toString(), List<String>.from(value)));
    }
    return {};
  }
}

class FieldConfig {
  final String type;
  final bool required;
  final Map<String, dynamic> choices;

  FieldConfig({
    required this.type,
    required this.required,
    required this.choices,
  });

  factory FieldConfig.fromYaml(dynamic yaml) {
    if (yaml is Map) {
      return FieldConfig(
        type: yaml['type'] as String? ?? 'text',
        required: yaml['required'] as bool? ?? false,
        choices: Map<String, dynamic>.from(yaml['choices'] ?? {}),
      );
    }
    return FieldConfig(type: 'text', required: false, choices: {});
  }
}