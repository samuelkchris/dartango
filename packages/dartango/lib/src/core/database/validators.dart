import 'dart:convert';

import 'exceptions.dart';

abstract class Validator<T> {
  void validate(T? value);
  String get message;
}

class RequiredValidator<T> extends Validator<T> {
  @override
  final String message;

  RequiredValidator({this.message = 'This field is required'});

  @override
  void validate(T? value) {
    if (value == null) {
      throw ValidationException(message);
    }
  }
}

class MinLengthValidator extends Validator<String> {
  final int minLength;
  @override
  final String message;

  MinLengthValidator(this.minLength, {String? message})
      : message = message ?? 'Must be at least $minLength characters long';

  @override
  void validate(String? value) {
    if (value != null && value.length < minLength) {
      throw ValidationException(message);
    }
  }
}

class MaxLengthValidator extends Validator<String> {
  final int maxLength;
  @override
  final String message;

  MaxLengthValidator(this.maxLength, {String? message})
      : message = message ?? 'Must be no more than $maxLength characters long';

  @override
  void validate(String? value) {
    if (value != null && value.length > maxLength) {
      throw ValidationException(message);
    }
  }
}

class MinValueValidator<T extends num> extends Validator<T> {
  final T minValue;
  @override
  final String message;

  MinValueValidator(this.minValue, {String? message})
      : message = message ?? 'Must be at least $minValue';

  @override
  void validate(T? value) {
    if (value != null && value < minValue) {
      throw ValidationException(message);
    }
  }
}

class MaxValueValidator<T extends num> extends Validator<T> {
  final T maxValue;
  @override
  final String message;

  MaxValueValidator(this.maxValue, {String? message})
      : message = message ?? 'Must be no more than $maxValue';

  @override
  void validate(T? value) {
    if (value != null && value > maxValue) {
      throw ValidationException(message);
    }
  }
}

class RangeValidator<T extends num> extends Validator<T> {
  final T minValue;
  final T maxValue;
  @override
  final String message;

  RangeValidator(this.minValue, this.maxValue, {String? message})
      : message = message ?? 'Must be between $minValue and $maxValue';

  @override
  void validate(T? value) {
    if (value != null && (value < minValue || value > maxValue)) {
      throw ValidationException(message);
    }
  }
}

class RegexValidator extends Validator<String> {
  final RegExp regex;
  @override
  final String message;

  RegexValidator(this.regex, {String? message})
      : message = message ?? 'Invalid format';

  @override
  void validate(String? value) {
    if (value != null && !regex.hasMatch(value)) {
      throw ValidationException(message);
    }
  }
}

class EmailValidator extends Validator<String> {
  @override
  final String message;

  EmailValidator({this.message = 'Invalid email format'});

  @override
  void validate(String? value) {
    if (value != null && value.isNotEmpty) {
      final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
      if (!emailRegex.hasMatch(value)) {
        throw ValidationException(message);
      }
    }
  }
}

class URLValidator extends Validator<String> {
  @override
  final String message;

  URLValidator({this.message = 'Invalid URL format'});

  @override
  void validate(String? value) {
    if (value != null && value.isNotEmpty) {
      final uri = Uri.tryParse(value);
      if (uri == null || (!uri.hasScheme) || (!uri.hasAuthority)) {
        throw ValidationException(message);
      }
    }
  }
}

class UUIDValidator extends Validator<String> {
  @override
  final String message;

  UUIDValidator({this.message = 'Invalid UUID format'});

  @override
  void validate(String? value) {
    if (value != null && value.isNotEmpty) {
      final uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
      if (!uuidRegex.hasMatch(value)) {
        throw ValidationException(message);
      }
    }
  }
}

class SlugValidator extends Validator<String> {
  @override
  final String message;

  SlugValidator({this.message = 'Invalid slug format (only letters, numbers, underscores and hyphens allowed)'});

  @override
  void validate(String? value) {
    if (value != null && value.isNotEmpty) {
      final slugRegex = RegExp(r'^[-a-zA-Z0-9_]+$');
      if (!slugRegex.hasMatch(value)) {
        throw ValidationException(message);
      }
    }
  }
}

class IPAddressValidator extends Validator<String> {
  @override
  final String message;

  IPAddressValidator({this.message = 'Invalid IP address format'});

  @override
  void validate(String? value) {
    if (value != null && value.isNotEmpty) {
      final ipv4Regex = RegExp(r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$');
      final ipv6Regex = RegExp(r'^(?:[0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$');
      
      if (!ipv4Regex.hasMatch(value) && !ipv6Regex.hasMatch(value)) {
        throw ValidationException(message);
      }
    }
  }
}

class DecimalValidator extends Validator<double> {
  final int maxDigits;
  final int decimalPlaces;
  @override
  final String message;

  DecimalValidator(this.maxDigits, this.decimalPlaces, {String? message})
      : message = message ?? 'Invalid decimal format (max $maxDigits digits with $decimalPlaces decimal places)';

  @override
  void validate(double? value) {
    if (value != null) {
      final valueStr = value.toString();
      final parts = valueStr.split('.');
      final integerPart = parts[0].replaceAll('-', '');
      final decimalPart = parts.length > 1 ? parts[1] : '';
      
      if (integerPart.length + decimalPart.length > maxDigits) {
        throw ValidationException('Number has too many digits');
      }
      
      if (decimalPart.length > decimalPlaces) {
        throw ValidationException('Number has too many decimal places');
      }
    }
  }
}

class ChoicesValidator<T> extends Validator<T> {
  final Map<T, String> choices;
  @override
  final String message;

  ChoicesValidator(this.choices, {String? message})
      : message = message ?? 'Invalid choice';

  @override
  void validate(T? value) {
    if (value != null && !choices.containsKey(value)) {
      throw ValidationException(message);
    }
  }
}

class CustomValidator<T> extends Validator<T> {
  final bool Function(T? value) validator;
  @override
  final String message;

  CustomValidator(this.validator, {required this.message});

  @override
  void validate(T? value) {
    if (!validator(value)) {
      throw ValidationException(message);
    }
  }
}

class FileExtensionValidator extends Validator<String> {
  final List<String> allowedExtensions;
  @override
  final String message;

  FileExtensionValidator(this.allowedExtensions, {String? message})
      : message = message ?? 'Invalid file extension. Allowed: ${allowedExtensions.join(', ')}';

  @override
  void validate(String? value) {
    if (value != null && value.isNotEmpty) {
      final extension = value.split('.').last.toLowerCase();
      if (!allowedExtensions.contains(extension)) {
        throw ValidationException(message);
      }
    }
  }
}

class FileSizeValidator extends Validator<int> {
  final int maxSize;
  @override
  final String message;

  FileSizeValidator(this.maxSize, {String? message})
      : message = message ?? 'File size must be less than ${_formatBytes(maxSize)}';

  @override
  void validate(int? value) {
    if (value != null && value > maxSize) {
      throw ValidationException(message);
    }
  }

  static String _formatBytes(int bytes) {
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(2)} ${suffixes[i]}';
  }
}

class DateRangeValidator extends Validator<DateTime> {
  final DateTime? minDate;
  final DateTime? maxDate;
  @override
  final String message;

  DateRangeValidator({this.minDate, this.maxDate, String? message})
      : message = message ?? 'Date is out of range';

  @override
  void validate(DateTime? value) {
    if (value != null) {
      if (minDate != null && value.isBefore(minDate!)) {
        throw ValidationException('Date must be after ${minDate!.toIso8601String().split('T')[0]}');
      }
      
      if (maxDate != null && value.isAfter(maxDate!)) {
        throw ValidationException('Date must be before ${maxDate!.toIso8601String().split('T')[0]}');
      }
    }
  }
}

class JSONValidator extends Validator<String> {
  @override
  final String message;

  JSONValidator({this.message = 'Invalid JSON format'});

  @override
  void validate(String? value) {
    if (value != null && value.isNotEmpty) {
      try {
        json.decode(value);
      } catch (e) {
        throw ValidationException(message);
      }
    }
  }
}

class CreditCardValidator extends Validator<String> {
  @override
  final String message;

  CreditCardValidator({this.message = 'Invalid credit card number'});

  @override
  void validate(String? value) {
    if (value != null && value.isNotEmpty) {
      final cleanValue = value.replaceAll(RegExp(r'[^0-9]'), '');
      if (!_isValidCreditCard(cleanValue)) {
        throw ValidationException(message);
      }
    }
  }

  bool _isValidCreditCard(String cardNumber) {
    if (cardNumber.length < 13 || cardNumber.length > 19) {
      return false;
    }

    int sum = 0;
    bool alternate = false;
    
    for (int i = cardNumber.length - 1; i >= 0; i--) {
      int digit = int.parse(cardNumber[i]);
      
      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit = (digit % 10) + 1;
        }
      }
      
      sum += digit;
      alternate = !alternate;
    }
    
    return sum % 10 == 0;
  }
}

class PhoneNumberValidator extends Validator<String> {
  @override
  final String message;

  PhoneNumberValidator({this.message = 'Invalid phone number format'});

  @override
  void validate(String? value) {
    if (value != null && value.isNotEmpty) {
      final phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$');
      final cleanValue = value.replaceAll(RegExp(r'[^\d+]'), '');
      if (!phoneRegex.hasMatch(cleanValue)) {
        throw ValidationException(message);
      }
    }
  }
}

class StrongPasswordValidator extends Validator<String> {
  final int minLength;
  final bool requireUppercase;
  final bool requireLowercase;
  final bool requireNumbers;
  final bool requireSpecialChars;
  @override
  final String message;

  StrongPasswordValidator({
    this.minLength = 8,
    this.requireUppercase = true,
    this.requireLowercase = true,
    this.requireNumbers = true,
    this.requireSpecialChars = true,
    String? message,
  }) : message = message ?? 'Password does not meet strength requirements';

  @override
  void validate(String? value) {
    if (value != null && value.isNotEmpty) {
      final errors = <String>[];
      
      if (value.length < minLength) {
        errors.add('at least $minLength characters');
      }
      
      if (requireUppercase && !value.contains(RegExp(r'[A-Z]'))) {
        errors.add('at least one uppercase letter');
      }
      
      if (requireLowercase && !value.contains(RegExp(r'[a-z]'))) {
        errors.add('at least one lowercase letter');
      }
      
      if (requireNumbers && !value.contains(RegExp(r'[0-9]'))) {
        errors.add('at least one number');
      }
      
      if (requireSpecialChars && !value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
        errors.add('at least one special character');
      }
      
      if (errors.isNotEmpty) {
        throw ValidationException('Password must contain: ${errors.join(', ')}');
      }
    }
  }
}

class UniqueValidator<T> extends Validator<T> {
  final Future<bool> Function(T value) checkUnique;
  @override
  final String message;

  UniqueValidator(this.checkUnique, {this.message = 'This value must be unique'});

  @override
  void validate(T? value) async {
    if (value != null) {
      final isUnique = await checkUnique(value);
      if (!isUnique) {
        throw ValidationException(message);
      }
    }
  }
}

List<Validator<String>> validateEmail() => [EmailValidator()];
List<Validator<String>> validateURL() => [URLValidator()];
List<Validator<String>> validateUUID() => [UUIDValidator()];
List<Validator<String>> validateSlug() => [SlugValidator()];
List<Validator<String>> validateIPAddress() => [IPAddressValidator()];
List<Validator<String>> validatePhoneNumber() => [PhoneNumberValidator()];
List<Validator<String>> validateCreditCard() => [CreditCardValidator()];
List<Validator<String>> validateStrongPassword() => [StrongPasswordValidator()];

List<Validator<String>> validateLength({int? min, int? max}) {
  final validators = <Validator<String>>[];
  if (min != null) validators.add(MinLengthValidator(min));
  if (max != null) validators.add(MaxLengthValidator(max));
  return validators;
}

List<Validator<T>> validateRange<T extends num>(T min, T max) => [RangeValidator(min, max)];
List<Validator<T>> validateChoices<T>(Map<T, String> choices) => [ChoicesValidator(choices)];
List<Validator<String>> validateRegex(RegExp regex, {String? message}) => [RegexValidator(regex, message: message)];
List<Validator<String>> validateFileExtension(List<String> extensions) => [FileExtensionValidator(extensions)];
List<Validator<int>> validateFileSize(int maxSize) => [FileSizeValidator(maxSize)];
List<Validator<DateTime>> validateDateRange({DateTime? min, DateTime? max}) => [DateRangeValidator(minDate: min, maxDate: max)];
List<Validator<double>> validateDecimal(int maxDigits, int decimalPlaces) => [DecimalValidator(maxDigits, decimalPlaces)];
List<Validator<String>> validateJSON() => [JSONValidator()];