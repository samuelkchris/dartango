class Constants {
  static const String appName = 'Dartango Admin';
  static const String appVersion = '1.0.0';
  static const String defaultApiUrl = 'http://localhost:8000/api';
  static const String defaultWebSocketUrl = 'ws://localhost:8000/ws';

  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration longTimeout = Duration(minutes: 2);
  static const Duration refreshInterval = Duration(seconds: 30);
  static const Duration cacheTimeout = Duration(minutes: 5);

  static const int defaultPageSize = 25;
  static const int maxPageSize = 100;
  static const int maxRetries = 3;
  static const int maxUploadSize = 10 * 1024 * 1024; // 10MB

  static const String dateFormat = 'yyyy-MM-dd';
  static const String timeFormat = 'HH:mm:ss';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
  static const String displayDateFormat = 'MMM dd, yyyy';
  static const String displayTimeFormat = 'hh:mm a';
  static const String displayDateTimeFormat = 'MMM dd, yyyy hh:mm a';

  static const Map<String, String> mimeTypes = {
    'pdf': 'application/pdf',
    'doc': 'application/msword',
    'docx':
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'xls': 'application/vnd.ms-excel',
    'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'ppt': 'application/vnd.ms-powerpoint',
    'pptx':
        'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'txt': 'text/plain',
    'csv': 'text/csv',
    'json': 'application/json',
    'xml': 'application/xml',
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'gif': 'image/gif',
    'bmp': 'image/bmp',
    'svg': 'image/svg+xml',
    'mp4': 'video/mp4',
    'avi': 'video/x-msvideo',
    'mov': 'video/quicktime',
    'wmv': 'video/x-ms-wmv',
    'mp3': 'audio/mpeg',
    'wav': 'audio/wav',
    'ogg': 'audio/ogg',
    'zip': 'application/zip',
    'rar': 'application/x-rar-compressed',
    '7z': 'application/x-7z-compressed',
  };

  static const List<String> allowedImageExtensions = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'bmp',
    'svg',
    'webp'
  ];

  static const List<String> allowedDocumentExtensions = [
    'pdf',
    'doc',
    'docx',
    'xls',
    'xlsx',
    'ppt',
    'pptx',
    'txt',
    'csv'
  ];

  static const List<String> allowedVideoExtensions = [
    'mp4',
    'avi',
    'mov',
    'wmv',
    'mkv',
    'flv',
    'webm'
  ];

  static const List<String> allowedAudioExtensions = [
    'mp3',
    'wav',
    'ogg',
    'aac',
    'flac',
    'm4a'
  ];

  static const Map<String, String> httpStatusMessages = {
    '200': 'OK',
    '201': 'Created',
    '400': 'Bad Request',
    '401': 'Unauthorized',
    '403': 'Forbidden',
    '404': 'Not Found',
    '405': 'Method Not Allowed',
    '409': 'Conflict',
    '422': 'Unprocessable Entity',
    '429': 'Too Many Requests',
    '500': 'Internal Server Error',
    '502': 'Bad Gateway',
    '503': 'Service Unavailable',
    '504': 'Gateway Timeout',
  };

  static const Map<String, String> permissions = {
    'users.add': 'Add Users',
    'users.change': 'Change Users',
    'users.delete': 'Delete Users',
    'users.view': 'View Users',
    'groups.add': 'Add Groups',
    'groups.change': 'Change Groups',
    'groups.delete': 'Delete Groups',
    'groups.view': 'View Groups',
    'sessions.add': 'Add Sessions',
    'sessions.change': 'Change Sessions',
    'sessions.delete': 'Delete Sessions',
    'sessions.view': 'View Sessions',
    'logs.view': 'View Logs',
    'logs.export': 'Export Logs',
    'settings.change': 'Change Settings',
    'settings.view': 'View Settings',
    'admin.access': 'Access Admin',
    'admin.full': 'Full Admin Access',
  };

  static const Map<String, String> actions = {
    'create': 'Created',
    'update': 'Updated',
    'delete': 'Deleted',
    'login': 'Logged In',
    'logout': 'Logged Out',
    'password_change': 'Changed Password',
    'password_reset': 'Reset Password',
    'profile_update': 'Updated Profile',
    'permission_grant': 'Granted Permission',
    'permission_revoke': 'Revoked Permission',
    'export': 'Exported Data',
    'import': 'Imported Data',
    'backup': 'Created Backup',
    'restore': 'Restored Backup',
  };

  static const List<String> themes = [
    'light',
    'dark',
    'auto',
  ];

  static const List<String> languages = [
    'en',
    'es',
    'fr',
    'de',
    'it',
    'pt',
    'ru',
    'zh',
    'ja',
    'ko',
  ];

  static const Map<String, String> languageNames = {
    'en': 'English',
    'es': 'Español',
    'fr': 'Français',
    'de': 'Deutsch',
    'it': 'Italiano',
    'pt': 'Português',
    'ru': 'Русский',
    'zh': '中文',
    'ja': '日本語',
    'ko': '한국어',
  };

  static const List<String> timezones = [
    'UTC',
    'America/New_York',
    'America/Chicago',
    'America/Denver',
    'America/Los_Angeles',
    'Europe/London',
    'Europe/Paris',
    'Europe/Berlin',
    'Europe/Rome',
    'Europe/Moscow',
    'Asia/Tokyo',
    'Asia/Shanghai',
    'Asia/Kolkata',
    'Asia/Dubai',
    'Australia/Sydney',
    'Pacific/Auckland',
  ];

  static const Map<String, String> timezoneNames = {
    'UTC': 'UTC',
    'America/New_York': 'Eastern Time',
    'America/Chicago': 'Central Time',
    'America/Denver': 'Mountain Time',
    'America/Los_Angeles': 'Pacific Time',
    'Europe/London': 'London',
    'Europe/Paris': 'Paris',
    'Europe/Berlin': 'Berlin',
    'Europe/Rome': 'Rome',
    'Europe/Moscow': 'Moscow',
    'Asia/Tokyo': 'Tokyo',
    'Asia/Shanghai': 'Shanghai',
    'Asia/Kolkata': 'Kolkata',
    'Asia/Dubai': 'Dubai',
    'Australia/Sydney': 'Sydney',
    'Pacific/Auckland': 'Auckland',
  };

  static const Map<String, List<String>> dashboardLayouts = {
    'default': ['stats', 'charts', 'recent_activity', 'system_metrics'],
    'minimal': ['stats', 'recent_activity'],
    'analytics': ['stats', 'charts', 'system_metrics'],
    'monitoring': ['system_metrics', 'charts', 'recent_activity'],
  };

  static const List<String> exportFormats = [
    'csv',
    'json',
    'xml',
    'excel',
    'pdf',
  ];

  static const Map<String, String> exportFormatNames = {
    'csv': 'CSV',
    'json': 'JSON',
    'xml': 'XML',
    'excel': 'Excel',
    'pdf': 'PDF',
  };

  static const Map<String, String> fieldTypes = {
    'string': 'String',
    'integer': 'Integer',
    'float': 'Float',
    'boolean': 'Boolean',
    'date': 'Date',
    'datetime': 'DateTime',
    'time': 'Time',
    'email': 'Email',
    'url': 'URL',
    'phone': 'Phone',
    'text': 'Text',
    'json': 'JSON',
    'file': 'File',
    'image': 'Image',
    'select': 'Select',
    'multiselect': 'Multi Select',
    'foreign_key': 'Foreign Key',
    'many_to_many': 'Many to Many',
  };

  static const Map<String, String> validationRules = {
    'required': 'Required',
    'email': 'Valid Email',
    'url': 'Valid URL',
    'phone': 'Valid Phone',
    'min_length': 'Minimum Length',
    'max_length': 'Maximum Length',
    'min_value': 'Minimum Value',
    'max_value': 'Maximum Value',
    'pattern': 'Pattern Match',
    'unique': 'Unique Value',
    'date_range': 'Date Range',
    'file_size': 'File Size',
    'file_type': 'File Type',
  };
}
