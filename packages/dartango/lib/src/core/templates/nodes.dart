import 'dart:async';

import 'context.dart';
import 'engine.dart';
import 'tags.dart';
import 'exceptions.dart';

abstract class TemplateNode {
  Future<String> render(TemplateContext context);
}

class NodeList extends TemplateNode {
  final List<TemplateNode> nodes;

  NodeList(this.nodes);

  @override
  Future<String> render(TemplateContext context) async {
    final buffer = StringBuffer();

    for (final node in nodes) {
      final result = await node.render(context);
      buffer.write(result);
    }

    return buffer.toString();
  }
}

class TextNode extends TemplateNode {
  final String text;

  TextNode(this.text);

  @override
  Future<String> render(TemplateContext context) async {
    return text;
  }
}

class VariableNode extends TemplateNode {
  final String expression;

  VariableNode(this.expression);

  @override
  Future<String> render(TemplateContext context) async {
    try {
      final variable = ContextVariable.parse(expression);
      final value = variable.resolve(context);

      if (value == null) return '';

      final result = value.toString();

      if (context.autoEscape && !_isSafe(value)) {
        return _escapeHtml(result);
      }

      return result;
    } catch (e) {
      throw TemplateVariableException(
          expression, 'Error resolving variable: $e');
    }
  }

  bool _isSafe(dynamic value) {
    return value is SafeString || value is TemplateResult && value.isSafe;
  }

  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;');
  }
}

class CommentNode extends TemplateNode {
  final String content;

  CommentNode(this.content);

  @override
  Future<String> render(TemplateContext context) async {
    return '';
  }
}

class IfNode extends TemplateNode {
  final List<IfBranch> branches;

  IfNode(this.branches);

  @override
  Future<String> render(TemplateContext context) async {
    for (final branch in branches) {
      if (await _evaluateCondition(branch.condition, context)) {
        return await NodeList(branch.nodes).render(context);
      }
    }

    return '';
  }

  Future<bool> _evaluateCondition(
      String condition, TemplateContext context) async {
    if (condition == 'true') return true;
    if (condition == 'false') return false;

    if (condition.contains(' and ')) {
      final parts = condition.split(' and ');
      for (final part in parts) {
        if (!await _evaluateCondition(part.trim(), context)) {
          return false;
        }
      }
      return true;
    }

    if (condition.contains(' or ')) {
      final parts = condition.split(' or ');
      for (final part in parts) {
        if (await _evaluateCondition(part.trim(), context)) {
          return true;
        }
      }
      return false;
    }

    if (condition.startsWith('not ')) {
      final innerCondition = condition.substring(4).trim();
      return !await _evaluateCondition(innerCondition, context);
    }

    if (condition.contains(' == ')) {
      final parts = condition.split(' == ');
      if (parts.length == 2) {
        final left = _resolveValue(parts[0].trim(), context);
        final right = _resolveValue(parts[1].trim(), context);
        return left == right;
      }
    }

    if (condition.contains(' != ')) {
      final parts = condition.split(' != ');
      if (parts.length == 2) {
        final left = _resolveValue(parts[0].trim(), context);
        final right = _resolveValue(parts[1].trim(), context);
        return left != right;
      }
    }

    if (condition.contains(' < ')) {
      final parts = condition.split(' < ');
      if (parts.length == 2) {
        final left = _resolveValue(parts[0].trim(), context);
        final right = _resolveValue(parts[1].trim(), context);
        return (left is num && right is num) ? left < right : false;
      }
    }

    if (condition.contains(' > ')) {
      final parts = condition.split(' > ');
      if (parts.length == 2) {
        final left = _resolveValue(parts[0].trim(), context);
        final right = _resolveValue(parts[1].trim(), context);
        return (left is num && right is num) ? left > right : false;
      }
    }

    final value = _resolveValue(condition, context);
    return _isTruthy(value);
  }

  dynamic _resolveValue(String expression, TemplateContext context) {
    if (expression.startsWith('"') && expression.endsWith('"')) {
      return expression.substring(1, expression.length - 1);
    }

    if (expression.startsWith("'") && expression.endsWith("'")) {
      return expression.substring(1, expression.length - 1);
    }

    final num = int.tryParse(expression) ?? double.tryParse(expression);
    if (num != null) return num;

    if (expression == 'True' || expression == 'true') return true;
    if (expression == 'False' || expression == 'false') return false;
    if (expression == 'None' || expression == 'null') return null;

    return ContextVariable.parse(expression).resolve(context);
  }

  bool _isTruthy(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value.isNotEmpty;
    if (value is List) return value.isNotEmpty;
    if (value is Map) return value.isNotEmpty;
    return true;
  }
}

class ForNode extends TemplateNode {
  final String variable;
  final String iterable;
  final List<TemplateNode> nodes;
  final List<TemplateNode> emptyNodes;

  ForNode(this.variable, this.iterable, this.nodes, this.emptyNodes);

  @override
  Future<String> render(TemplateContext context) async {
    final items = ContextVariable.parse(iterable).resolve(context);

    if (items == null || (items is List && items.isEmpty)) {
      return await NodeList(emptyNodes).render(context);
    }

    final buffer = StringBuffer();

    if (items is List) {
      for (int i = 0; i < items.length; i++) {
        context.push({
          variable: items[i],
          'forloop': {
            'counter': i + 1,
            'counter0': i,
            'first': i == 0,
            'last': i == items.length - 1,
            'length': items.length,
            'parentloop': context['forloop'],
          }
        });

        final result = await NodeList(nodes).render(context);
        buffer.write(result);

        context.pop();
      }
    } else if (items is Map) {
      final keys = items.keys.toList();
      for (int i = 0; i < keys.length; i++) {
        context.push({
          variable: keys[i],
          'forloop': {
            'counter': i + 1,
            'counter0': i,
            'first': i == 0,
            'last': i == keys.length - 1,
            'length': keys.length,
            'parentloop': context['forloop'],
          }
        });

        final result = await NodeList(nodes).render(context);
        buffer.write(result);

        context.pop();
      }
    }

    return buffer.toString();
  }
}

class WithNode extends TemplateNode {
  final String expression;
  final String variable;
  final List<TemplateNode> nodes;

  WithNode(this.expression, this.variable, this.nodes);

  @override
  Future<String> render(TemplateContext context) async {
    final value = ContextVariable.parse(expression).resolve(context);

    context.push({variable: value});

    try {
      return await NodeList(nodes).render(context);
    } finally {
      context.pop();
    }
  }
}

class IncludeNode extends TemplateNode {
  final String templateName;
  final Map<String, String> withContext;

  IncludeNode(this.templateName, this.withContext);

  @override
  Future<String> render(TemplateContext context) async {
    try {
      final template = TemplateEngine.instance.getTemplate(templateName);

      if (withContext.isNotEmpty) {
        final contextData = <String, dynamic>{};
        for (final entry in withContext.entries) {
          contextData[entry.key] =
              ContextVariable.parse(entry.value).resolve(context);
        }

        context.push(contextData);

        try {
          return await template.render(context);
        } finally {
          context.pop();
        }
      } else {
        return await template.render(context);
      }
    } catch (e) {
      throw TemplateIncludeException(
          templateName, 'Error including template: $e');
    }
  }
}

class ExtendsNode extends TemplateNode {
  final String parentTemplateName;

  ExtendsNode(this.parentTemplateName);

  @override
  Future<String> render(TemplateContext context) async {
    throw TemplateInheritanceException(
        'Extends node should be handled by template inheritance system');
  }
}

class BlockNode extends TemplateNode {
  final String blockName;
  final List<TemplateNode> nodes;

  BlockNode(this.blockName, this.nodes);

  @override
  Future<String> render(TemplateContext context) async {
    return await NodeList(nodes).render(context);
  }
}

class CsrfTokenNode extends TemplateNode {
  @override
  Future<String> render(TemplateContext context) async {
    final token = context['csrf_token'];
    if (token != null) {
      return '<input type="hidden" name="csrfmiddlewaretoken" value="$token">';
    }
    return '';
  }
}

class UrlNode extends TemplateNode {
  final String urlName;
  final List<String> args;

  UrlNode(this.urlName, this.args);

  @override
  Future<String> render(TemplateContext context) async {
    final resolvedArgs =
        args.map((arg) => ContextVariable.parse(arg).resolve(context)).toList();

    final urlResolver = context['url_resolver'];
    if (urlResolver != null) {
      try {
        return (urlResolver as dynamic).reverse(urlName, resolvedArgs);
      } catch (e) {
        return '';
      }
    }

    return '';
  }
}

class StaticNode extends TemplateNode {
  final String filePath;

  StaticNode(this.filePath);

  @override
  Future<String> render(TemplateContext context) async {
    final staticUrl = context['STATIC_URL'] ?? '/static/';
    return '$staticUrl$filePath';
  }
}

class LoadNode extends TemplateNode {
  final String libraryName;

  LoadNode(this.libraryName);

  @override
  Future<String> render(TemplateContext context) async {
    return '';
  }
}

class SpacelessNode extends TemplateNode {
  final List<TemplateNode> nodes;

  SpacelessNode(this.nodes);

  @override
  Future<String> render(TemplateContext context) async {
    final content = await NodeList(nodes).render(context);
    return content.replaceAll(RegExp(r'>\s+<'), '><');
  }
}

class VerbatimNode extends TemplateNode {
  final List<TemplateNode> nodes;

  VerbatimNode(this.nodes);

  @override
  Future<String> render(TemplateContext context) async {
    final buffer = StringBuffer();

    for (final node in nodes) {
      if (node is TextNode) {
        buffer.write(node.text);
      }
    }

    return buffer.toString();
  }
}

class NowNode extends TemplateNode {
  final String format;

  NowNode(this.format);

  @override
  Future<String> render(TemplateContext context) async {
    final now = DateTime.now();
    return _formatDateTime(now, format);
  }

  String _formatDateTime(DateTime date, String format) {
    return format
        .replaceAll('yyyy', date.year.toString())
        .replaceAll('MM', date.month.toString().padLeft(2, '0'))
        .replaceAll('dd', date.day.toString().padLeft(2, '0'))
        .replaceAll('HH', date.hour.toString().padLeft(2, '0'))
        .replaceAll('mm', date.minute.toString().padLeft(2, '0'))
        .replaceAll('ss', date.second.toString().padLeft(2, '0'));
  }
}

class RegroupNode extends TemplateNode {
  final String list;
  final String attribute;
  final String variable;

  RegroupNode(this.list, this.attribute, this.variable);

  @override
  Future<String> render(TemplateContext context) async {
    final items = ContextVariable.parse(list).resolve(context);

    if (items is! List) {
      context[variable] = [];
      return '';
    }

    final groups = <String, List<dynamic>>{};

    for (final item in items) {
      final key = ContextVariable.parse('$item.$attribute')
              .resolve(context)
              ?.toString() ??
          '';
      groups.putIfAbsent(key, () => []).add(item);
    }

    final regrouped = groups.entries
        .map((entry) => {
              'grouper': entry.key,
              'list': entry.value,
            })
        .toList();

    context[variable] = regrouped;

    return '';
  }
}

class CycleNode extends TemplateNode {
  final List<String> values;
  static final Map<String, int> _counters = {};

  CycleNode(this.values);

  @override
  Future<String> render(TemplateContext context) async {
    final key = values.join('|');
    final counter = _counters.putIfAbsent(key, () => 0);
    final value = values[counter % values.length];
    _counters[key] = counter + 1;
    return value;
  }
}

class FirstOfNode extends TemplateNode {
  final List<String> variables;

  FirstOfNode(this.variables);

  @override
  Future<String> render(TemplateContext context) async {
    for (final variable in variables) {
      final value = ContextVariable.parse(variable).resolve(context);
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }
    return '';
  }
}

class IfChangedNode extends TemplateNode {
  final List<String> variables;
  final List<TemplateNode> nodes;
  static final Map<String, dynamic> _lastValues = {};

  IfChangedNode(this.variables, this.nodes);

  @override
  Future<String> render(TemplateContext context) async {
    final key = variables.join('|');
    final currentValues = variables
        .map((v) => ContextVariable.parse(v).resolve(context))
        .toList();

    if (_lastValues[key] != currentValues.join('|')) {
      _lastValues[key] = currentValues.join('|');
      return await NodeList(nodes).render(context);
    }

    return '';
  }
}

class TemplateTagNode extends TemplateNode {
  final String tagName;

  TemplateTagNode(this.tagName);

  @override
  Future<String> render(TemplateContext context) async {
    switch (tagName) {
      case 'openblock':
        return '{%';
      case 'closeblock':
        return '%}';
      case 'openvariable':
        return '{{';
      case 'closevariable':
        return '}}';
      case 'openbrace':
        return '{';
      case 'closebrace':
        return '}';
      case 'opencomment':
        return '{#';
      case 'closecomment':
        return '#}';
      default:
        return '';
    }
  }
}

class WidthRatioNode extends TemplateNode {
  final String current;
  final String max;
  final String scale;

  WidthRatioNode(this.current, this.max, this.scale);

  @override
  Future<String> render(TemplateContext context) async {
    final currentValue = ContextVariable.parse(current).resolve(context);
    final maxValue = ContextVariable.parse(max).resolve(context);
    final scaleValue = ContextVariable.parse(scale).resolve(context);

    if (currentValue is num &&
        maxValue is num &&
        scaleValue is num &&
        maxValue != 0) {
      final ratio = (currentValue / maxValue * scaleValue).round();
      return ratio.toString();
    }

    return '0';
  }
}

class FilterNode extends TemplateNode {
  final String filters;
  final List<TemplateNode> nodes;

  FilterNode(this.filters, this.nodes);

  @override
  Future<String> render(TemplateContext context) async {
    final content = await NodeList(nodes).render(context);
    final variable = ContextVariable.parse('content|$filters');

    context.push({'content': content});

    try {
      return variable.resolve(context)?.toString() ?? '';
    } finally {
      context.pop();
    }
  }
}

class AutoEscapeNode extends TemplateNode {
  final bool autoEscape;
  final List<TemplateNode> nodes;

  AutoEscapeNode(this.autoEscape, this.nodes);

  @override
  Future<String> render(TemplateContext context) async {
    final oldAutoEscape = context.autoEscape;
    context.setAutoEscape(autoEscape);

    try {
      return await NodeList(nodes).render(context);
    } finally {
      context.setAutoEscape(oldAutoEscape);
    }
  }
}
