import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class CustomDataTable<T> extends StatefulWidget {
  final List<DataTableColumn<T>> columns;
  final List<T> data;
  final void Function(T)? onRowTap;
  final void Function(T)? onEdit;
  final void Function(T)? onDelete;
  final void Function(List<T>)? onBulkAction;
  final bool showActions;
  final bool showSelectAll;
  final bool sortable;
  final String? searchQuery;
  final Widget? emptyState;
  final Widget? loadingState;
  final bool isLoading;

  const CustomDataTable({
    super.key,
    required this.columns,
    required this.data,
    this.onRowTap,
    this.onEdit,
    this.onDelete,
    this.onBulkAction,
    this.showActions = true,
    this.showSelectAll = false,
    this.sortable = true,
    this.searchQuery,
    this.emptyState,
    this.loadingState,
    this.isLoading = false,
  });

  @override
  State<CustomDataTable<T>> createState() => _CustomDataTableState<T>();
}

class _CustomDataTableState<T> extends State<CustomDataTable<T>> {
  Set<T> selectedRows = {};
  String? sortColumn;
  bool sortAscending = true;

  List<T> get filteredData {
    if (widget.searchQuery == null || widget.searchQuery!.isEmpty) {
      return widget.data;
    }

    return widget.data.where((item) {
      return widget.columns.any((column) {
        final value = column.value(item);
        return value.toString().toLowerCase().contains(
              widget.searchQuery!.toLowerCase(),
            );
      });
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading && widget.loadingState != null) {
      return widget.loadingState!;
    }

    if (filteredData.isEmpty && widget.emptyState != null) {
      return widget.emptyState!;
    }

    return Column(
      children: [
        if (widget.showSelectAll && selectedRows.isNotEmpty)
          _buildBulkActions(),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: MediaQuery.of(context).size.width,
              ),
              child: DataTable(
                sortColumnIndex: sortColumn != null
                    ? widget.columns.indexWhere((col) => col.key == sortColumn)
                    : null,
                sortAscending: sortAscending,
                showCheckboxColumn: widget.showSelectAll,
                headingRowColor: WidgetStateProperty.all(
                  AppColors.backgroundLight,
                ),
                columns: _buildColumns(),
                rows: _buildRows(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<DataColumn> _buildColumns() {
    List<DataColumn> columns = widget.columns.map((col) {
      return DataColumn(
        label: Text(
          col.label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        onSort: widget.sortable
            ? (columnIndex, ascending) {
                setState(() {
                  sortColumn = col.key;
                  sortAscending = ascending;
                });
              }
            : null,
      );
    }).toList();

    if (widget.showActions) {
      columns.add(
        const DataColumn(
          label: Text(
            'Actions',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      );
    }

    return columns;
  }

  List<DataRow> _buildRows() {
    return filteredData.map((item) {
      final isSelected = selectedRows.contains(item);

      return DataRow(
        selected: isSelected,
        onSelectChanged: widget.showSelectAll
            ? (selected) {
                setState(() {
                  if (selected == true) {
                    selectedRows.add(item);
                  } else {
                    selectedRows.remove(item);
                  }
                });
              }
            : null,
        cells: [
          ...widget.columns.map((col) {
            return DataCell(
              col.cellBuilder?.call(item) ??
                  Text(
                    col.value(item).toString(),
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
              onTap:
                  widget.onRowTap != null ? () => widget.onRowTap!(item) : null,
            );
          }),
          if (widget.showActions) DataCell(_buildActionButtons(item)),
        ],
      );
    }).toList();
  }

  Widget _buildActionButtons(T item) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.onEdit != null)
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            onPressed: () => widget.onEdit!(item),
            tooltip: 'Edit',
            color: AppColors.primary,
          ),
        if (widget.onDelete != null)
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            onPressed: () => _showDeleteConfirmation(item),
            tooltip: 'Delete',
            color: AppColors.error,
          ),
      ],
    );
  }

  Widget _buildBulkActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.primary.withValues(alpha: 0.1),
      child: Row(
        children: [
          Text(
            '${selectedRows.length} selected',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () {
              if (widget.onBulkAction != null) {
                widget.onBulkAction!(selectedRows.toList());
              }
            },
            icon: const Icon(Icons.delete),
            label: const Text('Delete Selected'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {
              setState(() {
                selectedRows.clear();
              });
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(T item) {
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
              widget.onDelete!(item);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class DataTableColumn<T> {
  final String key;
  final String label;
  final dynamic Function(T) value;
  final Widget Function(T)? cellBuilder;
  final bool sortable;
  final double? width;

  const DataTableColumn({
    required this.key,
    required this.label,
    required this.value,
    this.cellBuilder,
    this.sortable = true,
    this.width,
  });
}
