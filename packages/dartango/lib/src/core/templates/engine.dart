import 'dart:async';

import 'context.dart';
import 'filters.dart';
import 'tags.dart';
import 'loader.dart';
import 'nodes.dart';
import 'exceptions.dart';

class TemplateEngine {
  static TemplateEngine? _instance;
  static TemplateEngine get instance => _instance ??= TemplateEngine._();

  TemplateEngine._();

  final List<TemplateLoader> _loaders = [];
  final Map<String, Template> _templateCache = {};
  final Map<String, TemplateFilter> _filters = {};
  final Map<String, TemplateTag> _tags = {};
  bool _debug = false;

  void addLoader(TemplateLoader loader) {
    _loaders.add(loader);
  }

  void addFilter(String name, TemplateFilter filter) {
    _filters[name] = filter;
  }

  void addTag(String name, TemplateTag tag) {
    _tags[name] = tag;
  }

  void setDebug(bool debug) {
    _debug = debug;
  }

  void clearCache() {
    _templateCache.clear();
  }

  Template getTemplate(String name) {
    if (_templateCache.containsKey(name) && !_debug) {
      return _templateCache[name]!;
    }

    String? source;
    String? origin;

    for (final loader in _loaders) {
      try {
        final result = loader.loadTemplate(name);
        source = result.source;
        origin = result.origin;
        break;
      } catch (e) {
        continue;
      }
    }

    if (source == null) {
      throw TemplateNotFoundException('Template "$name" not found');
    }

    final template = Template(name, source, origin: origin);

    if (!_debug) {
      _templateCache[name] = template;
    }

    return template;
  }

  bool hasFilter(String name) {
    return _filters.containsKey(name);
  }

  TemplateFilter getFilter(String name) {
    if (!_filters.containsKey(name)) {
      throw TemplateException('Filter "$name" not found');
    }
    return _filters[name]!;
  }

  bool hasTag(String name) {
    return _tags.containsKey(name);
  }

  TemplateTag getTag(String name) {
    if (!_tags.containsKey(name)) {
      throw TemplateException('Tag "$name" not found');
    }
    return _tags[name]!;
  }

  void configure() {
    _configureDefaultFilters();
    _configureDefaultTags();
    _configureDefaultLoaders();
  }

  void _configureDefaultFilters() {
    addFilter('default', DefaultFilter());
    addFilter('length', LengthFilter());
    addFilter('upper', UpperFilter());
    addFilter('lower', LowerFilter());
    addFilter('title', TitleFilter());
    addFilter('date', DateFilter());
    addFilter('time', TimeFilter());
    addFilter('truncate', TruncateFilter());
    addFilter('escape', EscapeFilter());
    addFilter('safe', SafeFilter());
    addFilter('json', JsonFilter());
    addFilter('join', JoinFilter());
    addFilter('reverse', ReverseFilter());
    addFilter('slice', SliceFilter());
    addFilter('first', FirstFilter());
    addFilter('last', LastFilter());
    addFilter('add', AddFilter());
    addFilter('subtract', SubtractFilter());
    addFilter('multiply', MultiplyFilter());
    addFilter('divide', DivideFilter());
    addFilter('modulo', ModuloFilter());
    addFilter('yesno', YesNoFilter());
    addFilter('pluralize', PluralizeFilter());
    addFilter('linebreaks', LinebreaksFilter());
    addFilter('striptags', StripTagsFilter());
    addFilter('urlencode', UrlEncodeFilter());
    addFilter('wordcount', WordCountFilter());
  }

  void _configureDefaultTags() {
    addTag('if', IfTag());
    addTag('for', ForTag());
    addTag('with', WithTag());
    addTag('include', IncludeTag());
    addTag('extends', ExtendsTag());
    addTag('block', BlockTag());
    addTag('comment', CommentTag());
    addTag('csrf_token', CsrfTokenTag());
    addTag('url', UrlTag());
    addTag('static', StaticTag());
    addTag('load', LoadTag());
    addTag('spaceless', SpacelessTag());
    addTag('verbatim', VerbatimTag());
    addTag('now', NowTag());
    addTag('regroup', RegroupTag());
    addTag('cycle', CycleTag());
    addTag('firstof', FirstOfTag());
    addTag('ifchanged', IfChangedTag());
    addTag('templatetag', TemplateTagTag());
    addTag('widthratio', WidthRatioTag());
    addTag('filter', FilterTag());
    addTag('autoescape', AutoEscapeTag());
  }

  void _configureDefaultLoaders() {
    addLoader(FileSystemLoader(['templates']));
  }
}

class Template {
  final String name;
  final String source;
  final String? origin;
  late final TemplateNode rootNode;

  Template(this.name, this.source, {this.origin}) {
    rootNode = _parse();
  }

  Future<String> render(TemplateContext context) async {
    try {
      return await rootNode.render(context);
    } catch (e) {
      if (TemplateEngine.instance._debug) {
        rethrow;
      }
      return 'Template rendering error: $e';
    }
  }

  TemplateNode _parse() {
    final lexer = TemplateLexer(source);
    final tokens = lexer.tokenize();
    final parser = TemplateParser(tokens);
    return parser.parse();
  }
}

class TemplateLexer {
  final String source;
  int position = 0;
  int line = 1;
  int column = 1;

  TemplateLexer(this.source);

  List<Token> tokenize() {
    final tokens = <Token>[];

    while (position < source.length) {
      final token = _nextToken();
      if (token != null) {
        tokens.add(token);
      }
    }

    return tokens;
  }

  Token? _nextToken() {
    if (position >= source.length) {
      return null;
    }

    final char = source[position];

    if (char == '{') {
      if (position + 1 < source.length) {
        final nextChar = source[position + 1];
        if (nextChar == '{') {
          return _readVariable();
        } else if (nextChar == '%') {
          return _readTag();
        } else if (nextChar == '#') {
          return _readComment();
        }
      }
    }

    return _readText();
  }

  Token _readText() {
    final start = position;
    final startLine = line;
    final startColumn = column;

    while (position < source.length && source[position] != '{') {
      _advance();
    }

    final content = source.substring(start, position);
    return Token(TokenType.text, content, startLine, startColumn);
  }

  Token _readVariable() {
    final startLine = line;
    final startColumn = column;

    position += 2; // Skip {{
    final start = position;

    while (position < source.length - 1 &&
        !(source[position] == '}' && source[position + 1] == '}')) {
      _advance();
    }

    final content = source.substring(start, position).trim();
    position += 2; // Skip }}

    return Token(TokenType.variable, content, startLine, startColumn);
  }

  Token _readTag() {
    final startLine = line;
    final startColumn = column;

    position += 2; // Skip {%
    final start = position;

    while (position < source.length - 1 &&
        !(source[position] == '%' && source[position + 1] == '}')) {
      _advance();
    }

    final content = source.substring(start, position).trim();
    position += 2; // Skip %}

    return Token(TokenType.tag, content, startLine, startColumn);
  }

  Token _readComment() {
    final startLine = line;
    final startColumn = column;

    position += 2; // Skip {#
    final start = position;

    while (position < source.length - 1 &&
        !(source[position] == '#' && source[position + 1] == '}')) {
      _advance();
    }

    final content = source.substring(start, position).trim();
    position += 2; // Skip #}

    return Token(TokenType.comment, content, startLine, startColumn);
  }

  void _advance() {
    if (position < source.length && source[position] == '\n') {
      line++;
      column = 1;
    } else {
      column++;
    }
    position++;
  }
}

class TemplateParser {
  final List<Token> tokens;
  int position = 0;

  TemplateParser(this.tokens);

  TemplateNode parse() {
    final nodes = <TemplateNode>[];

    while (position < tokens.length) {
      final node = _parseNode();
      if (node != null) {
        nodes.add(node);
      }
    }

    return NodeList(nodes);
  }

  TemplateNode? _parseNode() {
    if (position >= tokens.length) {
      return null;
    }

    final token = tokens[position];

    switch (token.type) {
      case TokenType.text:
        position++;
        return TextNode(token.content);

      case TokenType.variable:
        position++;
        return VariableNode(token.content);

      case TokenType.tag:
        return _parseTag(token);

      case TokenType.comment:
        position++;
        return CommentNode(token.content);
    }
  }

  TemplateNode _parseTag(Token token) {
    final parts = token.content.split(RegExp(r'\s+'));
    final tagName = parts[0];
    final args = parts.sublist(1);

    if (TemplateEngine.instance.hasTag(tagName)) {
      final tag = TemplateEngine.instance.getTag(tagName);
      position++;
      return tag.parse(this, token, args);
    }

    throw TemplateException('Unknown tag: $tagName');
  }

  Token? peek() {
    if (position < tokens.length) {
      return tokens[position];
    }
    return null;
  }

  Token? consume() {
    if (position < tokens.length) {
      return tokens[position++];
    }
    return null;
  }

  List<TemplateNode> parseUntil(List<String> endTags) {
    final nodes = <TemplateNode>[];

    while (position < tokens.length) {
      final token = peek();
      if (token != null && token.type == TokenType.tag) {
        final parts = token.content.split(RegExp(r'\s+'));
        final tagName = parts[0];

        if (endTags.contains(tagName)) {
          break;
        }
      }

      final node = _parseNode();
      if (node != null) {
        nodes.add(node);
      }
    }

    return nodes;
  }
}

enum TokenType {
  text,
  variable,
  tag,
  comment,
}

class Token {
  final TokenType type;
  final String content;
  final int line;
  final int column;

  Token(this.type, this.content, this.line, this.column);

  @override
  String toString() => 'Token($type, "$content", $line:$column)';
}

class TemplateResult {
  final String content;
  final bool isSafe;

  TemplateResult(this.content, {this.isSafe = false});

  @override
  String toString() => content;
}

class SafeString extends TemplateResult {
  SafeString(String content) : super(content, isSafe: true);
}

String escapeHtml(String text) {
  return text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#x27;');
}

extension TemplateString on String {
  String escape() => escapeHtml(this);
  SafeString safe() => SafeString(this);
}
