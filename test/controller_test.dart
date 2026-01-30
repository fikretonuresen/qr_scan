import 'package:flutter_test/flutter_test.dart';
import 'package:qr_scan/qr_scan.dart';

void main() {
  group('QrScanController', () {
    late QrScanController controller;

    setUp(() {
      controller = QrScanController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('starts with isScanning true', () {
      expect(controller.isScanning, isTrue);
    });

    test('pause sets isScanning to false', () {
      controller.pause();
      expect(controller.isScanning, isFalse);
    });

    test('resume sets isScanning to true', () {
      controller.pause();
      controller.resume();
      expect(controller.isScanning, isTrue);
    });

    test('toggle flips state', () {
      controller.toggle(); // true → false
      expect(controller.isScanning, isFalse);
      controller.toggle(); // false → true
      expect(controller.isScanning, isTrue);
    });

    // --- Edge cases: idempotent calls ---

    test('pause is idempotent — calling twice does not notify twice', () {
      int notifyCount = 0;
      controller.addListener(() => notifyCount++);

      controller.pause();
      controller.pause();

      expect(controller.isScanning, isFalse);
      expect(notifyCount, 1, reason: 'Second pause should be a no-op');
    });

    test('resume is idempotent — calling on already-scanning is a no-op', () {
      int notifyCount = 0;
      controller.addListener(() => notifyCount++);

      controller.resume(); // already scanning

      expect(controller.isScanning, isTrue);
      expect(notifyCount, 0, reason: 'Resume on active scanner is a no-op');
    });

    test('resume after pause notifies exactly once', () {
      controller.pause();

      int notifyCount = 0;
      controller.addListener(() => notifyCount++);

      controller.resume();
      controller.resume(); // idempotent

      expect(notifyCount, 1);
    });

    // --- Notification counting ---

    test('toggle always notifies listeners', () {
      int notifyCount = 0;
      controller.addListener(() => notifyCount++);

      controller.toggle();
      controller.toggle();
      controller.toggle();

      expect(notifyCount, 3, reason: 'toggle always changes state');
    });

    test('pause-resume cycle notifies exactly twice', () {
      int notifyCount = 0;
      controller.addListener(() => notifyCount++);

      controller.pause();
      controller.resume();

      expect(notifyCount, 2);
    });

    // --- Rapid state changes ---

    test('rapid toggle produces correct final state', () {
      // Start: true
      for (int i = 0; i < 100; i++) {
        controller.toggle();
      }
      // 100 toggles from true → should end at true (even count)
      expect(controller.isScanning, isTrue);
    });

    test('rapid toggle with odd count ends at false', () {
      for (int i = 0; i < 99; i++) {
        controller.toggle();
      }
      expect(controller.isScanning, isFalse);
    });

    // --- Listener management ---

    test('removed listener does not receive notifications', () {
      int notifyCount = 0;
      void listener() => notifyCount++;

      controller.addListener(listener);
      controller.pause();
      expect(notifyCount, 1);

      controller.removeListener(listener);
      controller.resume();
      expect(notifyCount, 1, reason: 'Removed listener should not be called');
    });

    test('multiple listeners all receive notifications', () {
      int count1 = 0;
      int count2 = 0;
      controller.addListener(() => count1++);
      controller.addListener(() => count2++);

      controller.toggle();

      expect(count1, 1);
      expect(count2, 1);
    });

    // --- Use after dispose ---

    test('using controller after dispose throws', () {
      controller.dispose();
      expect(() => controller.pause(), throwsFlutterError);
      // Re-create so tearDown doesn't double-dispose
      controller = QrScanController();
    });

    test('toggle after dispose throws', () {
      controller.dispose();
      expect(() => controller.toggle(), throwsFlutterError);
      controller = QrScanController();
    });

    test('resume after dispose throws', () {
      // pause first so resume would actually call notifyListeners
      controller.pause();
      controller.dispose();
      expect(() => controller.resume(), throwsFlutterError);
      controller = QrScanController();
    });
  });
}
