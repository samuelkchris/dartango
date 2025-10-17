
/// Base class for Flutter-to-HTML rendering
abstract class FlutterWidget {
  const FlutterWidget();
  
  /// Render this widget to HTML
  String render(Map<String, dynamic> context);
  
  /// Get CSS styles for this widget
  String? getStyles() => null;
  
  /// Get JavaScript for this widget
  String? getScripts() => null;
}

/// Text widget that renders to HTML
class Text extends FlutterWidget {
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final bool? softWrap;
  final TextOverflow? overflow;
  
  const Text(
    this.data, {
    this.style,
    this.textAlign,
    this.maxLines,
    this.softWrap,
    this.overflow,
  });
  
  @override
  String render(Map<String, dynamic> context) {
    final resolvedData = _resolveVariables(data, context);
    final cssClass = style?.toCssClass() ?? '';
    final alignClass = textAlign?.toCssClass() ?? '';
    final overflowClass = overflow?.toCssClass() ?? '';
    
    var classes = [cssClass, alignClass, overflowClass].where((c) => c.isNotEmpty).join(' ');
    classes = classes.isNotEmpty ? ' class="$classes"' : '';
    
    if (maxLines != null && maxLines! > 0) {
      return '<p$classes style="display: -webkit-box; -webkit-line-clamp: $maxLines; -webkit-box-orient: vertical; overflow: hidden;">$resolvedData</p>';
    }
    
    return '<p$classes>$resolvedData</p>';
  }
  
  String _resolveVariables(String text, Map<String, dynamic> context) {
    var resolved = text;
    final regex = RegExp(r'\{\{([^}]+)\}\}');
    resolved = resolved.replaceAllMapped(regex, (match) {
      final variable = match.group(1)?.trim();
      if (variable != null && context.containsKey(variable)) {
        return context[variable]?.toString() ?? '';
      }
      return match.group(0) ?? '';
    });
    return resolved;
  }
}

/// Container widget that renders to HTML div
class Container extends FlutterWidget {
  final FlutterWidget? child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Decoration? decoration;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;
  final BoxConstraints? constraints;
  
  const Container({
    this.child,
    this.padding,
    this.margin,
    this.color,
    this.decoration,
    this.width,
    this.height,
    this.alignment,
    this.constraints,
  });
  
  @override
  String render(Map<String, dynamic> context) {
    final styles = <String>[];
    
    if (width != null) styles.add('width: ${width}px');
    if (height != null) styles.add('height: ${height}px');
    if (color != null) styles.add('background-color: ${color!.toCss()}');
    if (padding != null) styles.add('padding: ${padding!.toCss()}');
    if (margin != null) styles.add('margin: ${margin!.toCss()}');
    if (alignment != null) styles.add(alignment!.toCss());
    if (decoration != null) styles.addAll(decoration!.toCss());
    
    final styleAttr = styles.isNotEmpty ? ' style="${styles.join('; ')}"' : '';
    final childHtml = child?.render(context) ?? '';
    
    return '<div$styleAttr>$childHtml</div>';
  }
}

/// Column widget that renders to HTML with flexbox
class Column extends FlutterWidget {
  final List<FlutterWidget> children;
  final MainAxisAlignment? mainAxisAlignment;
  final CrossAxisAlignment? crossAxisAlignment;
  final MainAxisSize? mainAxisSize;
  
  const Column({
    required this.children,
    this.mainAxisAlignment,
    this.crossAxisAlignment,
    this.mainAxisSize,
  });
  
  @override
  String render(Map<String, dynamic> context) {
    final styles = ['display: flex', 'flex-direction: column'];
    
    if (mainAxisAlignment != null) {
      styles.add('justify-content: ${mainAxisAlignment!.toCss()}');
    }
    if (crossAxisAlignment != null) {
      styles.add('align-items: ${crossAxisAlignment!.toCss()}');
    }
    
    final styleAttr = ' style="${styles.join('; ')}"';
    final childrenHtml = children.map((child) => child.render(context)).join('');
    
    return '<div$styleAttr>$childrenHtml</div>';
  }
}

/// Row widget that renders to HTML with flexbox
class Row extends FlutterWidget {
  final List<FlutterWidget> children;
  final MainAxisAlignment? mainAxisAlignment;
  final CrossAxisAlignment? crossAxisAlignment;
  final MainAxisSize? mainAxisSize;
  
  const Row({
    required this.children,
    this.mainAxisAlignment,
    this.crossAxisAlignment,
    this.mainAxisSize,
  });
  
  @override
  String render(Map<String, dynamic> context) {
    final styles = ['display: flex', 'flex-direction: row'];
    
    if (mainAxisAlignment != null) {
      styles.add('justify-content: ${mainAxisAlignment!.toCss()}');
    }
    if (crossAxisAlignment != null) {
      styles.add('align-items: ${crossAxisAlignment!.toCss()}');
    }
    
    final styleAttr = ' style="${styles.join('; ')}"';
    final childrenHtml = children.map((child) => child.render(context)).join('');
    
    return '<div$styleAttr>$childrenHtml</div>';
  }
}

/// Scaffold widget that renders to HTML page structure
class Scaffold extends FlutterWidget {
  final AppBar? appBar;
  final FlutterWidget? body;
  final FloatingActionButton? floatingActionButton;
  final BottomNavigationBar? bottomNavigationBar;
  final Color? backgroundColor;
  final bool? resizeToAvoidBottomInset;
  
  const Scaffold({
    this.appBar,
    this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.backgroundColor,
    this.resizeToAvoidBottomInset,
  });
  
  @override
  String render(Map<String, dynamic> context) {
    final appBarHtml = appBar?.render(context) ?? '';
    final bodyHtml = body?.render(context) ?? '';
    final fabHtml = floatingActionButton?.render(context) ?? '';
    final bottomNavHtml = bottomNavigationBar?.render(context) ?? '';
    
    final backgroundColor = this.backgroundColor?.toCss() ?? '#ffffff';
    
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dartango App</title>
    <style>
        ${_getDefaultStyles()}
    </style>
</head>
<body style="margin: 0; padding: 0; background-color: $backgroundColor;">
    <div class="scaffold">
        $appBarHtml
        <main class="scaffold-body">
            $bodyHtml
        </main>
        $fabHtml
        $bottomNavHtml
    </div>
</body>
</html>
    ''';
  }
  
  String _getDefaultStyles() {
    return '''
        .scaffold {
            display: flex;
            flex-direction: column;
            min-height: 100vh;
        }
        .scaffold-body {
            flex: 1;
            overflow: auto;
        }
        .floating-action-button {
            position: fixed;
            bottom: 16px;
            right: 16px;
            width: 56px;
            height: 56px;
            border-radius: 28px;
            border: none;
            cursor: pointer;
            box-shadow: 0 2px 10px rgba(0, 0, 0, 0.2);
            display: flex;
            align-items: center;
            justify-content: center;
        }
    ''';
  }
}

/// AppBar widget that renders to HTML header
class AppBar extends FlutterWidget {
  final FlutterWidget? title;
  final List<FlutterWidget>? actions;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final bool? centerTitle;
  
  const AppBar({
    this.title,
    this.actions,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.centerTitle,
  });
  
  @override
  String render(Map<String, dynamic> context) {
    final titleHtml = title?.render(context) ?? '';
    final actionsHtml = actions?.map((action) => action.render(context)).join('') ?? '';
    
    final styles = <String>[
      'display: flex',
      'align-items: center',
      'padding: 0 16px',
      'min-height: 56px',
      'background-color: ${backgroundColor?.toCss() ?? '#2196F3'}',
      'color: ${foregroundColor?.toCss() ?? '#ffffff'}',
    ];
    
    if (elevation != null && elevation! > 0) {
      styles.add('box-shadow: 0 ${elevation! * 2}px ${elevation! * 4}px rgba(0, 0, 0, 0.2)');
    }
    
    final titleAlignment = centerTitle == true ? 'justify-content: center' : 'justify-content: flex-start';
    
    return '''
      <header style="${styles.join('; ')}">
        <div style="flex: 1; $titleAlignment; display: flex; align-items: center;">
          $titleHtml
        </div>
        <div style="display: flex; align-items: center; gap: 8px;">
          $actionsHtml
        </div>
      </header>
    ''';
  }
}

/// ElevatedButton widget that renders to HTML button
class ElevatedButton extends FlutterWidget {
  final FlutterWidget child;
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  
  const ElevatedButton({
    required this.child,
    this.onPressed,
    this.style,
  });
  
  @override
  String render(Map<String, dynamic> context) {
    final childHtml = child.render(context);
    final disabled = onPressed == null;
    
    final styles = <String>[
      'padding: 8px 16px',
      'border: none',
      'border-radius: 4px',
      'cursor: ${disabled ? 'not-allowed' : 'pointer'}',
      'background-color: ${disabled ? '#e0e0e0' : '#2196F3'}',
      'color: ${disabled ? '#666666' : '#ffffff'}',
      'font-size: 14px',
      'font-weight: 500',
      'text-transform: uppercase',
      'letter-spacing: 0.5px',
    ];
    
    if (style != null) {
      styles.addAll(style!.toCss());
    }
    
    final disabledAttr = disabled ? ' disabled' : '';
    
    return '<button$disabledAttr style="${styles.join('; ')}">$childHtml</button>';
  }
}

/// Supporting classes for styling
class TextStyle {
  final Color? color;
  final double? fontSize;
  final FontWeight? fontWeight;
  final FontStyle? fontStyle;
  final String? fontFamily;
  final double? letterSpacing;
  final double? wordSpacing;
  final double? height;
  
  const TextStyle({
    this.color,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
    this.fontFamily,
    this.letterSpacing,
    this.wordSpacing,
    this.height,
  });
  
  String toCssClass() {
    return 'text-style-${hashCode.abs()}';
  }
}

class Color {
  final int value;
  
  const Color(this.value);
  
  static const Color transparent = Color(0x00000000);
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color red = Color(0xFFFF0000);
  static const Color green = Color(0xFF00FF00);
  static const Color blue = Color(0xFF0000FF);
  
  String toCss() {
    final a = (value >> 24) & 0xFF;
    final r = (value >> 16) & 0xFF;
    final g = (value >> 8) & 0xFF;
    final b = value & 0xFF;
    
    if (a == 0xFF) {
      return 'rgb($r, $g, $b)';
    } else {
      return 'rgba($r, $g, $b, ${a / 255.0})';
    }
  }
}

// Enums and supporting classes
enum TextAlign { left, right, center, justify, start, end }
enum TextOverflow { clip, ellipsis, fade, visible }
enum MainAxisAlignment { start, end, center, spaceBetween, spaceAround, spaceEvenly }
enum CrossAxisAlignment { start, end, center, stretch, baseline }
enum MainAxisSize { min, max }
enum FontWeight { w100, w200, w300, w400, w500, w600, w700, w800, w900, normal, bold }
enum FontStyle { normal, italic }

// Extension methods for CSS conversion
extension TextAlignExtension on TextAlign {
  String toCssClass() {
    switch (this) {
      case TextAlign.left:
        return 'text-left';
      case TextAlign.right:
        return 'text-right';
      case TextAlign.center:
        return 'text-center';
      case TextAlign.justify:
        return 'text-justify';
      case TextAlign.start:
        return 'text-start';
      case TextAlign.end:
        return 'text-end';
    }
  }
}

extension TextOverflowExtension on TextOverflow {
  String toCssClass() {
    switch (this) {
      case TextOverflow.ellipsis:
        return 'text-ellipsis';
      case TextOverflow.clip:
        return 'text-clip';
      case TextOverflow.fade:
        return 'text-fade';
      case TextOverflow.visible:
        return 'text-visible';
    }
  }
}

extension MainAxisAlignmentExtension on MainAxisAlignment {
  String toCss() {
    switch (this) {
      case MainAxisAlignment.start:
        return 'flex-start';
      case MainAxisAlignment.end:
        return 'flex-end';
      case MainAxisAlignment.center:
        return 'center';
      case MainAxisAlignment.spaceBetween:
        return 'space-between';
      case MainAxisAlignment.spaceAround:
        return 'space-around';
      case MainAxisAlignment.spaceEvenly:
        return 'space-evenly';
    }
  }
}

extension CrossAxisAlignmentExtension on CrossAxisAlignment {
  String toCss() {
    switch (this) {
      case CrossAxisAlignment.start:
        return 'flex-start';
      case CrossAxisAlignment.end:
        return 'flex-end';
      case CrossAxisAlignment.center:
        return 'center';
      case CrossAxisAlignment.stretch:
        return 'stretch';
      case CrossAxisAlignment.baseline:
        return 'baseline';
    }
  }
}

// Placeholder classes for completeness
class EdgeInsetsGeometry {
  String toCss() => '';
}

class EdgeInsets extends EdgeInsetsGeometry {
  final double top;
  final double right;
  final double bottom;
  final double left;
  
  EdgeInsets.all(double value) : top = value, right = value, bottom = value, left = value;
  EdgeInsets.symmetric({double vertical = 0, double horizontal = 0}) : top = vertical, right = horizontal, bottom = vertical, left = horizontal;
  EdgeInsets.only({this.top = 0, this.right = 0, this.bottom = 0, this.left = 0});
  
  @override
  String toCss() => '${top}px ${right}px ${bottom}px ${left}px';
}

class Decoration {
  List<String> toCss() => [];
}

class BoxDecoration extends Decoration {
  final Color? color;
  final Border? border;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;
  
  BoxDecoration({
    this.color,
    this.border,
    this.borderRadius,
    this.boxShadow,
  });
  
  @override
  List<String> toCss() {
    final styles = <String>[];
    
    if (color != null) styles.add('background-color: ${color!.toCss()}');
    if (border != null) styles.addAll(border!.toCss());
    if (borderRadius != null) styles.add('border-radius: ${borderRadius!.toCss()}');
    if (boxShadow != null) {
      final shadows = boxShadow!.map((shadow) => shadow.toCss()).join(', ');
      styles.add('box-shadow: $shadows');
    }
    
    return styles;
  }
}

class AlignmentGeometry {
  String toCss() => '';
}

class Alignment extends AlignmentGeometry {
  final double x;
  final double y;
  
  Alignment(this.x, this.y);
  
  static final Alignment topLeft = Alignment(-1, -1);
  static final Alignment topCenter = Alignment(0, -1);
  static final Alignment topRight = Alignment(1, -1);
  static final Alignment centerLeft = Alignment(-1, 0);
  static final Alignment center = Alignment(0, 0);
  static final Alignment centerRight = Alignment(1, 0);
  static final Alignment bottomLeft = Alignment(-1, 1);
  static final Alignment bottomCenter = Alignment(0, 1);
  static final Alignment bottomRight = Alignment(1, 1);
  
  @override
  String toCss() {
    final justifyContent = x == -1 ? 'flex-start' : x == 0 ? 'center' : 'flex-end';
    final alignItems = y == -1 ? 'flex-start' : y == 0 ? 'center' : 'flex-end';
    return 'display: flex; justify-content: $justifyContent; align-items: $alignItems';
  }
}

class BoxConstraints {
  final double minWidth;
  final double maxWidth;
  final double minHeight;
  final double maxHeight;
  
  const BoxConstraints({
    this.minWidth = 0,
    this.maxWidth = double.infinity,
    this.minHeight = 0,
    this.maxHeight = double.infinity,
  });
}

class VoidCallback {
  final Function() callback;
  const VoidCallback(this.callback);
}

class ButtonStyle {
  List<String> toCss() => [];
}

class FloatingActionButton extends FlutterWidget {
  final VoidCallback? onPressed;
  final FlutterWidget? child;
  final Color? backgroundColor;
  final Color? foregroundColor;
  
  const FloatingActionButton({
    this.onPressed,
    this.child,
    this.backgroundColor,
    this.foregroundColor,
  });
  
  @override
  String render(Map<String, dynamic> context) {
    final childHtml = child?.render(context) ?? '';
    final bgColor = backgroundColor?.toCss() ?? '#2196F3';
    final fgColor = foregroundColor?.toCss() ?? '#ffffff';
    
    return '''
      <button class="floating-action-button" style="background-color: $bgColor; color: $fgColor;">
        $childHtml
      </button>
    ''';
  }
}

class BottomNavigationBar extends FlutterWidget {
  final List<BottomNavigationBarItem> items;
  final int currentIndex;
  final ValueChanged<int>? onTap;
  
  const BottomNavigationBar({
    required this.items,
    this.currentIndex = 0,
    this.onTap,
  });
  
  @override
  String render(Map<String, dynamic> context) {
    final itemsHtml = items.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final isActive = index == currentIndex;
      
      return '''
        <div class="bottom-nav-item ${isActive ? 'active' : ''}" onclick="selectTab($index)">
          ${item.icon.render(context)}
          <span>${item.label}</span>
        </div>
      ''';
    }).join('');
    
    return '''
      <nav class="bottom-navigation-bar">
        $itemsHtml
      </nav>
    ''';
  }
}

class BottomNavigationBarItem {
  final FlutterWidget icon;
  final String label;
  final FlutterWidget? activeIcon;
  
  const BottomNavigationBarItem({
    required this.icon,
    required this.label,
    this.activeIcon,
  });
}

class ValueChanged<T> {
  final Function(T) callback;
  const ValueChanged(this.callback);
}

// Placeholder classes for borders and shadows
class Border {
  List<String> toCss() => [];
}

class BorderRadius {
  String toCss() => '';
}

class BoxShadow {
  String toCss() => '';
}