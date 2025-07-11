import 'package:flutter/material.dart';
import '../widgets/common/data_table.dart';
import '../widgets/common/custom_text_field.dart';
import '../widgets/common/loading_button.dart';
import '../widgets/layout/admin_layout.dart';
import '../theme/app_theme.dart';

abstract class CrudModel {
  String get id;
  String get displayName;
  Map<String, dynamic> toJson();
  CrudModel copyWith(Map<String, dynamic> updates);
}

abstract class CrudField {
  final String key;
  final String label;
  final bool isRequired;
  final bool editable;
  final bool showInList;

  const CrudField({
    required this.key,
    required this.label,
    this.isRequired = false,
    this.editable = true,
    this.showInList = true,
  });

  Widget buildFormField(dynamic value, Function(dynamic) onChanged);
  Widget? buildListCell(dynamic value);
  String? validate(dynamic value);
  dynamic parseValue(String input);
}

class StringField extends CrudField {
  final int? maxLength;
  final bool multiline;

  const StringField({
    required super.key,
    required super.label,
    super.isRequired = false,
    super.editable = true,
    super.showInList = true,
    this.maxLength,
    this.multiline = false,
  });

  @override
  Widget buildFormField(dynamic value, Function(dynamic) onChanged) {
    final controller = TextEditingController(text: value?.toString() ?? '');

    if (multiline) {
      return CustomMultilineField(
        controller: controller,
        label: label,
        maxLength: maxLength,
        onChanged: onChanged,
        validator: validate,
      );
    }

    return CustomTextField(
      controller: controller,
      label: label,
      onChanged: onChanged,
      validator: validate,
    );
  }

  @override
  Widget? buildListCell(dynamic value) {
    final text = value?.toString() ?? '-';
    return Text(
      text.length > 50 ? '${text.substring(0, 50)}...' : text,
      style: const TextStyle(color: AppColors.textPrimary),
    );
  }

  @override
  String? validate(dynamic value) {
    if (isRequired && (value == null || value.toString().trim().isEmpty)) {
      return '$label is required';
    }
    if (maxLength != null &&
        value != null &&
        value.toString().length > maxLength!) {
      return '$label must be less than $maxLength characters';
    }
    return null;
  }

  @override
  dynamic parseValue(String input) => input;
}

class IntegerField extends CrudField {
  final int? min;
  final int? max;

  const IntegerField({
    required super.key,
    required super.label,
    super.isRequired = false,
    super.editable = true,
    super.showInList = true,
    this.min,
    this.max,
  });

  @override
  Widget buildFormField(dynamic value, Function(dynamic) onChanged) {
    final controller = TextEditingController(text: value?.toString() ?? '');

    return CustomTextField(
      controller: controller,
      label: label,
      keyboardType: TextInputType.number,
      onChanged: (v) => onChanged(parseValue(v)),
      validator: validate,
    );
  }

  @override
  Widget? buildListCell(dynamic value) {
    return Text(
      value?.toString() ?? '0',
      style: const TextStyle(color: AppColors.textPrimary),
    );
  }

  @override
  String? validate(dynamic value) {
    if (isRequired && value == null) {
      return '$label is required';
    }
    if (value != null && value is int) {
      if (min != null && value < min!) {
        return '$label must be at least $min';
      }
      if (max != null && value > max!) {
        return '$label must be at most $max';
      }
    }
    return null;
  }

  @override
  dynamic parseValue(String input) {
    return int.tryParse(input);
  }
}

class BooleanField extends CrudField {
  const BooleanField({
    required super.key,
    required super.label,
    super.isRequired = false,
    super.editable = true,
    super.showInList = true,
  });

  @override
  Widget buildFormField(dynamic value, Function(dynamic) onChanged) {
    return CheckboxListTile(
      title: Text(label),
      value: value == true,
      onChanged: editable ? (v) => onChanged(v ?? false) : null,
    );
  }

  @override
  Widget? buildListCell(dynamic value) {
    return Icon(
      value == true ? Icons.check_circle : Icons.cancel,
      color: value == true ? AppColors.success : AppColors.error,
      size: 20,
    );
  }

  @override
  String? validate(dynamic value) {
    return null; // Boolean fields don't need validation
  }

  @override
  dynamic parseValue(String input) {
    return input.toLowerCase() == 'true';
  }
}

class SelectField extends CrudField {
  final List<SelectOption> options;
  final bool multiple;

  const SelectField({
    required super.key,
    required super.label,
    required this.options,
    super.isRequired = false,
    super.editable = true,
    super.showInList = true,
    this.multiple = false,
  });

  @override
  Widget buildFormField(dynamic value, Function(dynamic) onChanged) {
    if (multiple) {
      // Handle multiple selection
      final selectedValues = value as List<String>? ?? [];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          ...options.map((option) {
            return CheckboxListTile(
              title: Text(option.label),
              value: selectedValues.contains(option.value),
              onChanged: editable
                  ? (selected) {
                      final newValues = List<String>.from(selectedValues);
                      if (selected == true) {
                        newValues.add(option.value);
                      } else {
                        newValues.remove(option.value);
                      }
                      onChanged(newValues);
                    }
                  : null,
            );
          }),
        ],
      );
    }

    return CustomDropdownField<String>(
      value: value as String?,
      label: label,
      items: options.map((option) {
        return DropdownMenuItem<String>(
          value: option.value,
          child: Text(option.label),
        );
      }).toList(),
      onChanged: editable ? onChanged : null,
      validator: validate,
    );
  }

  @override
  Widget? buildListCell(dynamic value) {
    if (multiple) {
      final values = value as List<String>? ?? [];
      if (values.isEmpty) return const Text('-');

      return Wrap(
        spacing: 4,
        children: values.take(3).map((v) {
          final option = options.firstWhere(
            (o) => o.value == v,
            orElse: () => SelectOption(v, v),
          );
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              option.label,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 10,
              ),
            ),
          );
        }).toList(),
      );
    }

    final option = options.firstWhere(
      (o) => o.value == value,
      orElse: () =>
          SelectOption(value?.toString() ?? '', value?.toString() ?? '-'),
    );

    return Text(
      option.label,
      style: const TextStyle(color: AppColors.textPrimary),
    );
  }

  @override
  String? validate(dynamic value) {
    if (required == true) {
      if (multiple) {
        final values = value as List<String>? ?? [];
        if (values.isEmpty) {
          return '$label is required';
        }
      } else if (value == null || value.toString().isEmpty) {
        return '$label is required';
      }
    }
    return null;
  }

  @override
  dynamic parseValue(String input) {
    return multiple ? [input] : input;
  }
}

class SelectOption {
  final String value;
  final String label;

  const SelectOption(this.value, this.label);
}

class DateTimeField extends CrudField {
  final bool dateOnly;

  const DateTimeField({
    required super.key,
    required super.label,
    super.isRequired = false,
    super.editable = true,
    super.showInList = true,
    this.dateOnly = false,
  });

  @override
  Widget buildFormField(dynamic value, Function(dynamic) onChanged) {
    if (dateOnly) {
      return CustomDateField(
        label: label,
        onChanged: onChanged,
        validator: validate,
      );
    }

    // For now, use date field for datetime too
    return CustomDateField(
      label: label,
      onChanged: onChanged,
      validator: validate,
    );
  }

  @override
  Widget? buildListCell(dynamic value) {
    if (value == null) return const Text('-');

    final date = value as DateTime;
    final formatted = dateOnly
        ? '${date.day}/${date.month}/${date.year}'
        : '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';

    return Text(
      formatted,
      style: const TextStyle(color: AppColors.textPrimary),
    );
  }

  @override
  String? validate(dynamic value) {
    if (required == true && value == null) {
      return '$label is required';
    }
    return null;
  }

  @override
  dynamic parseValue(String input) {
    return DateTime.tryParse(input);
  }
}

class CrudConfig<T extends CrudModel> {
  final String title;
  final String singularName;
  final String pluralName;
  final List<CrudField> fields;
  final List<String> searchableFields;
  final T Function(Map<String, dynamic>) fromJson;
  final Future<List<T>> Function() loadItems;
  final Future<T> Function(T) saveItem;
  final Future<void> Function(T) deleteItem;
  final Future<void> Function(List<T>) bulkDelete;

  const CrudConfig({
    required this.title,
    required this.singularName,
    required this.pluralName,
    required this.fields,
    required this.searchableFields,
    required this.fromJson,
    required this.loadItems,
    required this.saveItem,
    required this.deleteItem,
    required this.bulkDelete,
  });
}

class CrudScreen<T extends CrudModel> extends StatefulWidget {
  final CrudConfig<T> config;

  const CrudScreen({
    super.key,
    required this.config,
  });

  @override
  State<CrudScreen<T>> createState() => _CrudScreenState<T>();
}

class _CrudScreenState<T extends CrudModel> extends State<CrudScreen<T>> {
  final TextEditingController _searchController = TextEditingController();
  List<T> _items = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final items = await widget.config.loadItems();
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error loading ${widget.config.pluralName}: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: widget.config.title,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadItems,
          tooltip: 'Refresh',
        ),
        ElevatedButton.icon(
          onPressed: () => _showItemForm(),
          icon: const Icon(Icons.add),
          label: Text('Add ${widget.config.singularName}'),
        ),
      ],
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildDataTable()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: CustomSearchField(
        controller: _searchController,
        hint: 'Search ${widget.config.pluralName.toLowerCase()}...',
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildDataTable() {
    final columns =
        widget.config.fields.where((field) => field.showInList).map((field) {
      return DataTableColumn<T>(
        key: field.key,
        label: field.label,
        value: (item) => _getFieldValue(item, field.key),
        cellBuilder: (item) {
          final value = _getFieldValue(item, field.key);
          return field.buildListCell(value) ?? Text(value?.toString() ?? '');
        },
      );
    }).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: CustomDataTable<T>(
        columns: columns,
        data: _items,
        searchQuery: _searchQuery,
        isLoading: _isLoading,
        showSelectAll: true,
        onRowTap: (item) => _showItemForm(item: item),
        onEdit: (item) => _showItemForm(item: item),
        onDelete: (item) => _deleteItem(item),
        onBulkAction: (items) => _bulkDeleteItems(items),
        emptyState: _buildEmptyState(),
        loadingState: const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(64),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.inbox_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No ${widget.config.pluralName.toLowerCase()} found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showItemForm(),
            icon: const Icon(Icons.add),
            label: Text('Add ${widget.config.singularName}'),
          ),
        ],
      ),
    );
  }

  void _showItemForm({T? item}) {
    showDialog(
      context: context,
      builder: (context) => CrudFormDialog<T>(
        config: widget.config,
        item: item,
        onSave: (savedItem) async {
          try {
            final result = await widget.config.saveItem(savedItem);
            setState(() {
              if (item != null) {
                final index = _items.indexWhere((i) => i.id == item.id);
                if (index != -1) {
                  _items[index] = result;
                }
              } else {
                _items.add(result);
              }
            });
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                      Text('Error saving ${widget.config.singularName}: $e')),
            );
          }
        },
      ),
    );
  }

  Future<void> _deleteItem(T item) async {
    try {
      await widget.config.deleteItem(item);
      setState(() {
        _items.removeWhere((i) => i.id == item.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.config.singularName} deleted'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              setState(() {
                _items.add(item);
              });
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error deleting ${widget.config.singularName}: $e')),
      );
    }
  }

  Future<void> _bulkDeleteItems(List<T> items) async {
    try {
      await widget.config.bulkDelete(items);
      setState(() {
        _items.removeWhere((item) => items.contains(item));
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '${items.length} ${widget.config.pluralName.toLowerCase()} deleted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error deleting ${widget.config.pluralName}: $e')),
      );
    }
  }

  dynamic _getFieldValue(T item, String fieldKey) {
    final json = item.toJson();
    return json[fieldKey];
  }
}

class CrudFormDialog<T extends CrudModel> extends StatefulWidget {
  final CrudConfig<T> config;
  final T? item;
  final Function(T) onSave;

  const CrudFormDialog({
    super.key,
    required this.config,
    this.item,
    required this.onSave,
  });

  @override
  State<CrudFormDialog<T>> createState() => _CrudFormDialogState<T>();
}

class _CrudFormDialogState<T extends CrudModel>
    extends State<CrudFormDialog<T>> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _formData = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _formData.addAll(widget.item!.toJson());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item != null
          ? 'Edit ${widget.config.singularName}'
          : 'Add ${widget.config.singularName}'),
      content: SizedBox(
        width: 500,
        height: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: widget.config.fields
                  .where((field) => field.editable)
                  .map((field) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: field.buildFormField(
                          _formData[field.key],
                          (value) {
                            setState(() {
                              _formData[field.key] = value;
                            });
                          },
                        ),
                      ))
                  .toList(),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        LoadingButton(
          onPressed: _isLoading ? null : _handleSave,
          isLoading: _isLoading,
          child: Text(widget.item != null ? 'Update' : 'Create'),
        ),
      ],
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      T item;
      if (widget.item != null) {
        item = widget.item!.copyWith(_formData) as T;
      } else {
        item = widget.config.fromJson(_formData);
      }

      widget.onSave(item);

      if (mounted) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
