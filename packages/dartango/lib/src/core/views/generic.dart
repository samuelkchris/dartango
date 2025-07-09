import 'dart:async';
import 'dart:convert';

import '../http/request.dart';
import '../http/response.dart';
import '../exceptions/http.dart';
import '../database/models.dart';
import '../database/queryset.dart';
import '../templates/engine.dart';
import '../templates/context.dart';
import 'base.dart';

abstract class GenericView extends View {
  Model? model;
  QuerySet? queryset;
  String? contextObjectName;
  Map<String, dynamic>? extraContext;
  
  GenericView({
    this.model,
    this.queryset,
    this.contextObjectName,
    this.extraContext,
  });
  
  QuerySet getQueryset() {
    if (queryset != null) {
      return queryset!;
    }
    
    if (model != null) {
      return (model as dynamic).objects.all();
    }
    
    throw ViewException('GenericView requires either a model or queryset');
  }
  
  String getContextObjectName() {
    if (contextObjectName != null) {
      return contextObjectName!;
    }
    
    if (model != null) {
      return model!.runtimeType.toString().toLowerCase();
    }
    
    return 'object';
  }
  
  Map<String, dynamic> getContext(HttpRequest request, Map<String, dynamic> kwargs) {
    final context = <String, dynamic>{
      'view': this,
      'request': request,
    };
    
    context.addAll(kwargs);
    
    if (extraContext != null) {
      context.addAll(extraContext!);
    }
    
    context.addAll(getContextData(request, kwargs));
    
    return context;
  }
  
  Map<String, dynamic> getContextData(HttpRequest request, Map<String, dynamic> kwargs) {
    return {};
  }
}

abstract class SingleObjectMixin extends GenericView {
  String? slug;
  String? slugField;
  String? slugUrlKwarg;
  String? pk;
  String? pkUrlKwarg;
  
  SingleObjectMixin({
    this.slug,
    this.slugField,
    this.slugUrlKwarg,
    this.pk,
    this.pkUrlKwarg,
    super.model,
    super.queryset,
    super.contextObjectName,
    super.extraContext,
  });
  
  Future<Model> getObject(HttpRequest request, Map<String, dynamic> kwargs) async {
    final queryset = getQueryset();
    
    final pk = getPk(kwargs);
    final slug = getSlug(kwargs);
    
    if (pk != null) {
      try {
        return await queryset.get({'pk': pk});
      } catch (e) {
        throw Http404Exception('Object not found');
      }
    }
    
    if (slug != null) {
      final slugField = getSlugField();
      try {
        return await queryset.get({slugField: slug});
      } catch (e) {
        throw Http404Exception('Object not found');
      }
    }
    
    throw ViewException('SingleObjectMixin requires either pk or slug');
  }
  
  String? getPk(Map<String, dynamic> kwargs) {
    if (pk != null) return pk;
    
    final kwarg = pkUrlKwarg ?? 'pk';
    return kwargs[kwarg]?.toString();
  }
  
  String? getSlug(Map<String, dynamic> kwargs) {
    if (slug != null) return slug;
    
    final kwarg = slugUrlKwarg ?? 'slug';
    return kwargs[kwarg]?.toString();
  }
  
  String getSlugField() {
    return slugField ?? 'slug';
  }
  
  @override
  Map<String, dynamic> getContextData(HttpRequest request, Map<String, dynamic> kwargs) {
    final context = super.getContextData(request, kwargs);
    
    if (context.containsKey('object')) {
      final objectName = getContextObjectName();
      context[objectName] = context['object'];
    }
    
    return context;
  }
}

abstract class MultipleObjectMixin extends GenericView {
  bool allowEmpty = true;
  int? paginate;
  String? paginateBy;
  String? contextObjectName;
  String? ordering;
  
  MultipleObjectMixin({
    this.allowEmpty = true,
    this.paginate,
    this.paginateBy,
    this.contextObjectName,
    this.ordering,
    super.model,
    super.queryset,
    super.extraContext,
  });
  
  Future<List<Model>> getObjectList(HttpRequest request, Map<String, dynamic> kwargs) async {
    var queryset = getQueryset();
    
    final ordering = getOrdering(request);
    if (ordering != null) {
      queryset = queryset.orderBy(ordering);
    }
    
    final objectList = await queryset.all();
    
    if (!allowEmpty && objectList.isEmpty) {
      throw Http404Exception('Empty list and allowEmpty is False');
    }
    
    return objectList;
  }
  
  List<String>? getOrdering(HttpRequest request) {
    if (ordering != null) {
      return [ordering!];
    }
    
    return null;
  }
  
  String getContextObjectName() {
    if (contextObjectName != null) {
      return contextObjectName!;
    }
    
    if (model != null) {
      return '${model!.runtimeType.toString().toLowerCase()}_list';
    }
    
    return 'object_list';
  }
  
  @override
  Map<String, dynamic> getContextData(HttpRequest request, Map<String, dynamic> kwargs) {
    final context = super.getContextData(request, kwargs);
    
    if (context.containsKey('object_list')) {
      final objectName = getContextObjectName();
      context[objectName] = context['object_list'];
    }
    
    return context;
  }
}

class DetailView extends SingleObjectMixin {
  String? templateName;
  String? contentType;
  
  DetailView({
    super.model,
    super.queryset,
    super.contextObjectName,
    super.extraContext,
    super.slug,
    super.slugField,
    super.slugUrlKwarg,
    super.pk,
    super.pkUrlKwarg,
    this.templateName,
    this.contentType,
  });
  
  @override
  Future<HttpResponse> get(HttpRequest request, Map<String, dynamic> kwargs) async {
    final object = await getObject(request, kwargs);
    final context = getContext(request, kwargs);
    context['object'] = object;
    
    return await renderToResponse(context, request);
  }
  
  Future<HttpResponse> renderToResponse(Map<String, dynamic> context, HttpRequest request) async {
    final template = getTemplate(request);
    final content = await template.render(TemplateContext(context));
    
    return HttpResponse.html(
      content,
      headers: contentType != null ? {'Content-Type': contentType!} : null,
    );
  }
  
  Template getTemplate(HttpRequest request) {
    final name = getTemplateName(request);
    if (name == null) {
      throw ViewException('DetailView requires either a templateName or an implementation of getTemplateName()');
    }
    
    return TemplateEngine.instance.getTemplate(name);
  }
  
  String? getTemplateName(HttpRequest request) {
    if (templateName != null) {
      return templateName;
    }
    
    if (model != null) {
      final modelName = model!.runtimeType.toString().toLowerCase();
      return '${modelName}_detail.html';
    }
    
    return null;
  }
}

class ListView extends MultipleObjectMixin {
  String? templateName;
  String? contentType;
  
  ListView({
    super.model,
    super.queryset,
    super.contextObjectName,
    super.extraContext,
    super.allowEmpty,
    super.paginate,
    super.paginateBy,
    super.ordering,
    this.templateName,
    this.contentType,
  });
  
  @override
  Future<HttpResponse> get(HttpRequest request, Map<String, dynamic> kwargs) async {
    final objectList = await getObjectList(request, kwargs);
    final context = getContext(request, kwargs);
    context['object_list'] = objectList;
    
    return await renderToResponse(context, request);
  }
  
  Future<HttpResponse> renderToResponse(Map<String, dynamic> context, HttpRequest request) async {
    final template = getTemplate(request);
    final content = await template.render(TemplateContext(context));
    
    return HttpResponse.html(
      content,
      headers: contentType != null ? {'Content-Type': contentType!} : null,
    );
  }
  
  Template getTemplate(HttpRequest request) {
    final name = getTemplateName(request);
    if (name == null) {
      throw ViewException('ListView requires either a templateName or an implementation of getTemplateName()');
    }
    
    return TemplateEngine.instance.getTemplate(name);
  }
  
  String? getTemplateName(HttpRequest request) {
    if (templateName != null) {
      return templateName;
    }
    
    if (model != null) {
      final modelName = model!.runtimeType.toString().toLowerCase();
      return '${modelName}_list.html';
    }
    
    return null;
  }
}

abstract class FormMixin extends GenericView {
  String? initialData;
  String? prefix;
  String? successUrl;
  
  FormMixin({
    this.initialData,
    this.prefix,
    this.successUrl,
    Model? model,
    QuerySet? queryset,
    String? contextObjectName,
    Map<String, dynamic>? extraContext,
  }) : super(
    model: model,
    queryset: queryset,
    contextObjectName: contextObjectName,
    extraContext: extraContext,
  );
  
  Map<String, dynamic> getInitialData(HttpRequest request) {
    final initial = <String, dynamic>{};
    
    if (initialData != null) {
      initial.addAll(json.decode(initialData!));
    }
    
    return initial;
  }
  
  String? getPrefix(HttpRequest request) {
    return prefix;
  }
  
  String? getSuccessUrl(HttpRequest request) {
    return successUrl;
  }
  
  Future<HttpResponse> formValid(HttpRequest request, Map<String, dynamic> form) async {
    final successUrl = getSuccessUrl(request);
    if (successUrl != null) {
      return HttpResponse.redirect(successUrl);
    }
    
    return HttpResponse('Form submitted successfully');
  }
  
  Future<HttpResponse> formInvalid(HttpRequest request, Map<String, dynamic> form, Map<String, dynamic> errors) async {
    final context = getContext(request, {});
    context['form'] = form;
    context['errors'] = errors;
    
    return await renderToResponse(context, request);
  }
  
  Future<HttpResponse> renderToResponse(Map<String, dynamic> context, HttpRequest request) async {
    final template = getTemplate(request);
    final content = await template.render(TemplateContext(context));
    
    return HttpResponse.html(content);
  }
  
  Template getTemplate(HttpRequest request) {
    final name = getTemplateName(request);
    if (name == null) {
      throw ViewException('FormMixin requires either a templateName or an implementation of getTemplateName()');
    }
    
    return TemplateEngine.instance.getTemplate(name);
  }
  
  String? getTemplateName(HttpRequest request) {
    return null;
  }
}

class FormView extends FormMixin {
  String? templateName;
  String? contentType;
  
  FormView({
    String? initialData,
    String? prefix,
    String? successUrl,
    Model? model,
    QuerySet? queryset,
    String? contextObjectName,
    Map<String, dynamic>? extraContext,
    this.templateName,
    this.contentType,
  }) : super(
    initialData: initialData,
    prefix: prefix,
    successUrl: successUrl,
    model: model,
    queryset: queryset,
    contextObjectName: contextObjectName,
    extraContext: extraContext,
  );
  
  @override
  Future<HttpResponse> get(HttpRequest request, Map<String, dynamic> kwargs) async {
    final context = getContext(request, kwargs);
    final initial = getInitialData(request);
    context['form'] = initial;
    
    return await renderToResponse(context, request);
  }
  
  @override
  Future<HttpResponse> post(HttpRequest request, Map<String, dynamic> kwargs) async {
    final form = await getFormData(request);
    final errors = await validateForm(request, form);
    
    if (errors.isEmpty) {
      return await formValid(request, form);
    } else {
      return await formInvalid(request, form, errors);
    }
  }
  
  Future<Map<String, dynamic>> getFormData(HttpRequest request) async {
    final contentType = request.headers['content-type'] ?? '';
    
    if (contentType.startsWith('application/json')) {
      final body = await request.body;
      return json.decode(body);
    }
    
    if (contentType.startsWith('application/x-www-form-urlencoded')) {
      final body = await request.body;
      final params = Uri.splitQueryString(body);
      return Map<String, dynamic>.from(params);
    }
    
    return {};
  }
  
  Future<Map<String, dynamic>> validateForm(HttpRequest request, Map<String, dynamic> form) async {
    final errors = <String, dynamic>{};
    
    return errors;
  }
  
  Future<HttpResponse> renderToResponse(Map<String, dynamic> context, HttpRequest request) async {
    final template = getTemplate(request);
    final content = await template.render(TemplateContext(context));
    
    return HttpResponse.html(
      content,
      headers: contentType != null ? {'Content-Type': contentType!} : null,
    );
  }
  
  Template getTemplate(HttpRequest request) {
    final name = getTemplateName(request);
    if (name == null) {
      throw ViewException('FormView requires either a templateName or an implementation of getTemplateName()');
    }
    
    return TemplateEngine.instance.getTemplate(name);
  }
  
  String? getTemplateName(HttpRequest request) {
    return templateName;
  }
}

class CreateView extends FormMixin {
  String? templateName;
  
  CreateView({
    Model? model,
    QuerySet? queryset,
    String? contextObjectName,
    Map<String, dynamic>? extraContext,
    String? initialData,
    String? prefix,
    String? successUrl,
    this.templateName,
  }) : super(
    model: model,
    queryset: queryset,
    contextObjectName: contextObjectName,
    extraContext: extraContext,
    initialData: initialData,
    prefix: prefix,
    successUrl: successUrl,
  );
  
  @override
  Future<HttpResponse> get(HttpRequest request, Map<String, dynamic> kwargs) async {
    final context = getContext(request, kwargs);
    final initial = getInitialData(request);
    context['form'] = initial;
    
    return await renderToResponse(context, request);
  }
  
  @override
  Future<HttpResponse> post(HttpRequest request, Map<String, dynamic> kwargs) async {
    final form = await getFormData(request);
    final errors = await validateForm(request, form);
    
    if (errors.isEmpty) {
      await createObject(request, form);
      return await formValid(request, form);
    } else {
      return await formInvalid(request, form, errors);
    }
  }
  
  Future<Model> createObject(HttpRequest request, Map<String, dynamic> form) async {
    final modelClass = model!.runtimeType;
    final object = (modelClass as dynamic).fromMap(form);
    await object.save();
    return object;
  }
  
  Future<Map<String, dynamic>> getFormData(HttpRequest request) async {
    final contentType = request.headers['content-type'] ?? '';
    
    if (contentType.startsWith('application/json')) {
      final body = await request.body;
      return json.decode(body);
    }
    
    if (contentType.startsWith('application/x-www-form-urlencoded')) {
      final body = await request.body;
      final params = Uri.splitQueryString(body);
      return Map<String, dynamic>.from(params);
    }
    
    return {};
  }
  
  Future<Map<String, dynamic>> validateForm(HttpRequest request, Map<String, dynamic> form) async {
    final errors = <String, dynamic>{};
    
    return errors;
  }
  
  @override
  String? getTemplateName(HttpRequest request) {
    if (templateName != null) {
      return templateName;
    }
    
    if (model != null) {
      final modelName = model!.runtimeType.toString().toLowerCase();
      return '${modelName}_form.html';
    }
    
    return null;
  }
}

class UpdateView extends FormMixin {
  String? templateName;
  String? slug;
  String? slugField;
  String? slugUrlKwarg;
  String? pk;
  String? pkUrlKwarg;
  
  UpdateView({
    Model? model,
    QuerySet? queryset,
    String? contextObjectName,
    Map<String, dynamic>? extraContext,
    this.slug,
    this.slugField,
    this.slugUrlKwarg,
    this.pk,
    this.pkUrlKwarg,
    String? initialData,
    String? prefix,
    String? successUrl,
    this.templateName,
  }) : super(
    model: model,
    queryset: queryset,
    contextObjectName: contextObjectName,
    extraContext: extraContext,
    initialData: initialData,
    prefix: prefix,
    successUrl: successUrl,
  );
  
  Future<Model> getObject(HttpRequest request, Map<String, dynamic> kwargs) async {
    final queryset = getQueryset();
    
    final pk = getPk(kwargs);
    final slug = getSlug(kwargs);
    
    if (pk != null) {
      try {
        return await queryset.get({'pk': pk});
      } catch (e) {
        throw Http404Exception('Object not found');
      }
    }
    
    if (slug != null) {
      final slugField = getSlugField();
      try {
        return await queryset.get({slugField: slug});
      } catch (e) {
        throw Http404Exception('Object not found');
      }
    }
    
    throw ViewException('UpdateView requires either pk or slug');
  }
  
  String? getPk(Map<String, dynamic> kwargs) {
    if (pk != null) return pk;
    
    final kwarg = pkUrlKwarg ?? 'pk';
    return kwargs[kwarg]?.toString();
  }
  
  String? getSlug(Map<String, dynamic> kwargs) {
    if (slug != null) return slug;
    
    final kwarg = slugUrlKwarg ?? 'slug';
    return kwargs[kwarg]?.toString();
  }
  
  String getSlugField() {
    return slugField ?? 'slug';
  }
  
  @override
  Future<HttpResponse> get(HttpRequest request, Map<String, dynamic> kwargs) async {
    final object = await getObject(request, kwargs);
    final context = getContext(request, kwargs);
    context['object'] = object;
    context['form'] = object.toMap();
    
    return await renderToResponse(context, request);
  }
  
  @override
  Future<HttpResponse> post(HttpRequest request, Map<String, dynamic> kwargs) async {
    final object = await getObject(request, kwargs);
    final form = await getFormData(request);
    final errors = await validateForm(request, form);
    
    if (errors.isEmpty) {
      await updateObject(request, object, form);
      return await formValid(request, form);
    } else {
      return await formInvalid(request, form, errors);
    }
  }
  
  Future<Model> updateObject(HttpRequest request, Model object, Map<String, dynamic> form) async {
    for (final entry in form.entries) {
      object.setField(entry.key, entry.value);
    }
    await object.save();
    return object;
  }
  
  Future<Map<String, dynamic>> getFormData(HttpRequest request) async {
    final contentType = request.headers['content-type'] ?? '';
    
    if (contentType.startsWith('application/json')) {
      final body = await request.body;
      return json.decode(body);
    }
    
    if (contentType.startsWith('application/x-www-form-urlencoded')) {
      final body = await request.body;
      final params = Uri.splitQueryString(body);
      return Map<String, dynamic>.from(params);
    }
    
    return {};
  }
  
  Future<Map<String, dynamic>> validateForm(HttpRequest request, Map<String, dynamic> form) async {
    final errors = <String, dynamic>{};
    
    return errors;
  }
  
  @override
  String? getTemplateName(HttpRequest request) {
    if (templateName != null) {
      return templateName;
    }
    
    if (model != null) {
      final modelName = model!.runtimeType.toString().toLowerCase();
      return '${modelName}_form.html';
    }
    
    return null;
  }
}

class DeleteView extends SingleObjectMixin {
  String? successUrl;
  String? templateName;
  String? contentType;
  
  DeleteView({
    this.successUrl,
    this.templateName,
    this.contentType,
    Model? model,
    QuerySet? queryset,
    String? contextObjectName,
    Map<String, dynamic>? extraContext,
    String? slug,
    String? slugField,
    String? slugUrlKwarg,
    String? pk,
    String? pkUrlKwarg,
  }) : super(
    model: model,
    queryset: queryset,
    contextObjectName: contextObjectName,
    extraContext: extraContext,
    slug: slug,
    slugField: slugField,
    slugUrlKwarg: slugUrlKwarg,
    pk: pk,
    pkUrlKwarg: pkUrlKwarg,
  );
  
  @override
  Future<HttpResponse> get(HttpRequest request, Map<String, dynamic> kwargs) async {
    final object = await getObject(request, kwargs);
    final context = getContext(request, kwargs);
    context['object'] = object;
    
    return await renderToResponse(context, request);
  }
  
  Future<HttpResponse> renderToResponse(Map<String, dynamic> context, HttpRequest request) async {
    final template = getTemplate(request);
    final content = await template.render(TemplateContext(context));
    
    return HttpResponse.html(
      content,
      headers: contentType != null ? {'Content-Type': contentType!} : null,
    );
  }
  
  Template getTemplate(HttpRequest request) {
    final name = getTemplateName(request);
    if (name == null) {
      throw ViewException('DeleteView requires either a templateName or an implementation of getTemplateName()');
    }
    
    return TemplateEngine.instance.getTemplate(name);
  }
  
  @override
  Future<HttpResponse> post(HttpRequest request, Map<String, dynamic> kwargs) async {
    final object = await getObject(request, kwargs);
    await deleteObject(request, object);
    
    final successUrl = getSuccessUrl(request);
    if (successUrl != null) {
      return HttpResponse.redirect(successUrl);
    }
    
    return HttpResponse('Object deleted successfully');
  }
  
  Future<void> deleteObject(HttpRequest request, Model object) async {
    await object.delete();
  }
  
  String? getSuccessUrl(HttpRequest request) {
    return successUrl;
  }
  
  String? getTemplateName(HttpRequest request) {
    if (templateName != null) {
      return templateName;
    }
    
    if (model != null) {
      final modelName = model!.runtimeType.toString().toLowerCase();
      return '${modelName}_confirm_delete.html';
    }
    
    return null;
  }
}