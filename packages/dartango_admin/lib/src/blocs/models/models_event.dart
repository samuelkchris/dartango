part of 'models_bloc.dart';

/// Model management events
@freezed
class ModelsEvent with _$ModelsEvent {
  /// Load all available apps
  const factory ModelsEvent.loadApps() = ModelsLoadApps;
  
  /// Load model list for specific app and model
  const factory ModelsEvent.loadModelList(
    String app,
    String model, {
    int? page,
    String? search,
    Map<String, dynamic>? filters,
  }) = ModelsLoadModelList;
  
  /// Load model detail
  const factory ModelsEvent.loadModelDetail(
    String app,
    String model,
    String id,
  ) = ModelsLoadModelDetail;
  
  /// Create new model instance
  const factory ModelsEvent.createModel(
    String app,
    String model,
    Map<String, dynamic> data,
  ) = ModelsCreateModel;
  
  /// Update existing model instance
  const factory ModelsEvent.updateModel(
    String app,
    String model,
    String id,
    Map<String, dynamic> data,
  ) = ModelsUpdateModel;
  
  /// Delete model instance
  const factory ModelsEvent.deleteModel(
    String app,
    String model,
    String id,
  ) = ModelsDeleteModel;
  
  /// Bulk delete multiple models
  const factory ModelsEvent.bulkDeleteModels(
    String app,
    String model,
    List<String> ids,
  ) = ModelsBulkDeleteModels;
  
  /// Refresh current model list
  const factory ModelsEvent.refreshModelList() = ModelsRefreshModelList;
  
  /// Clear model detail
  const factory ModelsEvent.clearModelDetail() = ModelsClearModelDetail;
  
  /// Set current app
  const factory ModelsEvent.setCurrentApp(String app) = ModelsSetCurrentApp;
  
  /// Set current model
  const factory ModelsEvent.setCurrentModel(String model) = ModelsSetCurrentModel;
}