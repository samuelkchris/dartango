import 'dart:io';
import 'dart:math' as math;

/// Verbosity level for command output
enum VerbosityLevel {
  /// Only show errors
  quiet,

  /// Show normal output (default)
  normal,

  /// Show detailed output
  verbose,

  /// Show debug level output
  debug,
}

/// ANSI color codes for terminal output
class AnsiColors {
  static const String reset = '\x1B[0m';
  static const String bold = '\x1B[1m';
  static const String dim = '\x1B[2m';
  static const String italic = '\x1B[3m';
  static const String underline = '\x1B[4m';

  static const String black = '\x1B[30m';
  static const String red = '\x1B[31m';
  static const String green = '\x1B[32m';
  static const String yellow = '\x1B[33m';
  static const String blue = '\x1B[34m';
  static const String magenta = '\x1B[35m';
  static const String cyan = '\x1B[36m';
  static const String white = '\x1B[37m';

  static const String bgBlack = '\x1B[40m';
  static const String bgRed = '\x1B[41m';
  static const String bgGreen = '\x1B[42m';
  static const String bgYellow = '\x1B[43m';
  static const String bgBlue = '\x1B[44m';
  static const String bgMagenta = '\x1B[45m';
  static const String bgCyan = '\x1B[46m';
  static const String bgWhite = '\x1B[47m';

  static const String brightBlack = '\x1B[90m';
  static const String brightRed = '\x1B[91m';
  static const String brightGreen = '\x1B[92m';
  static const String brightYellow = '\x1B[93m';
  static const String brightBlue = '\x1B[94m';
  static const String brightMagenta = '\x1B[95m';
  static const String brightCyan = '\x1B[96m';
  static const String brightWhite = '\x1B[97m';

  /// Check if ANSI colors are supported
  static bool get isSupported {
    return stdout.supportsAnsiEscapes;
  }

  /// Colorize text
  static String colorize(String text, String color) {
    if (!isSupported) return text;
    return '$color$text$reset';
  }

  /// Apply multiple styles
  static String style(String text, List<String> styles) {
    if (!isSupported) return text;
    final styleCode = styles.join('');
    return '$styleCode$text$reset';
  }
}

/// Progress bar for long-running operations
class ProgressBar {
  final int total;
  final int width;
  final String prefix;
  final String suffix;
  final String fillChar;
  final String emptyChar;
  final bool showPercentage;
  final bool showCount;

  int _current = 0;
  DateTime? _startTime;

  ProgressBar({
    required this.total,
    this.width = 40,
    this.prefix = '',
    this.suffix = '',
    this.fillChar = '█',
    this.emptyChar = '░',
    this.showPercentage = true,
    this.showCount = true,
  });

  /// Update progress
  void update(int current) {
    _startTime ??= DateTime.now();
    _current = current;
    _render();
  }

  /// Increment progress by 1
  void increment() {
    update(_current + 1);
  }

  /// Complete the progress bar
  void complete() {
    update(total);
    stdout.writeln();
  }

  void _render() {
    final percent = _current / total;
    final filled = (width * percent).round();
    final empty = width - filled;

    final bar = fillChar * filled + emptyChar * empty;

    final parts = <String>[];

    if (prefix.isNotEmpty) parts.add(prefix);

    parts.add('|$bar|');

    if (showPercentage) {
      parts.add('${(percent * 100).toStringAsFixed(1)}%');
    }

    if (showCount) {
      parts.add('$_current/$total');
    }

    if (_startTime != null && _current > 0) {
      final elapsed = DateTime.now().difference(_startTime!);
      final rate = _current / elapsed.inSeconds;
      if (rate > 0) {
        final remaining = ((total - _current) / rate).round();
        parts.add(_formatDuration(Duration(seconds: remaining)));
      }
    }

    if (suffix.isNotEmpty) parts.add(suffix);

    stdout.write('\r${parts.join(' ')}');
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}

/// Spinner for indeterminate progress
class Spinner {
  static const List<String> _frames = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'];
  final String message;

  int _frameIndex = 0;
  bool _running = false;

  Spinner(this.message);

  /// Start the spinner
  void start() {
    _running = true;
    _spin();
  }

  /// Stop the spinner
  void stop({String? finalMessage}) {
    _running = false;
    stdout.write('\r${' ' * (message.length + 10)}\r');
    if (finalMessage != null) {
      stdout.writeln(finalMessage);
    }
  }

  void _spin() async {
    while (_running) {
      final frame = _frames[_frameIndex];
      stdout.write('\r$frame $message');
      _frameIndex = (_frameIndex + 1) % _frames.length;
      await Future.delayed(const Duration(milliseconds: 80));
    }
  }
}

/// Table formatter for structured data
class Table {
  final List<String> headers;
  final List<List<String>> rows;
  final TableStyle style;
  final bool showBorders;
  final bool showHeaders;
  final int maxColumnWidth;

  Table({
    required this.headers,
    required this.rows,
    this.style = TableStyle.box,
    this.showBorders = true,
    this.showHeaders = true,
    this.maxColumnWidth = 50,
  });

  /// Render the table
  String render() {
    if (rows.isEmpty && !showHeaders) return '';

    final columnWidths = _calculateColumnWidths();
    final buffer = StringBuffer();

    if (showBorders) {
      buffer.writeln(_renderBorder(columnWidths, BorderType.top));
    }

    if (showHeaders) {
      buffer.writeln(_renderRow(headers, columnWidths, isHeader: true));
      if (showBorders) {
        buffer.writeln(_renderBorder(columnWidths, BorderType.middle));
      }
    }

    for (var i = 0; i < rows.length; i++) {
      buffer.writeln(_renderRow(rows[i], columnWidths));
      if (showBorders && i < rows.length - 1 && style == TableStyle.grid) {
        buffer.writeln(_renderBorder(columnWidths, BorderType.middle));
      }
    }

    if (showBorders) {
      buffer.writeln(_renderBorder(columnWidths, BorderType.bottom));
    }

    return buffer.toString();
  }

  List<int> _calculateColumnWidths() {
    final widths = List<int>.filled(headers.length, 0);

    for (var i = 0; i < headers.length; i++) {
      widths[i] = math.min(headers[i].length, maxColumnWidth);
    }

    for (final row in rows) {
      for (var i = 0; i < math.min(row.length, headers.length); i++) {
        widths[i] = math.max(
          widths[i],
          math.min(row[i].length, maxColumnWidth),
        );
      }
    }

    return widths;
  }

  String _renderRow(List<String> cells, List<int> widths, {bool isHeader = false}) {
    final parts = <String>[];

    if (showBorders) {
      parts.add(style.vertical);
    }

    for (var i = 0; i < math.min(cells.length, widths.length); i++) {
      var cell = _truncate(cells[i], widths[i]);
      cell = cell.padRight(widths[i]);

      if (isHeader && AnsiColors.isSupported) {
        cell = AnsiColors.colorize(cell, AnsiColors.bold);
      }

      parts.add(' $cell ');

      if (showBorders && i < cells.length - 1) {
        parts.add(style.vertical);
      }
    }

    if (showBorders) {
      parts.add(style.vertical);
    }

    return parts.join();
  }

  String _renderBorder(List<int> widths, BorderType type) {
    final parts = <String>[];

    switch (type) {
      case BorderType.top:
        parts.add(style.topLeft);
        for (var i = 0; i < widths.length; i++) {
          parts.add(style.horizontal * (widths[i] + 2));
          if (i < widths.length - 1) {
            parts.add(style.topMiddle);
          }
        }
        parts.add(style.topRight);
        break;

      case BorderType.middle:
        parts.add(style.middleLeft);
        for (var i = 0; i < widths.length; i++) {
          parts.add(style.horizontal * (widths[i] + 2));
          if (i < widths.length - 1) {
            parts.add(style.middle);
          }
        }
        parts.add(style.middleRight);
        break;

      case BorderType.bottom:
        parts.add(style.bottomLeft);
        for (var i = 0; i < widths.length; i++) {
          parts.add(style.horizontal * (widths[i] + 2));
          if (i < widths.length - 1) {
            parts.add(style.bottomMiddle);
          }
        }
        parts.add(style.bottomRight);
        break;
    }

    return parts.join();
  }

  String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }
}

/// Table border styles
enum TableStyle {
  box,
  grid,
  simple,
  minimal,
}

extension TableStyleExtension on TableStyle {
  String get horizontal {
    switch (this) {
      case TableStyle.box:
      case TableStyle.grid:
        return '─';
      case TableStyle.simple:
        return '-';
      case TableStyle.minimal:
        return ' ';
    }
  }

  String get vertical {
    switch (this) {
      case TableStyle.box:
      case TableStyle.grid:
        return '│';
      case TableStyle.simple:
        return '|';
      case TableStyle.minimal:
        return ' ';
    }
  }

  String get topLeft {
    switch (this) {
      case TableStyle.box:
      case TableStyle.grid:
        return '┌';
      case TableStyle.simple:
        return '+';
      case TableStyle.minimal:
        return ' ';
    }
  }

  String get topRight {
    switch (this) {
      case TableStyle.box:
      case TableStyle.grid:
        return '┐';
      case TableStyle.simple:
        return '+';
      case TableStyle.minimal:
        return ' ';
    }
  }

  String get bottomLeft {
    switch (this) {
      case TableStyle.box:
      case TableStyle.grid:
        return '└';
      case TableStyle.simple:
        return '+';
      case TableStyle.minimal:
        return ' ';
    }
  }

  String get bottomRight {
    switch (this) {
      case TableStyle.box:
      case TableStyle.grid:
        return '┘';
      case TableStyle.simple:
        return '+';
      case TableStyle.minimal:
        return ' ';
    }
  }

  String get topMiddle {
    switch (this) {
      case TableStyle.box:
      case TableStyle.grid:
        return '┬';
      case TableStyle.simple:
        return '+';
      case TableStyle.minimal:
        return ' ';
    }
  }

  String get bottomMiddle {
    switch (this) {
      case TableStyle.box:
      case TableStyle.grid:
        return '┴';
      case TableStyle.simple:
        return '+';
      case TableStyle.minimal:
        return ' ';
    }
  }

  String get middleLeft {
    switch (this) {
      case TableStyle.box:
      case TableStyle.grid:
        return '├';
      case TableStyle.simple:
        return '+';
      case TableStyle.minimal:
        return ' ';
    }
  }

  String get middleRight {
    switch (this) {
      case TableStyle.box:
      case TableStyle.grid:
        return '┤';
      case TableStyle.simple:
        return '+';
      case TableStyle.minimal:
        return ' ';
    }
  }

  String get middle {
    switch (this) {
      case TableStyle.box:
      case TableStyle.grid:
        return '┼';
      case TableStyle.simple:
        return '+';
      case TableStyle.minimal:
        return ' ';
    }
  }
}

enum BorderType { top, middle, bottom }

/// Output formatter with verbosity support
class CommandOutput {
  final VerbosityLevel verbosity;
  final bool useColors;

  CommandOutput({
    this.verbosity = VerbosityLevel.normal,
    this.useColors = true,
  });

  /// Print message based on verbosity level
  void log(String message, {VerbosityLevel level = VerbosityLevel.normal}) {
    if (_shouldPrint(level)) {
      stdout.writeln(message);
    }
  }

  /// Print success message
  void success(String message, {VerbosityLevel level = VerbosityLevel.normal}) {
    if (_shouldPrint(level)) {
      final output = useColors && AnsiColors.isSupported
          ? AnsiColors.colorize(message, AnsiColors.green)
          : message;
      stdout.writeln(output);
    }
  }

  /// Print error message
  void error(String message) {
    final output = useColors && AnsiColors.isSupported
        ? AnsiColors.colorize(message, AnsiColors.red)
        : message;
    stderr.writeln(output);
  }

  /// Print warning message
  void warning(String message, {VerbosityLevel level = VerbosityLevel.normal}) {
    if (_shouldPrint(level)) {
      final output = useColors && AnsiColors.isSupported
          ? AnsiColors.colorize(message, AnsiColors.yellow)
          : message;
      stdout.writeln(output);
    }
  }

  /// Print info message
  void info(String message, {VerbosityLevel level = VerbosityLevel.normal}) {
    if (_shouldPrint(level)) {
      final output = useColors && AnsiColors.isSupported
          ? AnsiColors.colorize(message, AnsiColors.blue)
          : message;
      stdout.writeln(output);
    }
  }

  /// Print debug message
  void debug(String message) {
    if (verbosity == VerbosityLevel.debug) {
      final output = useColors && AnsiColors.isSupported
          ? AnsiColors.colorize('[DEBUG] $message', AnsiColors.dim)
          : '[DEBUG] $message';
      stdout.writeln(output);
    }
  }

  bool _shouldPrint(VerbosityLevel level) {
    if (verbosity == VerbosityLevel.quiet) {
      return false;
    }

    switch (level) {
      case VerbosityLevel.quiet:
        return true;
      case VerbosityLevel.normal:
        return verbosity.index >= VerbosityLevel.normal.index;
      case VerbosityLevel.verbose:
        return verbosity.index >= VerbosityLevel.verbose.index;
      case VerbosityLevel.debug:
        return verbosity == VerbosityLevel.debug;
    }
  }
}
