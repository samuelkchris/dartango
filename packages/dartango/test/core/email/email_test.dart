import 'dart:convert';
import 'package:test/test.dart';

import '../../../lib/src/core/email/backend.dart';

void main() {
  group('EmailMessage', () {
    test('should create email with required fields', () {
      final email = EmailMessage(
        subject: 'Test Subject',
        body: 'Test Body',
        from: 'sender@example.com',
        to: ['recipient@example.com'],
      );

      expect(email.subject, equals('Test Subject'));
      expect(email.body, equals('Test Body'));
      expect(email.from, equals('sender@example.com'));
      expect(email.to, equals(['recipient@example.com']));
      expect(email.cc, isEmpty);
      expect(email.bcc, isEmpty);
      expect(email.attachments, isEmpty);
      expect(email.headers, isEmpty);
      expect(email.isHtml, isFalse);
      expect(email.createdAt, isA<DateTime>());
    });

    test('should create email with all fields', () {
      final now = DateTime.now();
      final email = EmailMessage(
        subject: 'Test Subject',
        body: '<h1>HTML Body</h1>',
        from: 'sender@example.com',
        to: ['recipient1@example.com', 'recipient2@example.com'],
        cc: ['cc@example.com'],
        bcc: ['bcc@example.com'],
        attachments: [
          EmailAttachment(
            filename: 'test.pdf',
            bytes: [1, 2, 3, 4],
          ),
        ],
        headers: {'X-Custom': 'value'},
        isHtml: true,
        createdAt: now,
      );

      expect(email.subject, equals('Test Subject'));
      expect(email.body, equals('<h1>HTML Body</h1>'));
      expect(email.from, equals('sender@example.com'));
      expect(email.to, hasLength(2));
      expect(email.cc, hasLength(1));
      expect(email.bcc, hasLength(1));
      expect(email.attachments, hasLength(1));
      expect(email.headers['X-Custom'], equals('value'));
      expect(email.isHtml, isTrue);
      expect(email.createdAt, equals(now));
    });

    test('should copy email with modifications', () {
      final original = EmailMessage(
        subject: 'Original',
        body: 'Original Body',
        from: 'sender@example.com',
        to: ['recipient@example.com'],
      );

      final copy = original.copyWith(
        subject: 'Modified',
        isHtml: true,
      );

      expect(copy.subject, equals('Modified'));
      expect(copy.body, equals('Original Body'));
      expect(copy.from, equals('sender@example.com'));
      expect(copy.isHtml, isTrue);
      expect(copy.createdAt, equals(original.createdAt));
    });

    test('should serialize to JSON', () {
      final email = EmailMessage(
        subject: 'Test',
        body: 'Body',
        from: 'sender@example.com',
        to: ['recipient@example.com'],
        cc: ['cc@example.com'],
        bcc: ['bcc@example.com'],
        headers: {'X-Custom': 'value'},
        isHtml: true,
      );

      final json = email.toJson();

      expect(json['subject'], equals('Test'));
      expect(json['body'], equals('Body'));
      expect(json['from'], equals('sender@example.com'));
      expect(json['to'], equals(['recipient@example.com']));
      expect(json['cc'], equals(['cc@example.com']));
      expect(json['bcc'], equals(['bcc@example.com']));
      expect(json['headers'], equals({'X-Custom': 'value'}));
      expect(json['is_html'], isTrue);
      expect(json['created_at'], isA<String>());
      expect(json['attachments'], isList);
    });

    test('should deserialize from JSON', () {
      final json = {
        'subject': 'Test Subject',
        'body': 'Test Body',
        'from': 'sender@example.com',
        'to': ['recipient@example.com'],
        'cc': ['cc@example.com'],
        'bcc': ['bcc@example.com'],
        'attachments': [],
        'headers': {'X-Custom': 'value'},
        'is_html': true,
        'created_at': DateTime.now().toIso8601String(),
      };

      final email = EmailMessage.fromJson(json);

      expect(email.subject, equals('Test Subject'));
      expect(email.body, equals('Test Body'));
      expect(email.from, equals('sender@example.com'));
      expect(email.to, equals(['recipient@example.com']));
      expect(email.cc, equals(['cc@example.com']));
      expect(email.bcc, equals(['bcc@example.com']));
      expect(email.headers, equals({'X-Custom': 'value'}));
      expect(email.isHtml, isTrue);
    });

    test('should serialize and deserialize attachments', () {
      final attachment = EmailAttachment(
        filename: 'test.pdf',
        bytes: [72, 101, 108, 108, 111],
        contentType: 'application/pdf',
        contentId: 'test-id',
      );

      final email = EmailMessage(
        subject: 'Test',
        body: 'Body',
        from: 'sender@example.com',
        to: ['recipient@example.com'],
        attachments: [attachment],
      );

      final json = email.toJson();
      final restored = EmailMessage.fromJson(json);

      expect(restored.attachments, hasLength(1));
      expect(restored.attachments[0].filename, equals('test.pdf'));
      expect(restored.attachments[0].bytes, equals([72, 101, 108, 108, 111]));
      expect(restored.attachments[0].contentType, equals('application/pdf'));
      expect(restored.attachments[0].contentId, equals('test-id'));
    });
  });

  group('EmailAttachment', () {
    test('should create attachment with required fields', () {
      final attachment = EmailAttachment(
        filename: 'document.pdf',
        bytes: [1, 2, 3, 4, 5],
      );

      expect(attachment.filename, equals('document.pdf'));
      expect(attachment.bytes, equals([1, 2, 3, 4, 5]));
      expect(attachment.contentType, isNull);
      expect(attachment.contentId, isNull);
    });

    test('should create attachment with all fields', () {
      final attachment = EmailAttachment(
        filename: 'image.jpg',
        bytes: [255, 216, 255],
        contentType: 'image/jpeg',
        contentId: 'img123',
      );

      expect(attachment.filename, equals('image.jpg'));
      expect(attachment.bytes, equals([255, 216, 255]));
      expect(attachment.contentType, equals('image/jpeg'));
      expect(attachment.contentId, equals('img123'));
    });

    test('should serialize to JSON with base64 encoding', () {
      final attachment = EmailAttachment(
        filename: 'test.txt',
        bytes: [72, 101, 108, 108, 111],
        contentType: 'text/plain',
      );

      final json = attachment.toJson();

      expect(json['filename'], equals('test.txt'));
      expect(json['bytes'], isA<String>());
      expect(json['content_type'], equals('text/plain'));

      final decoded = base64Decode(json['bytes']);
      expect(decoded, equals([72, 101, 108, 108, 111]));
    });

    test('should deserialize from JSON', () {
      final json = {
        'filename': 'test.txt',
        'bytes': base64Encode([72, 101, 108, 108, 111]),
        'content_type': 'text/plain',
        'content_id': 'txt-1',
      };

      final attachment = EmailAttachment.fromJson(json);

      expect(attachment.filename, equals('test.txt'));
      expect(attachment.bytes, equals([72, 101, 108, 108, 111]));
      expect(attachment.contentType, equals('text/plain'));
      expect(attachment.contentId, equals('txt-1'));
    });

    test('should handle round-trip serialization', () {
      final original = EmailAttachment(
        filename: 'data.bin',
        bytes: List.generate(256, (i) => i),
        contentType: 'application/octet-stream',
        contentId: 'bin-123',
      );

      final json = original.toJson();
      final restored = EmailAttachment.fromJson(json);

      expect(restored.filename, equals(original.filename));
      expect(restored.bytes, equals(original.bytes));
      expect(restored.contentType, equals(original.contentType));
      expect(restored.contentId, equals(original.contentId));
    });
  });

  group('EmailResult', () {
    test('should create success result', () {
      final result = EmailResult.success('msg-123');

      expect(result.success, isTrue);
      expect(result.messageId, equals('msg-123'));
      expect(result.error, isNull);
      expect(result.sentAt, isA<DateTime>());
    });

    test('should create error result', () {
      final result = EmailResult.error('SMTP connection failed');

      expect(result.success, isFalse);
      expect(result.messageId, isNull);
      expect(result.error, equals('SMTP connection failed'));
      expect(result.sentAt, isA<DateTime>());
    });

    test('should create result with custom sent time', () {
      final customTime = DateTime(2024, 1, 1, 12, 0);
      final result = EmailResult(
        success: true,
        messageId: 'msg-456',
        sentAt: customTime,
      );

      expect(result.sentAt, equals(customTime));
    });

    test('should have error when success is false', () {
      final result = EmailResult(
        success: false,
        error: 'Network error',
      );

      expect(result.success, isFalse);
      expect(result.error, isNotNull);
    });
  });

  group('Email Integration Tests', () {
    test('should handle multiple recipients', () {
      final email = EmailMessage(
        subject: 'Newsletter',
        body: 'Welcome!',
        from: 'newsletter@example.com',
        to: [
          'user1@example.com',
          'user2@example.com',
          'user3@example.com',
        ],
        cc: ['manager@example.com'],
        bcc: ['audit@example.com'],
      );

      expect(email.to, hasLength(3));
      expect(email.cc, hasLength(1));
      expect(email.bcc, hasLength(1));

      final json = email.toJson();
      final restored = EmailMessage.fromJson(json);

      expect(restored.to, equals(email.to));
      expect(restored.cc, equals(email.cc));
      expect(restored.bcc, equals(email.bcc));
    });

    test('should handle HTML email with inline images', () {
      final htmlBody = '''
        <html>
          <body>
            <h1>Welcome</h1>
            <img src="cid:logo"/>
          </body>
        </html>
      ''';

      final email = EmailMessage(
        subject: 'HTML Email',
        body: htmlBody,
        from: 'sender@example.com',
        to: ['recipient@example.com'],
        attachments: [
          EmailAttachment(
            filename: 'logo.png',
            bytes: [137, 80, 78, 71],
            contentType: 'image/png',
            contentId: 'logo',
          ),
        ],
        isHtml: true,
      );

      expect(email.isHtml, isTrue);
      expect(email.attachments, hasLength(1));
      expect(email.attachments[0].contentId, equals('logo'));
    });

    test('should handle email with custom headers', () {
      final email = EmailMessage(
        subject: 'Custom Headers',
        body: 'Test',
        from: 'sender@example.com',
        to: ['recipient@example.com'],
        headers: {
          'X-Priority': '1',
          'X-Mailer': 'Dartango Email Backend',
          'Reply-To': 'noreply@example.com',
          'Message-ID': '<unique-id@example.com>',
        },
      );

      expect(email.headers, hasLength(4));
      expect(email.headers['X-Priority'], equals('1'));
      expect(email.headers['X-Mailer'], equals('Dartango Email Backend'));
      expect(email.headers['Reply-To'], equals('noreply@example.com'));
    });

    test('should handle large attachments', () {
      final largeData = List.generate(1024 * 100, (i) => i % 256);

      final attachment = EmailAttachment(
        filename: 'large-file.bin',
        bytes: largeData,
        contentType: 'application/octet-stream',
      );

      final email = EmailMessage(
        subject: 'Large Attachment',
        body: 'See attached file',
        from: 'sender@example.com',
        to: ['recipient@example.com'],
        attachments: [attachment],
      );

      final json = email.toJson();
      final restored = EmailMessage.fromJson(json);

      expect(restored.attachments[0].bytes, equals(largeData));
      expect(restored.attachments[0].bytes, hasLength(1024 * 100));
    });

    test('should handle empty optional fields', () {
      final email = EmailMessage(
        subject: 'Minimal',
        body: 'Body',
        from: 'sender@example.com',
        to: ['recipient@example.com'],
      );

      final json = email.toJson();
      final restored = EmailMessage.fromJson(json);

      expect(restored.cc, isEmpty);
      expect(restored.bcc, isEmpty);
      expect(restored.attachments, isEmpty);
      expect(restored.headers, isEmpty);
      expect(restored.isHtml, isFalse);
    });

    test('should preserve timestamp through serialization', () {
      final timestamp = DateTime(2024, 6, 15, 10, 30, 45);
      final email = EmailMessage(
        subject: 'Timestamped',
        body: 'Test',
        from: 'sender@example.com',
        to: ['recipient@example.com'],
        createdAt: timestamp,
      );

      final json = email.toJson();
      final restored = EmailMessage.fromJson(json);

      expect(restored.createdAt.year, equals(timestamp.year));
      expect(restored.createdAt.month, equals(timestamp.month));
      expect(restored.createdAt.day, equals(timestamp.day));
      expect(restored.createdAt.hour, equals(timestamp.hour));
      expect(restored.createdAt.minute, equals(timestamp.minute));
    });

    test('should handle email copying with partial updates', () {
      final original = EmailMessage(
        subject: 'Original',
        body: 'Original Body',
        from: 'original@example.com',
        to: ['recipient@example.com'],
        cc: ['cc@example.com'],
        isHtml: false,
      );

      final modified1 = original.copyWith(subject: 'Modified Subject');
      expect(modified1.subject, equals('Modified Subject'));
      expect(modified1.body, equals('Original Body'));
      expect(modified1.cc, equals(['cc@example.com']));

      final modified2 = original.copyWith(
        to: ['new-recipient@example.com'],
        isHtml: true,
      );
      expect(modified2.to, equals(['new-recipient@example.com']));
      expect(modified2.isHtml, isTrue);
      expect(modified2.subject, equals('Original'));
    });
  });

  group('Email Validation Scenarios', () {
    test('should handle unicode in subject and body', () {
      final email = EmailMessage(
        subject: 'Hello 世界 🌍',
        body: 'Email with émojis and spëcial çharacters',
        from: 'sender@example.com',
        to: ['recipient@example.com'],
      );

      final json = email.toJson();
      final restored = EmailMessage.fromJson(json);

      expect(restored.subject, equals('Hello 世界 🌍'));
      expect(restored.body, equals('Email with émojis and spëcial çharacters'));
    });

    test('should handle multiple attachments of different types', () {
      final email = EmailMessage(
        subject: 'Multiple Attachments',
        body: 'See attached files',
        from: 'sender@example.com',
        to: ['recipient@example.com'],
        attachments: [
          EmailAttachment(
            filename: 'document.pdf',
            bytes: [37, 80, 68, 70],
            contentType: 'application/pdf',
          ),
          EmailAttachment(
            filename: 'image.jpg',
            bytes: [255, 216, 255],
            contentType: 'image/jpeg',
          ),
          EmailAttachment(
            filename: 'data.csv',
            bytes: utf8.encode('a,b,c\n1,2,3'),
            contentType: 'text/csv',
          ),
        ],
      );

      expect(email.attachments, hasLength(3));
      expect(email.attachments[0].contentType, equals('application/pdf'));
      expect(email.attachments[1].contentType, equals('image/jpeg'));
      expect(email.attachments[2].contentType, equals('text/csv'));
    });

    test('should handle result with all fields', () {
      final result = EmailResult(
        success: true,
        messageId: 'msg-789',
        error: null,
        sentAt: DateTime(2024, 1, 1),
      );

      expect(result.success, isTrue);
      expect(result.messageId, equals('msg-789'));
      expect(result.error, isNull);
    });
  });
}
