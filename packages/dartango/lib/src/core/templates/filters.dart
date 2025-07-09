import 'dart:convert';

import 'context.dart';
import 'exceptions.dart';

abstract class TemplateFilter {
  dynamic apply(dynamic value, List<String> args, TemplateContext context);
}

class DefaultFilter extends TemplateFilter {
  @override
  dynamic apply(dynamic value, List<String> args, TemplateContext context) {
    if (value == null || value == '') {
      return args.isNotEmpty ? args[0] : '';
    }
    return value;
  }
}

class LengthFilter extends TemplateFilter {
  @override
  dynamic apply(dynamic value, List<String> args, TemplateContext context) {
    if (value == null) return 0;
    
    if (value is String) return value.length;
    if (value is List) return value.length;
    if (value is Map) return value.length;
    
    return 0;
  }
}

class UpperFilter extends TemplateFilter {
  @override
  dynamic apply(dynamic value, List<String> args, TemplateContext context) {
    return value?.toString().toUpperCase() ?? '';
  }
}

class LowerFilter extends TemplateFilter {
  @override
  dynamic apply(dynamic value, List<String> args, TemplateContext context) {
    return value?.toString().toLowerCase() ?? '';
  }
}

class TitleFilter extends TemplateFilter {
  @override
  dynamic apply(dynamic value, List<String> args, TemplateContext context) {
    if (value == null) return '';
    
    final str = value.toString();
    return str.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}

class DateFilter extends TemplateFilter {
  @override
  dynamic apply(dynamic value, List<String> args, TemplateContext context) {
    if (value == null) return '';
    
    DateTime date;
    if (value is DateTime) {
      date = value;
    } else if (value is String) {
      try {
        date = DateTime.parse(value);
      } catch (e) {
        return value;
      }
    } else {
      return value;
    }
    
    final format = args.isNotEmpty ? args[0] : 'yyyy-MM-dd';
    
    return _formatDate(date, format);
  }
  
  String _formatDate(DateTime date, String format) {
    return format
        .replaceAll('yyyy', date.year.toString())
        .replaceAll('MM', date.month.toString().padLeft(2, '0'))
        .replaceAll('dd', date.day.toString().padLeft(2, '0'))
        .replaceAll('HH', date.hour.toString().padLeft(2, '0'))
        .replaceAll('mm', date.minute.toString().padLeft(2, '0'))
        .replaceAll('ss', date.second.toString().padLeft(2, '0'));
  }
}

class TimeFilter extends TemplateFilter {
  @override
  dynamic apply(dynamic value, List<String> args, TemplateContext context) {
    if (value == null) return '';
    
    DateTime date;
    if (value is DateTime) {
      date = value;
    } else if (value is String) {
      try {
        date = DateTime.parse(value);
      } catch (e) {
        return value;
      }
    } else {
      return value;
    }
    
    final format = args.isNotEmpty ? args[0] : 'HH:mm:ss';
    
    return _formatTime(date, format);
  }
  
  String _formatTime(DateTime date, String format) {
    return format
        .replaceAll('HH', date.hour.toString().padLeft(2, '0'))
        .replaceAll('mm', date.minute.toString().padLeft(2, '0'))
        .replaceAll('ss', date.second.toString().padLeft(2, '0'));
  }
}

class TruncateFilter extends TemplateFilter {
  @override
  dynamic apply(dynamic value, List<String> args, TemplateContext context) {
    if (value == null) return '';
    
    final str = value.toString();
    final length = args.isNotEmpty ? int.tryParse(args[0]) ?? 30 : 30;
    
    if (str.length <= length) return str;
    
    return '${str.substring(0, length)}...';
  }
}

class EscapeFilter extends TemplateFilter {
  @override
  dynamic apply(dynamic value, List<String> args, TemplateContext context) {
    if (value == null) return '';
    
    return _escapeHtml(value.toString());
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

class SafeFilter extends TemplateFilter {
  @override
  dynamic apply(dynamic value, List<String> args, TemplateContext context) {
    return value;
  }
}

class JsonFilter extends TemplateFilter {
  @override
  dynamic apply(dynamic value, List<String> args, TemplateContext context) {
    try {
      return json.encode(value);
    } catch (e) {
      return value?.toString() ?? '';
    }
  }
}

class JoinFilter extends TemplateFilter {
  @override
  dynamic apply(dynamic value, List<String> args, TemplateContext context) {
    if (value == null) return '';
    
    if (value is List) {
      final separator = args.isNotEmpty ? args[0] : ', ';
      return value.map((e) => e.toString()).join(separator);
    }
    
    return value.toString();
  }
}

class ReverseFilter extends TemplateFilter {
  @override
  dynamic apply(dynamic value, List<String> args, TemplateContext context) {
    if (value == null) return '';
    
    if (value is List) {
      return value.reversed.toList();
    }
    
    if (value is String) {
      return value.split('').reversed.join('');
    }
    
    return value;
  }
}

class SliceFilter extends TemplateFilter {
  @override
  dynamic apply(dynamic value, List<String> args, TemplateContext context) {
    if (value == null) return '';
    
    if (args.isEmpty) return value;
    
    final parts = args[0].split(':');
    int start = 0;
    int? end;
    
    if (parts.isNotEmpty && parts[0].isNotEmpty) {
      start = int.tryParse(parts[0]) ?? 0;
    }
    
    if (parts.length > 1 && parts[1].isNotEmpty) {
      end = int.tryParse(parts[1]);
    }
    
    if (value is String) {
      final str = value;
      if (start < 0) start = str.length + start;
      if (end != null && end < 0) end = str.length + end;
      
      return str.substring(start, end ?? str.length);
    }
    
    if (value is List) {
      final list = value;
      if (start < 0) start = list.length + start;
      if (end != null && end < 0) end = list.length + end;
      
      return list.sublist(start, end ?? list.length);
    }
    
    return value;
  }
}

class FirstFilter extends TemplateFilter {
  @override
  dynamic apply(dynamic value, List<String> args, TemplateContext context) {
    if (value == null) return '';
    
    if (value is List && value.isNotEmpty) {
      return value.first;
    }
    
    if (value is String && value.isNotEmpty) {
      return value[0];
    }
    
    return '';
  }
}

class LastFilter extends TemplateFilter {
  @override
  dynamic apply(dynamic value, List<String> args, TemplateContext context) {
    if (value == null) return '';
    
    if (value is List && value.isNotEmpty) {
      return value.last;
    }
    
    if (value is String && value.isNotEmpty) {
      return value[value.length - 1];
    }
    
    return '';
  }
}

class AddFilter extends TemplateFilter {
  @override
  dynamic apply(dynamic value, List<String> args, TemplateContext context) {
    if (args.isEmpty) return value;
    
    final addValue = args[0];
    
    if (value is num) {
      final num = double.tryParse(addValue) ?? int.tryParse(addValue) ?? 0;
      return value + num;
    }
    
    if (value is String) {
      return value + addValue;
    }
    
    if (value is List) {
      return [...value, addValue];
    }
    
    return value;
  }
}

class SubtractFilter extends TemplateFilter {
  @override
  dynamic apply(dynamic value, List<String> args, TemplateContext context) {
    if (args.isEmpty) return value;
    
    final subtractValue = args[0];
    
    if (value is num) {
      final num = double.tryParse(subtractValue) ?? int.tryParse(subtractValue) ?? 0;
      return value - num;
    }
    
    return value;
  }
}

class MultiplyFilter extends TemplateFilter {
  @override
  dynamic apply(dynamic value, List<String> args, TemplateContext context) {
    if (args.isEmpty) return value;
    
    final multiplyValue = args[0];
    
    if (value is num) {
      final num = double.tryParse(multiplyValue) ?? int.tryParse(multiplyValue) ?? 1;
      return value * num;
    }
    
    if (value is String) {
      final times = int.tryParse(multiplyValue) ?? 1;
      return value * times;
    }
    
    return value;
  }
}

class DivideFilter extends TemplateFilter {
  @override
  dynamic apply(dynamic value, List<String> args, TemplateContext context) {
    if (args.isEmpty) return value;
    
    final divideValue = args[0];
    
    if (value is num) {
      final num = double.tryParse(divideValue) ?? int.tryParse(divideValue) ?? 1;
      if (num == 0) throw TemplateFilterException('divide', 'Division by zero');
      return value / num;
    }
    
    return value;
  }
}

class ModuloFilter extends TemplateFilter {
  @override
  dynamic apply(dynamic value, List<String> args, TemplateContext context) {
    if (args.isEmpty) return value;
    
    final moduloValue = args[0];
    
    if (value is num) {
      final num = double.tryParse(moduloValue) ?? int.tryParse(moduloValue) ?? 1;
      if (num == 0) throw TemplateFilterException('modulo', 'Modulo by zero');
      return value % num;
    }
    
    return value;
  }
}

class YesNoFilter extends TemplateFilter {
  @override
  dynamic apply(dynamic value, List<String> args, TemplateContext context) {
    final yesValue = args.isNotEmpty ? args[0] : 'yes';
    final noValue = args.length > 1 ? args[1] : 'no';
    final maybeValue = args.length > 2 ? args[2] : noValue;
    
    if (value == null) return maybeValue;
    
    if (value is bool) {
      return value ? yesValue : noValue;
    }
    
    if (value is String) {
      return value.isNotEmpty ? yesValue : noValue;
    }
    
    if (value is num) {
      return value != 0 ? yesValue : noValue;
    }
    
    if (value is List) {
      return value.isNotEmpty ? yesValue : noValue;
    }
    
    return value.toString().isNotEmpty ? yesValue : noValue;
  }
}

class PluralizeFilter extends TemplateFilter {
  @override
  dynamic apply(dynamic value, List<String> args, TemplateContext context) {
    if (value == null) return '';
    
    final singular = args.isNotEmpty ? args[0] : '';
    final plural = args.length > 1 ? args[1] : '${singular}s';
    
    if (value is num) {
      return value == 1 ? singular : plural;
    }
    
    if (value is String) {
      final num = int.tryParse(value) ?? 0;
      return num == 1 ? singular : plural;
    }
    
    if (value is List) {
      return value.length == 1 ? singular : plural;
    }
    
    return plural;
  }
}

class LinebreaksFilter extends TemplateFilter {
  @override
  dynamic apply(dynamic value, List<String> args, TemplateContext context) {
    if (value == null) return '';
    
    final str = value.toString();
    return str.replaceAll('\n', '<br>');
  }
}

class StripTagsFilter extends TemplateFilter {
  @override
  dynamic apply(dynamic value, List<String> args, TemplateContext context) {
    if (value == null) return '';
    
    final str = value.toString();
    return str.replaceAll(RegExp(r'<[^>]*>'), '');
  }
}

class UrlEncodeFilter extends TemplateFilter {
  @override
  dynamic apply(dynamic value, List<String> args, TemplateContext context) {
    if (value == null) return '';
    
    return Uri.encodeComponent(value.toString());
  }
}

class WordCountFilter extends TemplateFilter {
  @override
  dynamic apply(dynamic value, List<String> args, TemplateContext context) {
    if (value == null) return 0;
    
    final str = value.toString().trim();
    if (str.isEmpty) return 0;
    
    return str.split(RegExp(r'\s+')).length;
  }
}