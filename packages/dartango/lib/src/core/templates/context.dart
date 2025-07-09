
import 'engine.dart';
import 'exceptions.dart';

class TemplateContext {
  final List<Map<String, dynamic>> _stack = [];
  final Map<String, dynamic> _globals = {};
  bool _autoEscape = true;
  
  TemplateContext([Map<String, dynamic>? initial]) {
    if (initial != null) {
      _stack.add(Map<String, dynamic>.from(initial));
    } else {
      _stack.add(<String, dynamic>{});
    }
  }
  
  void push([Map<String, dynamic>? context]) {
    _stack.add(context ?? <String, dynamic>{});
  }
  
  Map<String, dynamic> pop() {
    if (_stack.length <= 1) {
      throw StateError('Cannot pop the last context');
    }
    return _stack.removeLast();
  }
  
  dynamic operator [](String key) {
    if (_globals.containsKey(key)) {
      return _globals[key];
    }
    
    for (int i = _stack.length - 1; i >= 0; i--) {
      if (_stack[i].containsKey(key)) {
        return _stack[i][key];
      }
    }
    
    return null;
  }
  
  void operator []=(String key, dynamic value) {
    _stack.last[key] = value;
  }
  
  bool containsKey(String key) {
    if (_globals.containsKey(key)) {
      return true;
    }
    
    for (final context in _stack.reversed) {
      if (context.containsKey(key)) {
        return true;
      }
    }
    
    return false;
  }
  
  void remove(String key) {
    for (final context in _stack.reversed) {
      if (context.containsKey(key)) {
        context.remove(key);
        break;
      }
    }
  }
  
  void setGlobal(String key, dynamic value) {
    _globals[key] = value;
  }
  
  dynamic getGlobal(String key) {
    return _globals[key];
  }
  
  void removeGlobal(String key) {
    _globals.remove(key);
  }
  
  bool get autoEscape => _autoEscape;
  
  void setAutoEscape(bool value) {
    _autoEscape = value;
  }
  
  Map<String, dynamic> flatten() {
    final result = <String, dynamic>{};
    
    for (final context in _stack) {
      result.addAll(context);
    }
    
    result.addAll(_globals);
    
    return result;
  }
  
  TemplateContext copy() {
    final copy = TemplateContext();
    copy._stack.clear();
    
    for (final context in _stack) {
      copy._stack.add(Map<String, dynamic>.from(context));
    }
    
    copy._globals.addAll(_globals);
    copy._autoEscape = _autoEscape;
    
    return copy;
  }
  
  void update(Map<String, dynamic> other) {
    _stack.last.addAll(other);
  }
  
  Iterable<String> get keys {
    final allKeys = <String>{};
    
    for (final context in _stack) {
      allKeys.addAll(context.keys);
    }
    
    allKeys.addAll(_globals.keys);
    
    return allKeys;
  }
  
  @override
  String toString() {
    return 'TemplateContext(${flatten()})';
  }
}

class ContextVariable {
  final String name;
  final List<String> filters;
  
  ContextVariable(this.name, [this.filters = const []]);
  
  dynamic resolve(TemplateContext context) {
    dynamic value = _resolveVariable(context, name);
    
    for (final filterName in filters) {
      value = _applyFilter(value, filterName, context);
    }
    
    return value;
  }
  
  dynamic _resolveVariable(TemplateContext context, String name) {
    if (name.contains('.')) {
      final parts = name.split('.');
      dynamic current = context[parts[0]];
      
      for (int i = 1; i < parts.length; i++) {
        if (current == null) {
          return null;
        }
        
        current = _resolveAttribute(current, parts[i]);
      }
      
      return current;
    }
    
    return context[name];
  }
  
  dynamic _resolveAttribute(dynamic object, String attribute) {
    if (object is Map) {
      return object[attribute];
    }
    
    if (object is List) {
      final index = int.tryParse(attribute);
      if (index != null && index >= 0 && index < object.length) {
        return object[index];
      }
    }
    
    return null;
  }
  
  dynamic _applyFilter(dynamic value, String filterName, TemplateContext context) {
    final parts = filterName.split(':');
    final name = parts[0];
    final args = parts.length > 1 ? parts.sublist(1) : <String>[];
    
    if (!TemplateEngine.instance.hasFilter(name)) {
      throw TemplateException('Unknown filter: $name');
    }
    
    final filter = TemplateEngine.instance.getFilter(name);
    return filter.apply(value, args, context);
  }
  
  static ContextVariable parse(String expression) {
    final parts = expression.split('|');
    final variableName = parts[0].trim();
    final filters = parts.sublist(1).map((f) => f.trim()).toList();
    
    return ContextVariable(variableName, filters);
  }
}


class TemplateContextProcessor {
  final String name;
  final Map<String, dynamic> Function(dynamic request) processor;
  
  TemplateContextProcessor(this.name, this.processor);
  
  Map<String, dynamic> process(dynamic request) {
    return processor(request);
  }
}

class TemplateContextProcessorManager {
  final List<TemplateContextProcessor> _processors = [];
  
  void addProcessor(TemplateContextProcessor processor) {
    _processors.add(processor);
  }
  
  void removeProcessor(String name) {
    _processors.removeWhere((p) => p.name == name);
  }
  
  Map<String, dynamic> processAll(dynamic request) {
    final context = <String, dynamic>{};
    
    for (final processor in _processors) {
      try {
        final result = processor.process(request);
        context.addAll(result);
      } catch (e) {
        continue;
      }
    }
    
    return context;
  }
}

extension TemplateContextExtensions on TemplateContext {
  void withContext(Map<String, dynamic> context, void Function() callback) {
    push(context);
    try {
      callback();
    } finally {
      pop();
    }
  }
  
  T withContextResult<T>(Map<String, dynamic> context, T Function() callback) {
    push(context);
    try {
      return callback();
    } finally {
      pop();
    }
  }
  
  void set(String key, dynamic value) {
    this[key] = value;
  }
  
  dynamic get(String key, [dynamic defaultValue]) {
    return containsKey(key) ? this[key] : defaultValue;
  }
  
  bool isEmpty() {
    return _stack.isEmpty || (_stack.length == 1 && _stack.first.isEmpty);
  }
  
  int get length {
    return flatten().length;
  }
}