import 'dart:async';
import 'dart:io';
import 'dart:convert';

class EmailMessage {
  final String subject;
  final String body;
  final String from;
  final List<String> to;
  final List<String> cc;
  final List<String> bcc;
  final List<EmailAttachment> attachments;
  final Map<String, String> headers;
  final bool isHtml;
  final DateTime createdAt;

  EmailMessage({
    required this.subject,
    required this.body,
    required this.from,
    required this.to,
    this.cc = const [],
    this.bcc = const [],
    this.attachments = const [],
    this.headers = const {},
    this.isHtml = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  EmailMessage copyWith({
    String? subject,
    String? body,
    String? from,
    List<String>? to,
    List<String>? cc,
    List<String>? bcc,
    List<EmailAttachment>? attachments,
    Map<String, String>? headers,
    bool? isHtml,
  }) {
    return EmailMessage(
      subject: subject ?? this.subject,
      body: body ?? this.body,
      from: from ?? this.from,
      to: to ?? this.to,
      cc: cc ?? this.cc,
      bcc: bcc ?? this.bcc,
      attachments: attachments ?? this.attachments,
      headers: headers ?? this.headers,
      isHtml: isHtml ?? this.isHtml,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subject': subject,
      'body': body,
      'from': from,
      'to': to,
      'cc': cc,
      'bcc': bcc,
      'attachments': attachments.map((a) => a.toJson()).toList(),
      'headers': headers,
      'is_html': isHtml,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory EmailMessage.fromJson(Map<String, dynamic> json) {
    return EmailMessage(
      subject: json['subject'] as String,
      body: json['body'] as String,
      from: json['from'] as String,
      to: List<String>.from(json['to'] as List),
      cc: List<String>.from(json['cc'] as List? ?? []),
      bcc: List<String>.from(json['bcc'] as List? ?? []),
      attachments: (json['attachments'] as List? ?? [])
          .map((a) => EmailAttachment.fromJson(a as Map<String, dynamic>))
          .toList(),
      headers: Map<String, String>.from(json['headers'] as Map? ?? {}),
      isHtml: json['is_html'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class EmailAttachment {
  final String filename;
  final List<int> bytes;
  final String? contentType;
  final String? contentId;

  EmailAttachment({
    required this.filename,
    required this.bytes,
    this.contentType,
    this.contentId,
  });

  Map<String, dynamic> toJson() {
    return {
      'filename': filename,
      'bytes': base64Encode(bytes),
      'content_type': contentType,
      'content_id': contentId,
    };
  }

  factory EmailAttachment.fromJson(Map<String, dynamic> json) {
    return EmailAttachment(
      filename: json['filename'] as String,
      bytes: base64Decode(json['bytes'] as String),
      contentType: json['content_type'] as String?,
      contentId: json['content_id'] as String?,
    );
  }

  factory EmailAttachment.fromFile(File file,
      {String? contentType, String? contentId}) {
    return EmailAttachment(
      filename: file.path.split('/').last,
      bytes: file.readAsBytesSync(),
      contentType: contentType,
      contentId: contentId,
    );
  }
}

class EmailResult {
  final bool success;
  final String? messageId;
  final String? error;
  final DateTime sentAt;

  EmailResult({
    required this.success,
    this.messageId,
    this.error,
    DateTime? sentAt,
  }) : sentAt = sentAt ?? DateTime.now();

  factory EmailResult.success(String messageId) {
    return EmailResult(
      success: true,
      messageId: messageId,
    );
  }

  factory EmailResult.error(String error) {
    return EmailResult(
      success: false,
      error: error,
    );
  }
}

abstract class EmailBackend {
  Future<EmailResult> sendEmail(EmailMessage message);
  Future<List<EmailResult>> sendEmails(List<EmailMessage> messages);
  Future<void> close();
}

class SmtpEmailBackend implements EmailBackend {
  final String host;
  final int port;
  final String? username;
  final String? password;
  final bool ssl;
  final bool tls;
  final Duration timeout;

  Socket? _socket;

  SmtpEmailBackend({
    required this.host,
    required this.port,
    this.username,
    this.password,
    this.ssl = false,
    this.tls = true,
    this.timeout = const Duration(seconds: 30),
  });

  @override
  Future<EmailResult> sendEmail(EmailMessage message) async {
    try {
      // Create a simple SMTP implementation
      final socket = await Socket.connect(host, port);
      _socket = socket;

      // Send SMTP commands
      await _sendCommand(socket, 'EHLO localhost');

      if (username != null && password != null) {
        await _sendCommand(socket, 'AUTH LOGIN');
        await _sendCommand(socket, base64Encode(utf8.encode(username!)));
        await _sendCommand(socket, base64Encode(utf8.encode(password!)));
      }

      await _sendCommand(socket, 'MAIL FROM:<${message.from}>');

      for (final recipient in message.to) {
        await _sendCommand(socket, 'RCPT TO:<$recipient>');
      }

      for (final recipient in message.cc) {
        await _sendCommand(socket, 'RCPT TO:<$recipient>');
      }

      for (final recipient in message.bcc) {
        await _sendCommand(socket, 'RCPT TO:<$recipient>');
      }

      await _sendCommand(socket, 'DATA');

      // Build email content
      final emailContent = _buildEmailContent(message);
      socket.add(utf8.encode(emailContent));
      socket.add(utf8.encode('\r\n.\r\n'));

      await _sendCommand(socket, 'QUIT');
      await socket.close();

      return EmailResult.success(
          'smtp-${DateTime.now().millisecondsSinceEpoch}');
    } catch (e) {
      return EmailResult.error(e.toString());
    }
  }

  Future<void> _sendCommand(Socket socket, String command) async {
    socket.add(utf8.encode('$command\r\n'));
    await Future.delayed(const Duration(milliseconds: 100));
  }

  String _buildEmailContent(EmailMessage message) {
    final buffer = StringBuffer();

    // Headers
    buffer.writeln('From: ${message.from}');
    buffer.writeln('To: ${message.to.join(', ')}');
    if (message.cc.isNotEmpty) {
      buffer.writeln('Cc: ${message.cc.join(', ')}');
    }
    buffer.writeln('Subject: ${message.subject}');
    buffer.writeln('Date: ${DateTime.now().toUtc().toString()}');
    buffer.writeln(
        'Content-Type: ${message.isHtml ? 'text/html' : 'text/plain'}; charset=utf-8');

    // Custom headers
    for (final header in message.headers.entries) {
      buffer.writeln('${header.key}: ${header.value}');
    }

    buffer.writeln();
    buffer.writeln(message.body);

    return buffer.toString();
  }

  @override
  Future<List<EmailResult>> sendEmails(List<EmailMessage> messages) async {
    final results = <EmailResult>[];

    for (final message in messages) {
      final result = await sendEmail(message);
      results.add(result);
    }

    return results;
  }

  @override
  Future<void> close() async {
    if (_socket != null) {
      await _socket!.close();
    }
  }
}

class ConsoleEmailBackend implements EmailBackend {
  final IOSink output;

  ConsoleEmailBackend({IOSink? output}) : output = output ?? stdout;

  @override
  Future<EmailResult> sendEmail(EmailMessage message) async {
    final divider = '=' * 70;

    output.writeln(divider);
    output.writeln('Email Message');
    output.writeln(divider);
    output.writeln('Subject: ${message.subject}');
    output.writeln('From: ${message.from}');
    output.writeln('To: ${message.to.join(', ')}');

    if (message.cc.isNotEmpty) {
      output.writeln('CC: ${message.cc.join(', ')}');
    }

    if (message.bcc.isNotEmpty) {
      output.writeln('BCC: ${message.bcc.join(', ')}');
    }

    if (message.attachments.isNotEmpty) {
      output.writeln(
          'Attachments: ${message.attachments.map((a) => a.filename).join(', ')}');
    }

    output.writeln(
        'Content-Type: ${message.isHtml ? 'text/html' : 'text/plain'}');
    output.writeln('');
    output.writeln(message.body);
    output.writeln(divider);

    return EmailResult.success(
        'console-${DateTime.now().millisecondsSinceEpoch}');
  }

  @override
  Future<List<EmailResult>> sendEmails(List<EmailMessage> messages) async {
    final results = <EmailResult>[];

    for (final message in messages) {
      final result = await sendEmail(message);
      results.add(result);
    }

    return results;
  }

  @override
  Future<void> close() async {
    // Console output doesn't need closing
  }
}

class FileEmailBackend implements EmailBackend {
  final String directory;
  final String filePrefix;

  FileEmailBackend({
    this.directory = 'emails',
    this.filePrefix = 'email_',
  });

  @override
  Future<EmailResult> sendEmail(EmailMessage message) async {
    try {
      final dir = Directory(directory);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = '$filePrefix$timestamp.json';
      final file = File('$directory/$filename');

      final emailData = {
        'timestamp': DateTime.now().toIso8601String(),
        'message': message.toJson(),
      };

      await file.writeAsString(jsonEncode(emailData));
      return EmailResult.success(filename);
    } catch (e) {
      return EmailResult.error(e.toString());
    }
  }

  @override
  Future<List<EmailResult>> sendEmails(List<EmailMessage> messages) async {
    final results = <EmailResult>[];

    for (final message in messages) {
      final result = await sendEmail(message);
      results.add(result);
    }

    return results;
  }

  @override
  Future<void> close() async {
    // File backend doesn't need closing
  }
}

class InMemoryEmailBackend implements EmailBackend {
  final List<EmailMessage> _sentEmails = [];

  List<EmailMessage> get sentEmails => List.unmodifiable(_sentEmails);

  @override
  Future<EmailResult> sendEmail(EmailMessage message) async {
    _sentEmails.add(message);
    return EmailResult.success('memory-${_sentEmails.length}');
  }

  @override
  Future<List<EmailResult>> sendEmails(List<EmailMessage> messages) async {
    final results = <EmailResult>[];

    for (final message in messages) {
      final result = await sendEmail(message);
      results.add(result);
    }

    return results;
  }

  @override
  Future<void> close() async {
    // In-memory backend doesn't need closing
  }

  void clear() {
    _sentEmails.clear();
  }
}

class EmailService {
  final EmailBackend backend;
  final String? defaultFrom;

  EmailService({
    required this.backend,
    this.defaultFrom,
  });

  Future<EmailResult> sendEmail({
    required String subject,
    required String body,
    String? from,
    required List<String> to,
    List<String>? cc,
    List<String>? bcc,
    List<EmailAttachment>? attachments,
    Map<String, String>? headers,
    bool isHtml = false,
  }) async {
    final message = EmailMessage(
      subject: subject,
      body: body,
      from: from ?? defaultFrom ?? 'noreply@example.com',
      to: to,
      cc: cc ?? [],
      bcc: bcc ?? [],
      attachments: attachments ?? [],
      headers: headers ?? {},
      isHtml: isHtml,
    );

    return await backend.sendEmail(message);
  }

  Future<EmailResult> sendTextEmail({
    required String subject,
    required String body,
    String? from,
    required List<String> to,
    List<String>? cc,
    List<String>? bcc,
    List<EmailAttachment>? attachments,
    Map<String, String>? headers,
  }) async {
    return await sendEmail(
      subject: subject,
      body: body,
      from: from,
      to: to,
      cc: cc,
      bcc: bcc,
      attachments: attachments,
      headers: headers,
      isHtml: false,
    );
  }

  Future<EmailResult> sendHtmlEmail({
    required String subject,
    required String body,
    String? from,
    required List<String> to,
    List<String>? cc,
    List<String>? bcc,
    List<EmailAttachment>? attachments,
    Map<String, String>? headers,
  }) async {
    return await sendEmail(
      subject: subject,
      body: body,
      from: from,
      to: to,
      cc: cc,
      bcc: bcc,
      attachments: attachments,
      headers: headers,
      isHtml: true,
    );
  }

  Future<List<EmailResult>> sendBulkEmails(List<EmailMessage> messages) async {
    return await backend.sendEmails(messages);
  }

  Future<void> close() async {
    await backend.close();
  }
}

class EmailTemplate {
  final String name;
  final String subject;
  final String textBody;
  final String? htmlBody;
  final Map<String, dynamic> defaultContext;

  EmailTemplate({
    required this.name,
    required this.subject,
    required this.textBody,
    this.htmlBody,
    this.defaultContext = const {},
  });

  String renderSubject(Map<String, dynamic> context) {
    return _renderTemplate(subject, {...defaultContext, ...context});
  }

  String renderText(Map<String, dynamic> context) {
    return _renderTemplate(textBody, {...defaultContext, ...context});
  }

  String? renderHtml(Map<String, dynamic> context) {
    if (htmlBody == null) return null;
    return _renderTemplate(htmlBody!, {...defaultContext, ...context});
  }

  String _renderTemplate(String template, Map<String, dynamic> context) {
    String result = template;
    for (final entry in context.entries) {
      result = result.replaceAll('{{${entry.key}}}', entry.value.toString());
    }
    return result;
  }

  EmailMessage createMessage({
    required String from,
    required List<String> to,
    required Map<String, dynamic> context,
    List<String>? cc,
    List<String>? bcc,
    List<EmailAttachment>? attachments,
    Map<String, String>? headers,
  }) {
    return EmailMessage(
      subject: renderSubject(context),
      body: renderHtml(context) ?? renderText(context),
      from: from,
      to: to,
      cc: cc ?? [],
      bcc: bcc ?? [],
      attachments: attachments ?? [],
      headers: headers ?? {},
      isHtml: htmlBody != null,
    );
  }
}

class EmailConfiguration {
  final String backend;
  final String? host;
  final int? port;
  final String? username;
  final String? password;
  final bool ssl;
  final bool tls;
  final String? defaultFrom;
  final Duration timeout;

  const EmailConfiguration({
    this.backend = 'console',
    this.host,
    this.port,
    this.username,
    this.password,
    this.ssl = false,
    this.tls = true,
    this.defaultFrom,
    this.timeout = const Duration(seconds: 30),
  });

  EmailService createService() {
    final backend = createBackend();
    return EmailService(
      backend: backend,
      defaultFrom: defaultFrom,
    );
  }

  EmailBackend createBackend() {
    switch (backend) {
      case 'smtp':
        return SmtpEmailBackend(
          host: host ?? 'localhost',
          port: port ?? 587,
          username: username,
          password: password,
          ssl: ssl,
          tls: tls,
          timeout: timeout,
        );
      case 'file':
        return FileEmailBackend();
      case 'memory':
        return InMemoryEmailBackend();
      case 'console':
      default:
        return ConsoleEmailBackend();
    }
  }
}

// Common email templates
class WelcomeEmailTemplate extends EmailTemplate {
  WelcomeEmailTemplate()
      : super(
          name: 'welcome',
          subject: 'Welcome to {{app_name}}!',
          textBody: '''
Hello {{user_name}},

Welcome to {{app_name}}! We're excited to have you on board.

Your account has been created successfully. You can now start using our services.

Best regards,
The {{app_name}} Team
          ''',
          htmlBody: '''
<h2>Welcome to {{app_name}}!</h2>
<p>Hello {{user_name}},</p>
<p>Welcome to {{app_name}}! We're excited to have you on board.</p>
<p>Your account has been created successfully. You can now start using our services.</p>
<p>Best regards,<br>The {{app_name}} Team</p>
          ''',
        );
}

class PasswordResetEmailTemplate extends EmailTemplate {
  PasswordResetEmailTemplate()
      : super(
          name: 'password_reset',
          subject: 'Password Reset Request',
          textBody: '''
Hello {{user_name}},

You have requested to reset your password for {{app_name}}.

Please click the following link to reset your password:
{{reset_url}}

This link will expire in {{expiry_hours}} hours.

If you did not request this password reset, please ignore this email.

Best regards,
The {{app_name}} Team
          ''',
          htmlBody: '''
<h2>Password Reset Request</h2>
<p>Hello {{user_name}},</p>
<p>You have requested to reset your password for {{app_name}}.</p>
<p><a href="{{reset_url}}" style="background-color: #007bff; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">Reset Password</a></p>
<p>This link will expire in {{expiry_hours}} hours.</p>
<p>If you did not request this password reset, please ignore this email.</p>
<p>Best regards,<br>The {{app_name}} Team</p>
          ''',
        );
}
