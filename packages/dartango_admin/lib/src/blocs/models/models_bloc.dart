import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../models/admin_models.dart';
import '../../repositories/admin_repository.dart';

part 'models_event.dart';
part 'models_state.dart';
part 'models_bloc.freezed.dart';

/// Model management BLoC for admin interface
class ModelsBloc extends Bloc<ModelsEvent, ModelsState> {
  final AdminRepository _repository;

  ModelsBloc({required AdminRepository repository})
      : _repository = repository,
        super(const ModelsState.initial()) {
    on<ModelsEvent>(
      (event, emit) async {
        await event.when(
          loadApps: () => _onLoadApps(emit),
          loadModelList: (app, model, page, search, filters) =>
              _onLoadModelList(app, model, page, search, filters, emit),
          loadModelDetail: (app, model, id) =>
              _onLoadModelDetail(app, model, id, emit),
          createModel: (app, model, data) =>
              _onCreateModel(app, model, data, emit),
          updateModel: (app, model, id, data) =>
              _onUpdateModel(app, model, id, data, emit),
          deleteModel: (app, model, id) =>
              _onDeleteModel(app, model, id, emit),
          bulkDeleteModels: (app, model, ids) =>
              _onBulkDeleteModels(app, model, ids, emit),
          refreshModelList: () => _onRefreshModelList(emit),
          clearModelDetail: () => _onClearModelDetail(emit),
          setCurrentApp: (app) => _onSetCurrentApp(app, emit),
          setCurrentModel: (model) => _onSetCurrentModel(model, emit),
        );
      },
    );
  }

  Future<void> _onLoadApps(Emitter<ModelsState> emit) async {
    emit(state.copyWith(appsLoading: true, appsError: null));

    try {
      final response = await _repository.getAppsList();
      emit(state.copyWith(
        apps: response.apps,
        appsLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        appsLoading: false,
        appsError: _getErrorMessage(e),
      ));
    }
  }

  Future<void> _onLoadModelList(
    String app,
    String model,
    int? page,
    String? search,
    Map<String, dynamic>? filters,
    Emitter<ModelsState> emit,
  ) async {
    emit(state.copyWith(
      listLoading: true,
      listError: null,
      currentApp: app,
      currentModel: model,
    ));

    try {
      final response = await _repository.getModelList<Map<String, dynamic>>(
        app,
        model,
        page: page,
        search: search,
        filters: filters,
      );

      emit(state.copyWith(
        modelList: response.results,
        totalCount: response.count,
        currentPage: page ?? 1,
        totalPages: response.totalPages ?? 1,
        hasNext: response.next != null,
        hasPrevious: response.previous != null,
        listLoading: false,
        searchQuery: search,
        appliedFilters: filters ?? {},
      ));
    } catch (e) {
      emit(state.copyWith(
        listLoading: false,
        listError: _getErrorMessage(e),
      ));
    }
  }

  Future<void> _onLoadModelDetail(
    String app,
    String model,
    String id,
    Emitter<ModelsState> emit,
  ) async {
    emit(state.copyWith(
      detailLoading: true,
      detailError: null,
    ));

    try {
      final response = await _repository.getModelDetail<Map<String, dynamic>>(
        app,
        model,
        id,
      );

      emit(state.copyWith(
        modelDetail: response.object,
        detailLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        detailLoading: false,
        detailError: _getErrorMessage(e),
      ));
    }
  }

  Future<void> _onCreateModel(
    String app,
    String model,
    Map<String, dynamic> data,
    Emitter<ModelsState> emit,
  ) async {
    emit(state.copyWith(
      saving: true,
      saveError: null,
    ));

    try {
      final response = await _repository.createModel<Map<String, dynamic>>(
        app,
        model,
        data,
      );

      // Add the new model to the list if we're on the first page
      if (state.currentPage == 1) {
        final updatedList = [response.object, ...state.modelList];
        emit(state.copyWith(
          modelList: updatedList,
          totalCount: state.totalCount + 1,
          saving: false,
          saveSuccess: true,
        ));
      } else {
        emit(state.copyWith(
          saving: false,
          saveSuccess: true,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        saving: false,
        saveError: _getErrorMessage(e),
      ));
    }
  }

  Future<void> _onUpdateModel(
    String app,
    String model,
    String id,
    Map<String, dynamic> data,
    Emitter<ModelsState> emit,
  ) async {
    emit(state.copyWith(
      saving: true,
      saveError: null,
    ));

    try {
      final response = await _repository.updateModel<Map<String, dynamic>>(
        app,
        model,
        id,
        data,
      );

      // Update the model in the list
      final updatedList = state.modelList.map((item) {
        if (item['id'] == id) {
          return response.object;
        }
        return item;
      }).toList();

      emit(state.copyWith(
        modelList: updatedList,
        modelDetail: response.object,
        saving: false,
        saveSuccess: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        saving: false,
        saveError: _getErrorMessage(e),
      ));
    }
  }

  Future<void> _onDeleteModel(
    String app,
    String model,
    String id,
    Emitter<ModelsState> emit,
  ) async {
    emit(state.copyWith(
      deleting: true,
      deleteError: null,
    ));

    try {
      await _repository.deleteModel(app, model, id);

      // Remove the model from the list
      final updatedList = state.modelList
          .where((item) => item['id'].toString() != id)
          .toList();

      emit(state.copyWith(
        modelList: updatedList,
        totalCount: state.totalCount - 1,
        deleting: false,
        deleteSuccess: true,
        modelDetail: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        deleting: false,
        deleteError: _getErrorMessage(e),
      ));
    }
  }

  Future<void> _onBulkDeleteModels(
    String app,
    String model,
    List<String> ids,
    Emitter<ModelsState> emit,
  ) async {
    emit(state.copyWith(
      bulkDeleting: true,
      bulkDeleteError: null,
    ));

    try {
      final request = BulkDeleteRequest(ids: ids);
      final response = await _repository.bulkDeleteModels(app, model, request);

      // Remove the models from the list
      final updatedList = state.modelList
          .where((item) => !ids.contains(item['id'].toString()))
          .toList();

      emit(state.copyWith(
        modelList: updatedList,
        totalCount: state.totalCount - response.deleted,
        bulkDeleting: false,
        bulkDeleteSuccess: true,
        selectedItems: {},
      ));
    } catch (e) {
      emit(state.copyWith(
        bulkDeleting: false,
        bulkDeleteError: _getErrorMessage(e),
      ));
    }
  }

  Future<void> _onRefreshModelList(Emitter<ModelsState> emit) async {
    if (state.currentApp != null && state.currentModel != null) {
      await _onLoadModelList(
        state.currentApp!,
        state.currentModel!,
        state.currentPage,
        state.searchQuery,
        state.appliedFilters,
        emit,
      );
    }
  }

  void _onClearModelDetail(Emitter<ModelsState> emit) {
    emit(state.copyWith(
      modelDetail: null,
      detailError: null,
      saveSuccess: false,
      deleteSuccess: false,
    ));
  }

  void _onSetCurrentApp(String app, Emitter<ModelsState> emit) {
    emit(state.copyWith(
      currentApp: app,
      currentModel: null,
      modelList: [],
      modelDetail: null,
    ));
  }

  void _onSetCurrentModel(String model, Emitter<ModelsState> emit) {
    emit(state.copyWith(
      currentModel: model,
      modelList: [],
      modelDetail: null,
    ));
  }

  String _getErrorMessage(dynamic error) {
    if (error is AdminApiError) {
      return error.message;
    }
    return 'An unexpected error occurred. Please try again.';
  }

  /// Toggle item selection for bulk operations
  void toggleItemSelection(String id) {
    final selectedItems = Map<String, bool>.from(state.selectedItems);
    selectedItems[id] = !(selectedItems[id] ?? false);
    
    emit(state.copyWith(selectedItems: selectedItems));
  }

  /// Select all items
  void selectAllItems() {
    final selectedItems = <String, bool>{};
    for (final item in state.modelList) {
      selectedItems[item['id'].toString()] = true;
    }
    
    emit(state.copyWith(selectedItems: selectedItems));
  }

  /// Clear all selections
  void clearSelection() {
    emit(state.copyWith(selectedItems: {}));
  }

  /// Get selected item IDs
  List<String> get selectedItemIds {
    return state.selectedItems.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
  }

  /// Check if item is selected
  bool isItemSelected(String id) {
    return state.selectedItems[id] ?? false;
  }

  /// Get selection count
  int get selectionCount {
    return state.selectedItems.values.where((selected) => selected).length;
  }
}