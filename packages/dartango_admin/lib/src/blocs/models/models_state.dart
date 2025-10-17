part of 'models_bloc.dart';

/// Model management state
@freezed
class ModelsState with _$ModelsState {
  const factory ModelsState({
    // Apps loading
    @Default([]) List<AdminApp> apps,
    @Default(false) bool appsLoading,
    String? appsError,
    
    // Current selection
    String? currentApp,
    String? currentModel,
    
    // Model list
    @Default([]) List<Map<String, dynamic>> modelList,
    @Default(false) bool listLoading,
    String? listError,
    
    // Pagination
    @Default(0) int totalCount,
    @Default(1) int currentPage,
    @Default(1) int totalPages,
    @Default(false) bool hasNext,
    @Default(false) bool hasPrevious,
    
    // Search and filters
    String? searchQuery,
    @Default({}) Map<String, dynamic> appliedFilters,
    
    // Model detail
    Map<String, dynamic>? modelDetail,
    @Default(false) bool detailLoading,
    String? detailError,
    
    // CRUD operations
    @Default(false) bool saving,
    @Default(false) bool saveSuccess,
    String? saveError,
    
    @Default(false) bool deleting,
    @Default(false) bool deleteSuccess,
    String? deleteError,
    
    // Bulk operations
    @Default(false) bool bulkDeleting,
    @Default(false) bool bulkDeleteSuccess,
    String? bulkDeleteError,
    
    // Selection state
    @Default({}) Map<String, bool> selectedItems,
  }) = _ModelsState;
  
  const factory ModelsState.initial() = _ModelsStateInitial;
}

/// Extension methods for ModelsState
extension ModelsStateX on ModelsState {
  bool get hasData => modelList.isNotEmpty;
  bool get isEmpty => modelList.isEmpty && !listLoading;
  bool get isLoading => listLoading || appsLoading || detailLoading;
  bool get hasError => listError != null || appsError != null || detailError != null;
  
  String? get anyError => listError ?? appsError ?? detailError ?? saveError ?? deleteError ?? bulkDeleteError;
  
  bool get canLoadMore => hasNext && !listLoading;
  bool get canLoadPrevious => hasPrevious && !listLoading;
  
  int get selectedCount => selectedItems.values.where((selected) => selected).length;
  bool get hasSelection => selectedCount > 0;
  bool get isAllSelected => selectedCount == modelList.length && modelList.isNotEmpty;
  
  List<String> get selectedIds => selectedItems.entries
      .where((entry) => entry.value)
      .map((entry) => entry.key)
      .toList();
      
  AdminApp? get currentAppData => apps.firstWhereOrNull((app) => app.appLabel == currentApp);
  
  AdminModel? get currentModelData {
    final app = currentAppData;
    if (app == null || currentModel == null) return null;
    return app.models.firstWhereOrNull((model) => model.objectName.toLowerCase() == currentModel);
  }
}

extension ListExtension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}