import 'dart:async';
import 'package:test/test.dart';

import '../lib/src/core/signals/signals.dart';

void main() {
  group('Signals System Tests', () {
    late Signal<String> testSignal;
    late SignalTestHelper helper;

    setUp(() {
      testSignal = Signal<String>(name: 'test_signal');
      helper = SignalTestHelper();
    });

    tearDown(() {
      testSignal.disconnect();
    });

    group('Signal Creation', () {
      test('should create signal with name', () {
        final signal = Signal<String>(name: 'test');
        expect(signal.name, equals('test'));
        expect(signal.hasListeners, isFalse);
        expect(signal.receiversCount, equals(0));
      });

      test('should create signal with providing args', () {
        final signal = Signal<String>(
          name: 'test',
          providingArgs: true,
          validArguments: ['arg1', 'arg2'],
        );
        expect(signal.providingArgs, isTrue);
        expect(signal.validArguments, equals(['arg1', 'arg2']));
      });
    });

    group('Signal Connection', () {
      test('should connect receiver to signal', () {
        testSignal.connect(receiver: helper.captureSignal);
        expect(testSignal.hasListeners, isTrue);
        expect(testSignal.receiversCount, equals(1));
      });

      test('should connect multiple receivers', () {
        testSignal.connect(receiver: helper.captureSignal);
        testSignal.connect(receiver: _dummyReceiver);
        expect(testSignal.receiversCount, equals(2));
      });

      test('should connect with dispatch_uid', () {
        testSignal.connect(
          receiver: helper.captureSignal,
          dispatchUid: 'test_uid',
        );
        expect(testSignal.receiversCount, equals(1));

        // Connecting again with same dispatch_uid should throw
        expect(
          () => testSignal.connect(
            receiver: _dummyReceiver,
            dispatchUid: 'test_uid',
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should connect with sender filter', () {
        testSignal.connect(
          receiver: helper.captureSignal,
          sender: String,
        );
        expect(testSignal.receiversCount, equals(1));
      });

      test('should connect with weak reference', () {
        testSignal.connect(
          receiver: helper.captureSignal,
          weak: true,
        );
        expect(testSignal.receiversCount, equals(1));
      });
    });

    group('Signal Disconnection', () {
      test('should disconnect receiver', () {
        testSignal.connect(receiver: helper.captureSignal);
        expect(testSignal.receiversCount, equals(1));

        final disconnected =
            testSignal.disconnect(receiver: helper.captureSignal);
        expect(disconnected, isTrue);
        expect(testSignal.receiversCount, equals(0));
      });

      test('should disconnect by dispatch_uid', () {
        testSignal.connect(
          receiver: helper.captureSignal,
          dispatchUid: 'test_uid',
        );
        expect(testSignal.receiversCount, equals(1));

        final disconnected = testSignal.disconnect(dispatchUid: 'test_uid');
        expect(disconnected, isTrue);
        expect(testSignal.receiversCount, equals(0));
      });

      test('should disconnect by sender', () {
        testSignal.connect(
          receiver: helper.captureSignal,
          sender: String,
        );
        expect(testSignal.receiversCount, equals(1));

        final disconnected = testSignal.disconnect(sender: String);
        expect(disconnected, isTrue);
        expect(testSignal.receiversCount, equals(0));
      });

      test('should disconnect all receivers', () {
        testSignal.connect(receiver: helper.captureSignal);
        testSignal.connect(receiver: _dummyReceiver);
        expect(testSignal.receiversCount, equals(2));

        final disconnected = testSignal.disconnect();
        expect(disconnected, isTrue);
        expect(testSignal.receiversCount, equals(0));
      });

      test('should return false when disconnecting non-existent receiver', () {
        final disconnected =
            testSignal.disconnect(receiver: helper.captureSignal);
        expect(disconnected, isFalse);
      });
    });

    group('Signal Sending', () {
      test('should send signal to connected receiver', () async {
        testSignal.connect(receiver: helper.captureSignal);

        final responses = await testSignal.send(sender: 'test_sender');
        expect(responses, hasLength(1));
        expect(responses.first.success, isTrue);
        expect(responses.first.sender, equals('test_sender'));

        expect(helper.wasReceived(), isTrue);
        expect(helper.receivedCount, equals(1));
      });

      test('should send signal with kwargs', () async {
        bool received = false;
        Map<String, dynamic>? receivedKwargs;

        Future<void> receiver(String sender,
            {Map<String, dynamic>? kwargs}) async {
          received = true;
          receivedKwargs = kwargs;
        }

        testSignal.connect(receiver: receiver);

        final kwargs = {'key1': 'value1', 'key2': 42};
        await testSignal.send(sender: 'test_sender', kwargs: kwargs);

        expect(received, isTrue);
        expect(receivedKwargs, equals(kwargs));
      });

      test('should send signal to multiple receivers', () async {
        final helper2 = SignalTestHelper();

        testSignal.connect(receiver: helper.captureSignal);
        testSignal.connect(receiver: helper2.captureSignal);

        final responses = await testSignal.send(sender: 'test_sender');
        expect(responses, hasLength(2));
        expect(responses.every((r) => r.success), isTrue);

        expect(helper.wasReceived(), isTrue);
        expect(helper2.wasReceived(), isTrue);
      });

      test('should filter by sender type', () async {
        testSignal.connect(
          receiver: helper.captureSignal,
          sender: String,
        );

        // Send with String sender - should be received
        await testSignal.send(sender: 'test_sender');
        expect(helper.receivedCount, equals(1));

        // Send with int sender - should not be received
        helper.clear();
        final intSignal = Signal<int>(name: 'int_signal');
        intSignal.connect(
          receiver: helper.captureSignal,
          sender: String,
        );
        await intSignal.send(sender: 123);
        expect(helper.receivedCount, equals(0));
      });

      test('should handle receiver exceptions', () async {
        Future<void> faultyReceiver(String sender,
            {Map<String, dynamic>? kwargs}) async {
          throw Exception('Receiver error');
        }

        testSignal.connect(receiver: faultyReceiver);
        testSignal.connect(receiver: helper.captureSignal);

        final responses = await testSignal.send(sender: 'test_sender');
        expect(responses, hasLength(2));

        expect(responses[0].success, isFalse);
        expect(responses[0].error, isA<Exception>());
        expect(responses[1].success, isTrue);

        expect(helper.wasReceived(), isTrue);
      });

      test('should validate arguments', () async {
        final signal = Signal<String>(
          name: 'test',
          validArguments: ['arg1', 'arg2'],
        );

        signal.connect(receiver: helper.captureSignal);

        // Valid arguments should work
        await signal.send(sender: 'test', kwargs: {'arg1': 'value1'});
        expect(helper.receivedCount, equals(1));

        // Invalid arguments should throw
        helper.clear();
        expect(
          () => signal.send(sender: 'test', kwargs: {'invalid': 'value'}),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should handle empty receivers list', () async {
        final responses = await testSignal.send(sender: 'test_sender');
        expect(responses, isEmpty);
      });
    });

    group('Signal Registry', () {
      test('should register and retrieve signals', () {
        final registry = SignalRegistry();
        final signal = Signal<String>(name: 'test');

        registry.register('test_signal', signal);

        final retrieved = registry.get<String>('test_signal');
        expect(retrieved, equals(signal));
      });

      test('should return null for non-existent signal', () {
        final registry = SignalRegistry();
        final retrieved = registry.get<String>('non_existent');
        expect(retrieved, isNull);
      });

      test('should list all registered signals', () {
        final registry = SignalRegistry();
        final signal1 = Signal<String>(name: 'signal1');
        final signal2 = Signal<int>(name: 'signal2');

        registry.register('signal1', signal1);
        registry.register('signal2', signal2);

        final all = registry.all;
        expect(all, hasLength(2));
        expect(all.containsKey('signal1'), isTrue);
        expect(all.containsKey('signal2'), isTrue);
      });

      test('should clear all signals', () {
        final registry = SignalRegistry();
        registry.register('signal1', Signal<String>(name: 'signal1'));
        registry.register('signal2', Signal<int>(name: 'signal2'));

        expect(registry.all, hasLength(2));

        registry.clear();
        expect(registry.all, isEmpty);
      });
    });

    group('Signal Context', () {
      test('should temporarily connect receivers', () async {
        final context = SignalContext();

        context.connect(
          signal: testSignal,
          receiver: helper.captureSignal,
        );

        // Should not be connected yet
        expect(testSignal.hasListeners, isFalse);

        await context.run(() async {
          // Should be connected now
          expect(testSignal.hasListeners, isTrue);
          await testSignal.send(sender: 'test');
        });

        // Should be disconnected after context
        expect(testSignal.hasListeners, isFalse);
        expect(helper.wasReceived(), isTrue);
      });

      test('should handle context errors', () async {
        final context = SignalContext();

        context.connect(
          signal: testSignal,
          receiver: helper.captureSignal,
        );

        try {
          await context.run(() async {
            throw Exception('Test error');
          });
          fail('Expected exception to be thrown');
        } catch (e) {
          expect(e, isA<Exception>());
        }

        // Should still be disconnected after error
        expect(testSignal.hasListeners, isFalse);
      });
    });

    group('Django Signals', () {
      test('should have all Django signals', () {
        expect(DjangoSignals.preInit.name, equals('pre_init'));
        expect(DjangoSignals.postInit.name, equals('post_init'));
        expect(DjangoSignals.preSave.name, equals('pre_save'));
        expect(DjangoSignals.postSave.name, equals('post_save'));
        expect(DjangoSignals.preDelete.name, equals('pre_delete'));
        expect(DjangoSignals.postDelete.name, equals('post_delete'));
        expect(DjangoSignals.preMigrate.name, equals('pre_migrate'));
        expect(DjangoSignals.postMigrate.name, equals('post_migrate'));
        expect(DjangoSignals.requestStarted.name, equals('request_started'));
        expect(DjangoSignals.requestFinished.name, equals('request_finished'));
        expect(DjangoSignals.gotRequestException.name,
            equals('got_request_exception'));
      });

      test('should register all Django signals', () {
        final registry = SignalRegistry();
        registry.clear();

        DjangoSignals.registerAll();

        expect(registry.get('pre_init'), isNotNull);
        expect(registry.get('post_init'), isNotNull);
        expect(registry.get('pre_save'), isNotNull);
        expect(registry.get('post_save'), isNotNull);
        expect(registry.get('pre_delete'), isNotNull);
        expect(registry.get('post_delete'), isNotNull);
        expect(registry.get('pre_migrate'), isNotNull);
        expect(registry.get('post_migrate'), isNotNull);
        expect(registry.get('request_started'), isNotNull);
        expect(registry.get('request_finished'), isNotNull);
        expect(registry.get('got_request_exception'), isNotNull);
      });
    });

    group('Signal Mixin', () {
      test('should send signals from mixin', () async {
        final sender = TestSignalSender();
        final signal = Signal<TestSignalSender>(name: 'test');

        signal.connect(receiver: helper.captureSignal);

        await sender.sendSignal(signal);
        expect(helper.wasReceived(senderType: TestSignalSender), isTrue);
      });
    });

    group('Signal Locking', () {
      test('should prevent connections during send', () async {
        testSignal.connect(receiver: helper.captureSignal);

        // Create a receiver that tries to connect during send
        Future<void> connectingReceiver(String sender,
            {Map<String, dynamic>? kwargs}) async {
          expect(
            () => testSignal.connect(receiver: _dummyReceiver),
            throwsA(isA<StateError>()),
          );
        }

        testSignal.connect(receiver: connectingReceiver);

        await testSignal.send(sender: 'test');
      });

      test('should prevent disconnections during send', () async {
        testSignal.connect(receiver: helper.captureSignal);

        // Create a receiver that tries to disconnect during send
        Future<void> disconnectingReceiver(String sender,
            {Map<String, dynamic>? kwargs}) async {
          expect(
            () => testSignal.disconnect(receiver: helper.captureSignal),
            throwsA(isA<StateError>()),
          );
        }

        testSignal.connect(receiver: disconnectingReceiver);

        await testSignal.send(sender: 'test');
      });
    });

    group('Signal Test Helper', () {
      test('should capture signal responses', () async {
        testSignal.connect(receiver: helper.captureSignal);

        await testSignal.send(sender: 'test1');
        await testSignal.send(sender: 'test2');

        expect(helper.receivedCount, equals(2));
        expect(helper.responses, hasLength(2));
        expect(helper.responses[0].sender, equals('test1'));
        expect(helper.responses[1].sender, equals('test2'));
      });

      test('should check if signal was received', () async {
        expect(helper.wasReceived(), isFalse);

        testSignal.connect(receiver: helper.captureSignal);
        await testSignal.send(sender: 'test');

        expect(helper.wasReceived(), isTrue);
        expect(helper.wasReceived(senderType: String), isTrue);
        expect(helper.wasReceived(senderType: int), isFalse);
      });

      test('should clear captured responses', () async {
        testSignal.connect(receiver: helper.captureSignal);
        await testSignal.send(sender: 'test');

        expect(helper.receivedCount, equals(1));

        helper.clear();

        expect(helper.receivedCount, equals(0));
        expect(helper.responses, isEmpty);
      });
    });

    group('Signal Initialization', () {
      test('should initialize signals system', () {
        final registry = SignalRegistry();
        registry.clear();

        initializeSignals();

        expect(registry.all, isNotEmpty);
        expect(registry.get('pre_save'), isNotNull);
        expect(registry.get('post_save'), isNotNull);
      });
    });
  });
}

// Helper functions and classes
Future<void> _dummyReceiver(String sender,
    {Map<String, dynamic>? kwargs}) async {
  // Do nothing
}

class TestSignalSender with SignalSender {
  String get name => 'TestSignalSender';
}
