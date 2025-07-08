import 'dart:convert';

abstract class PathConverter {
  String get name;
  String get pattern;
  
  Object convert(String value);
  String reverse(Object value);
  
  static PathConverter getConverter(String name) {
    if (_customConverters.containsKey(name)) {
      return _customConverters[name]!;
    }
    
    switch (name) {
      case 'int':
        return IntConverter();
      case 'slug':
        return SlugConverter();
      case 'uuid':
        return UuidConverter();
      case 'path':
        return PathPathConverter();
      case 'float':
        return FloatConverter();
      case 'bool':
        return BoolConverter();
      case 'date':
        return DateConverter();
      case 'json':
        return JsonConverter();
      case 'base64':
        return Base64Converter();
      case 'hex':
        return HexConverter();
      case 'octal':
        return OctalConverter();
      case 'alpha':
        return AlphaConverter();
      case 'alphanum':
        return AlphaNumericConverter();
      case 'email':
        return EmailConverter();
      case 'str':
      default:
        return StringConverter();
    }
  }
  
  static void registerConverter(String name, PathConverter converter) {
    _customConverters[name] = converter;
  }
  
  static final Map<String, PathConverter> _customConverters = {};
}

class StringConverter extends PathConverter {
  @override
  String get name => 'str';
  
  @override
  String get pattern => r'[^/]+';
  
  @override
  String convert(String value) {
    return value;
  }
  
  @override
  String reverse(Object value) {
    return value.toString();
  }
}

class IntConverter extends PathConverter {
  @override
  String get name => 'int';
  
  @override
  String get pattern => r'[0-9]+';
  
  @override
  int convert(String value) {
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      throw ArgumentError('Invalid integer value: $value');
    }
    final parsed = int.tryParse(value);
    if (parsed == null) {
      throw ArgumentError('Invalid integer value: $value');
    }
    return parsed;
  }
  
  @override
  String reverse(Object value) {
    if (value is! int) {
      throw ArgumentError('Expected int, got ${value.runtimeType}');
    }
    return value.toString();
  }
}

class SlugConverter extends PathConverter {
  @override
  String get name => 'slug';
  
  @override
  String get pattern => r'[-a-zA-Z0-9_]+';
  
  @override
  String convert(String value) {
    if (!RegExp(r'^[-a-zA-Z0-9_]+$').hasMatch(value)) {
      throw ArgumentError('Invalid slug value: $value');
    }
    return value;
  }
  
  @override
  String reverse(Object value) {
    final str = value.toString();
    if (!RegExp(r'^[-a-zA-Z0-9_]+$').hasMatch(str)) {
      throw ArgumentError('Invalid slug value: $str');
    }
    return str;
  }
}

class UuidConverter extends PathConverter {
  @override
  String get name => 'uuid';
  
  @override
  String get pattern => r'[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}';
  
  @override
  String convert(String value) {
    final uuid = value.toLowerCase();
    if (!RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$').hasMatch(uuid)) {
      throw ArgumentError('Invalid UUID value: $value');
    }
    return uuid;
  }
  
  @override
  String reverse(Object value) {
    final str = value.toString().toLowerCase();
    if (!RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$').hasMatch(str)) {
      throw ArgumentError('Invalid UUID value: $str');
    }
    return str;
  }
}

class PathPathConverter extends PathConverter {
  @override
  String get name => 'path';
  
  @override
  String get pattern => r'.+';
  
  @override
  String convert(String value) {
    return value;
  }
  
  @override
  String reverse(Object value) {
    return value.toString();
  }
}

class FloatConverter extends PathConverter {
  @override
  String get name => 'float';
  
  @override
  String get pattern => r'[0-9]+(?:\.[0-9]+)?';
  
  @override
  double convert(String value) {
    final parsed = double.tryParse(value);
    if (parsed == null) {
      throw ArgumentError('Invalid float value: $value');
    }
    return parsed;
  }
  
  @override
  String reverse(Object value) {
    if (value is! num) {
      throw ArgumentError('Expected num, got ${value.runtimeType}');
    }
    return value.toString();
  }
}

class DateConverter extends PathConverter {
  @override
  String get name => 'date';
  
  @override
  String get pattern => r'[0-9]{4}-[0-9]{2}-[0-9]{2}';
  
  @override
  DateTime convert(String value) {
    try {
      return DateTime.parse(value);
    } catch (e) {
      throw ArgumentError('Invalid date value: $value');
    }
  }
  
  @override
  String reverse(Object value) {
    if (value is! DateTime) {
      throw ArgumentError('Expected DateTime, got ${value.runtimeType}');
    }
    return value.toIso8601String().split('T')[0];
  }
}

class BoolConverter extends PathConverter {
  @override
  String get name => 'bool';
  
  @override
  String get pattern => r'(?:true|false|1|0)';
  
  @override
  bool convert(String value) {
    switch (value.toLowerCase()) {
      case 'true':
      case '1':
        return true;
      case 'false':
      case '0':
        return false;
      default:
        throw ArgumentError('Invalid boolean value: $value');
    }
  }
  
  @override
  String reverse(Object value) {
    if (value is! bool) {
      throw ArgumentError('Expected bool, got ${value.runtimeType}');
    }
    return value.toString();
  }
}

class JsonConverter extends PathConverter {
  @override
  String get name => 'json';
  
  @override
  String get pattern => r'[^/]+';
  
  @override
  Object convert(String value) {
    try {
      return json.decode(Uri.decodeComponent(value));
    } catch (e) {
      throw ArgumentError('Invalid JSON value: $value');
    }
  }
  
  @override
  String reverse(Object value) {
    try {
      return Uri.encodeComponent(json.encode(value));
    } catch (e) {
      throw ArgumentError('Cannot encode value to JSON: $value');
    }
  }
}

class Base64Converter extends PathConverter {
  @override
  String get name => 'base64';
  
  @override
  String get pattern => r'[A-Za-z0-9+/]+=*';
  
  @override
  String convert(String value) {
    try {
      final decoded = base64.decode(value);
      return String.fromCharCodes(decoded);
    } catch (e) {
      throw ArgumentError('Invalid base64 value: $value');
    }
  }
  
  @override
  String reverse(Object value) {
    try {
      final encoded = base64.encode(value.toString().codeUnits);
      return encoded;
    } catch (e) {
      throw ArgumentError('Cannot encode value to base64: $value');
    }
  }
}

class HexConverter extends PathConverter {
  @override
  String get name => 'hex';
  
  @override
  String get pattern => r'[0-9a-fA-F]+';
  
  @override
  int convert(String value) {
    try {
      return int.parse(value, radix: 16);
    } catch (e) {
      throw ArgumentError('Invalid hex value: $value');
    }
  }
  
  @override
  String reverse(Object value) {
    if (value is! int) {
      throw ArgumentError('Expected int, got ${value.runtimeType}');
    }
    return value.toRadixString(16);
  }
}

class OctalConverter extends PathConverter {
  @override
  String get name => 'octal';
  
  @override
  String get pattern => r'[0-7]+';
  
  @override
  int convert(String value) {
    try {
      return int.parse(value, radix: 8);
    } catch (e) {
      throw ArgumentError('Invalid octal value: $value');
    }
  }
  
  @override
  String reverse(Object value) {
    if (value is! int) {
      throw ArgumentError('Expected int, got ${value.runtimeType}');
    }
    return value.toRadixString(8);
  }
}

class AlphaConverter extends PathConverter {
  @override
  String get name => 'alpha';
  
  @override
  String get pattern => r'[a-zA-Z]+';
  
  @override
  String convert(String value) {
    if (!RegExp(r'^[a-zA-Z]+$').hasMatch(value)) {
      throw ArgumentError('Invalid alpha value: $value');
    }
    return value;
  }
  
  @override
  String reverse(Object value) {
    final str = value.toString();
    if (!RegExp(r'^[a-zA-Z]+$').hasMatch(str)) {
      throw ArgumentError('Invalid alpha value: $str');
    }
    return str;
  }
}

class AlphaNumericConverter extends PathConverter {
  @override
  String get name => 'alphanum';
  
  @override
  String get pattern => r'[a-zA-Z0-9]+';
  
  @override
  String convert(String value) {
    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value)) {
      throw ArgumentError('Invalid alphanumeric value: $value');
    }
    return value;
  }
  
  @override
  String reverse(Object value) {
    final str = value.toString();
    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(str)) {
      throw ArgumentError('Invalid alphanumeric value: $str');
    }
    return str;
  }
}

class EmailConverter extends PathConverter {
  @override
  String get name => 'email';
  
  @override
  String get pattern => r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}';
  
  @override
  String convert(String value) {
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
      throw ArgumentError('Invalid email value: $value');
    }
    return value;
  }
  
  @override
  String reverse(Object value) {
    final str = value.toString();
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(str)) {
      throw ArgumentError('Invalid email value: $str');
    }
    return str;
  }
}