class TemplateException implements Exception {
  final String message;
  final String? templateName;
  final int? line;
  final int? column;

  TemplateException(this.message, {this.templateName, this.line, this.column});

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('TemplateException: $message');

    if (templateName != null) {
      buffer.write(' in template "$templateName"');
    }

    if (line != null) {
      buffer.write(' at line $line');
      if (column != null) {
        buffer.write(', column $column');
      }
    }

    return buffer.toString();
  }
}

class TemplateNotFoundException extends TemplateException {
  TemplateNotFoundException(String message,
      {String? templateName, int? line, int? column})
      : super(message, templateName: templateName, line: line, column: column);
}

class TemplateSyntaxException extends TemplateException {
  TemplateSyntaxException(String message,
      {String? templateName, int? line, int? column})
      : super(message, templateName: templateName, line: line, column: column);
}

class TemplateRuntimeException extends TemplateException {
  TemplateRuntimeException(String message,
      {String? templateName, int? line, int? column})
      : super(message, templateName: templateName, line: line, column: column);
}

class TemplateVariableException extends TemplateException {
  final String variableName;

  TemplateVariableException(this.variableName, String message,
      {String? templateName, int? line, int? column})
      : super(message, templateName: templateName, line: line, column: column);
}

class TemplateFilterException extends TemplateException {
  final String filterName;

  TemplateFilterException(this.filterName, String message,
      {String? templateName, int? line, int? column})
      : super(message, templateName: templateName, line: line, column: column);
}

class TemplateTagException extends TemplateException {
  final String tagName;

  TemplateTagException(this.tagName, String message,
      {String? templateName, int? line, int? column})
      : super(message, templateName: templateName, line: line, column: column);
}

class TemplateInheritanceException extends TemplateException {
  TemplateInheritanceException(String message,
      {String? templateName, int? line, int? column})
      : super(message, templateName: templateName, line: line, column: column);
}

class TemplateIncludeException extends TemplateException {
  final String includedTemplate;

  TemplateIncludeException(this.includedTemplate, String message,
      {String? templateName, int? line, int? column})
      : super(message, templateName: templateName, line: line, column: column);
}

class TemplateSecurityException extends TemplateException {
  TemplateSecurityException(String message,
      {String? templateName, int? line, int? column})
      : super(message, templateName: templateName, line: line, column: column);
}

class TemplateContextException extends TemplateException {
  TemplateContextException(String message,
      {String? templateName, int? line, int? column})
      : super(message, templateName: templateName, line: line, column: column);
}

class TemplateLoaderException extends TemplateException {
  TemplateLoaderException(String message,
      {String? templateName, int? line, int? column})
      : super(message, templateName: templateName, line: line, column: column);
}

class TemplateCompilationException extends TemplateException {
  TemplateCompilationException(String message,
      {String? templateName, int? line, int? column})
      : super(message, templateName: templateName, line: line, column: column);
}

class TemplateRenderingException extends TemplateException {
  final Exception originalException;

  TemplateRenderingException(this.originalException, String message,
      {String? templateName, int? line, int? column})
      : super(message, templateName: templateName, line: line, column: column);
}
