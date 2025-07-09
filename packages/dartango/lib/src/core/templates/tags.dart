import 'nodes.dart';
import 'engine.dart';
import 'exceptions.dart';

abstract class TemplateTag {
  TemplateNode parse(TemplateParser parser, Token token, List<String> args);
}

class IfTag extends TemplateTag {
  @override
  TemplateNode parse(TemplateParser parser, Token token, List<String> args) {
    final condition = args.join(' ');
    final ifNodes = parser.parseUntil(['elif', 'else', 'endif']);
    
    final branches = <IfBranch>[IfBranch(condition, ifNodes)];
    
    while (parser.peek()?.type == TokenType.tag) {
      final nextToken = parser.peek()!;
      final parts = nextToken.content.split(RegExp(r'\s+'));
      final tagName = parts[0];
      
      if (tagName == 'elif') {
        parser.consume();
        final elifCondition = parts.sublist(1).join(' ');
        final elifNodes = parser.parseUntil(['elif', 'else', 'endif']);
        branches.add(IfBranch(elifCondition, elifNodes));
      } else if (tagName == 'else') {
        parser.consume();
        final elseNodes = parser.parseUntil(['endif']);
        branches.add(IfBranch('true', elseNodes));
        break;
      } else {
        break;
      }
    }
    
    final endToken = parser.consume();
    if (endToken == null || !endToken.content.startsWith('endif')) {
      throw TemplateSyntaxException('Expected endif tag');
    }
    
    return IfNode(branches);
  }
}

class ForTag extends TemplateTag {
  @override
  TemplateNode parse(TemplateParser parser, Token token, List<String> args) {
    if (args.length < 3 || args[1] != 'in') {
      throw TemplateSyntaxException('For tag requires format: for item in items');
    }
    
    final variable = args[0];
    final iterable = args.sublist(2).join(' ');
    
    final nodes = parser.parseUntil(['empty', 'endfor']);
    
    List<TemplateNode> emptyNodes = [];
    
    final nextToken = parser.peek();
    if (nextToken?.content.startsWith('empty') == true) {
      parser.consume();
      emptyNodes = parser.parseUntil(['endfor']);
    }
    
    final endToken = parser.consume();
    if (endToken == null || !endToken.content.startsWith('endfor')) {
      throw TemplateSyntaxException('Expected endfor tag');
    }
    
    return ForNode(variable, iterable, nodes, emptyNodes);
  }
}

class WithTag extends TemplateTag {
  @override
  TemplateNode parse(TemplateParser parser, Token token, List<String> args) {
    if (args.length < 3 || args[1] != 'as') {
      throw TemplateSyntaxException('With tag requires format: with expression as variable');
    }
    
    final expression = args[0];
    final variable = args[2];
    
    final nodes = parser.parseUntil(['endwith']);
    
    final endToken = parser.consume();
    if (endToken == null || !endToken.content.startsWith('endwith')) {
      throw TemplateSyntaxException('Expected endwith tag');
    }
    
    return WithNode(expression, variable, nodes);
  }
}

class IncludeTag extends TemplateTag {
  @override
  TemplateNode parse(TemplateParser parser, Token token, List<String> args) {
    if (args.isEmpty) {
      throw TemplateSyntaxException('Include tag requires a template name');
    }
    
    final templateName = args[0].replaceAll('"', '').replaceAll("'", '');
    Map<String, String> withContext = {};
    
    if (args.length > 1 && args[1] == 'with') {
      for (int i = 2; i < args.length; i++) {
        final part = args[i];
        if (part.contains('=')) {
          final keyValue = part.split('=');
          if (keyValue.length == 2) {
            withContext[keyValue[0]] = keyValue[1];
          }
        }
      }
    }
    
    return IncludeNode(templateName, withContext);
  }
}

class ExtendsTag extends TemplateTag {
  @override
  TemplateNode parse(TemplateParser parser, Token token, List<String> args) {
    if (args.isEmpty) {
      throw TemplateSyntaxException('Extends tag requires a template name');
    }
    
    final templateName = args[0].replaceAll('"', '').replaceAll("'", '');
    return ExtendsNode(templateName);
  }
}

class BlockTag extends TemplateTag {
  @override
  TemplateNode parse(TemplateParser parser, Token token, List<String> args) {
    if (args.isEmpty) {
      throw TemplateSyntaxException('Block tag requires a block name');
    }
    
    final blockName = args[0];
    final nodes = parser.parseUntil(['endblock']);
    
    final endToken = parser.consume();
    if (endToken == null || !endToken.content.startsWith('endblock')) {
      throw TemplateSyntaxException('Expected endblock tag');
    }
    
    return BlockNode(blockName, nodes);
  }
}

class CommentTag extends TemplateTag {
  @override
  TemplateNode parse(TemplateParser parser, Token token, List<String> args) {
    parser.parseUntil(['endcomment']);
    
    final endToken = parser.consume();
    if (endToken == null || !endToken.content.startsWith('endcomment')) {
      throw TemplateSyntaxException('Expected endcomment tag');
    }
    
    return CommentNode('');
  }
}

class CsrfTokenTag extends TemplateTag {
  @override
  TemplateNode parse(TemplateParser parser, Token token, List<String> args) {
    return CsrfTokenNode();
  }
}

class UrlTag extends TemplateTag {
  @override
  TemplateNode parse(TemplateParser parser, Token token, List<String> args) {
    if (args.isEmpty) {
      throw TemplateSyntaxException('URL tag requires a URL pattern name');
    }
    
    final urlName = args[0].replaceAll('"', '').replaceAll("'", '');
    final urlArgs = args.sublist(1);
    
    return UrlNode(urlName, urlArgs);
  }
}

class StaticTag extends TemplateTag {
  @override
  TemplateNode parse(TemplateParser parser, Token token, List<String> args) {
    if (args.isEmpty) {
      throw TemplateSyntaxException('Static tag requires a file path');
    }
    
    final filePath = args[0].replaceAll('"', '').replaceAll("'", '');
    return StaticNode(filePath);
  }
}

class LoadTag extends TemplateTag {
  @override
  TemplateNode parse(TemplateParser parser, Token token, List<String> args) {
    if (args.isEmpty) {
      throw TemplateSyntaxException('Load tag requires a library name');
    }
    
    final libraryName = args[0];
    return LoadNode(libraryName);
  }
}

class SpacelessTag extends TemplateTag {
  @override
  TemplateNode parse(TemplateParser parser, Token token, List<String> args) {
    final nodes = parser.parseUntil(['endspaceless']);
    
    final endToken = parser.consume();
    if (endToken == null || !endToken.content.startsWith('endspaceless')) {
      throw TemplateSyntaxException('Expected endspaceless tag');
    }
    
    return SpacelessNode(nodes);
  }
}

class VerbatimTag extends TemplateTag {
  @override
  TemplateNode parse(TemplateParser parser, Token token, List<String> args) {
    final nodes = parser.parseUntil(['endverbatim']);
    
    final endToken = parser.consume();
    if (endToken == null || !endToken.content.startsWith('endverbatim')) {
      throw TemplateSyntaxException('Expected endverbatim tag');
    }
    
    return VerbatimNode(nodes);
  }
}

class NowTag extends TemplateTag {
  @override
  TemplateNode parse(TemplateParser parser, Token token, List<String> args) {
    final format = args.isNotEmpty ? args[0].replaceAll('"', '').replaceAll("'", '') : 'yyyy-MM-dd HH:mm:ss';
    return NowNode(format);
  }
}

class RegroupTag extends TemplateTag {
  @override
  TemplateNode parse(TemplateParser parser, Token token, List<String> args) {
    if (args.length < 5 || args[1] != 'by' || args[3] != 'as') {
      throw TemplateSyntaxException('Regroup tag requires format: regroup list by attribute as variable');
    }
    
    final list = args[0];
    final attribute = args[2];
    final variable = args[4];
    
    return RegroupNode(list, attribute, variable);
  }
}

class CycleTag extends TemplateTag {
  @override
  TemplateNode parse(TemplateParser parser, Token token, List<String> args) {
    if (args.isEmpty) {
      throw TemplateSyntaxException('Cycle tag requires at least one value');
    }
    
    final values = args.map((arg) => arg.replaceAll('"', '').replaceAll("'", '')).toList();
    return CycleNode(values);
  }
}

class FirstOfTag extends TemplateTag {
  @override
  TemplateNode parse(TemplateParser parser, Token token, List<String> args) {
    if (args.isEmpty) {
      throw TemplateSyntaxException('Firstof tag requires at least one variable');
    }
    
    return FirstOfNode(args);
  }
}

class IfChangedTag extends TemplateTag {
  @override
  TemplateNode parse(TemplateParser parser, Token token, List<String> args) {
    final variables = args;
    final nodes = parser.parseUntil(['endifchanged']);
    
    final endToken = parser.consume();
    if (endToken == null || !endToken.content.startsWith('endifchanged')) {
      throw TemplateSyntaxException('Expected endifchanged tag');
    }
    
    return IfChangedNode(variables, nodes);
  }
}

class TemplateTagTag extends TemplateTag {
  @override
  TemplateNode parse(TemplateParser parser, Token token, List<String> args) {
    if (args.isEmpty) {
      throw TemplateSyntaxException('Templatetag tag requires a tag name');
    }
    
    final tagName = args[0];
    return TemplateTagNode(tagName);
  }
}

class WidthRatioTag extends TemplateTag {
  @override
  TemplateNode parse(TemplateParser parser, Token token, List<String> args) {
    if (args.length < 3) {
      throw TemplateSyntaxException('Widthratio tag requires format: widthratio current max scale');
    }
    
    final current = args[0];
    final max = args[1];
    final scale = args[2];
    
    return WidthRatioNode(current, max, scale);
  }
}

class FilterTag extends TemplateTag {
  @override
  TemplateNode parse(TemplateParser parser, Token token, List<String> args) {
    if (args.isEmpty) {
      throw TemplateSyntaxException('Filter tag requires at least one filter');
    }
    
    final filters = args.join(' ');
    final nodes = parser.parseUntil(['endfilter']);
    
    final endToken = parser.consume();
    if (endToken == null || !endToken.content.startsWith('endfilter')) {
      throw TemplateSyntaxException('Expected endfilter tag');
    }
    
    return FilterNode(filters, nodes);
  }
}

class AutoEscapeTag extends TemplateTag {
  @override
  TemplateNode parse(TemplateParser parser, Token token, List<String> args) {
    final autoEscape = args.isNotEmpty ? args[0] == 'on' : true;
    final nodes = parser.parseUntil(['endautoescape']);
    
    final endToken = parser.consume();
    if (endToken == null || !endToken.content.startsWith('endautoescape')) {
      throw TemplateSyntaxException('Expected endautoescape tag');
    }
    
    return AutoEscapeNode(autoEscape, nodes);
  }
}

class IfBranch {
  final String condition;
  final List<TemplateNode> nodes;
  
  IfBranch(this.condition, this.nodes);
}