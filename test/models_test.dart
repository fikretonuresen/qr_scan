import 'package:flutter_test/flutter_test.dart';
import 'package:qr_scan/qr_scan.dart';

void main() {
  group('ScannedBarcode', () {
    test('constructs with all fields', () {
      const barcode = ScannedBarcode(
        rawValue: 'https://example.com',
        displayValue: 'example.com',
        format: BarcodeFormat.qrCode,
        type: BarcodeType.url,
      );

      expect(barcode.rawValue, 'https://example.com');
      expect(barcode.displayValue, 'example.com');
      expect(barcode.format, BarcodeFormat.qrCode);
      expect(barcode.type, BarcodeType.url);
    });

    test('allows null rawValue and displayValue', () {
      const barcode = ScannedBarcode(
        format: BarcodeFormat.ean13,
        type: BarcodeType.unknown,
      );

      expect(barcode.rawValue, isNull);
      expect(barcode.displayValue, isNull);
    });

    test('is const-constructible', () {
      // Verifies the constructor is truly const — compile-time check
      const a = ScannedBarcode(
        rawValue: 'test',
        format: BarcodeFormat.qrCode,
        type: BarcodeType.text,
      );
      const b = ScannedBarcode(
        rawValue: 'test',
        format: BarcodeFormat.qrCode,
        type: BarcodeType.text,
      );
      // Same const values should be identical in Dart
      expect(identical(a, b), isTrue);
    });

    test('supports all common BarcodeFormat values', () {
      final formats = [
        BarcodeFormat.qrCode,
        BarcodeFormat.code128,
        BarcodeFormat.code39,
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.upca,
        BarcodeFormat.upce,
        BarcodeFormat.pdf417,
        BarcodeFormat.aztec,
        BarcodeFormat.dataMatrix,
        BarcodeFormat.itf,
        BarcodeFormat.codabar,
      ];

      for (final format in formats) {
        final barcode = ScannedBarcode(
          rawValue: 'value',
          format: format,
          type: BarcodeType.unknown,
        );
        expect(barcode.format, format);
      }
    });

    test('supports all BarcodeType values', () {
      final types = [
        BarcodeType.unknown,
        BarcodeType.contactInfo,
        BarcodeType.email,
        BarcodeType.isbn,
        BarcodeType.phone,
        BarcodeType.product,
        BarcodeType.sms,
        BarcodeType.text,
        BarcodeType.url,
        BarcodeType.wifi,
        BarcodeType.geoCoordinates,
        BarcodeType.calendarEvent,
        BarcodeType.driverLicense,
      ];

      for (final type in types) {
        final barcode = ScannedBarcode(
          rawValue: 'value',
          format: BarcodeFormat.qrCode,
          type: type,
        );
        expect(barcode.type, type);
      }
    });

    test('rawValue can be empty string', () {
      const barcode = ScannedBarcode(
        rawValue: '',
        format: BarcodeFormat.qrCode,
        type: BarcodeType.text,
      );
      expect(barcode.rawValue, '');
      expect(barcode.rawValue, isNotNull);
    });

    test('rawValue can contain special characters', () {
      const barcode = ScannedBarcode(
        rawValue: 'https://example.com/path?q=hello&lang=en#section',
        format: BarcodeFormat.qrCode,
        type: BarcodeType.url,
      );
      expect(
          barcode.rawValue, 'https://example.com/path?q=hello&lang=en#section');
    });

    test('rawValue can contain unicode', () {
      const barcode = ScannedBarcode(
        rawValue: '日本語テスト 🎉',
        format: BarcodeFormat.qrCode,
        type: BarcodeType.text,
      );
      expect(barcode.rawValue, '日本語テスト 🎉');
    });

    test('rawValue and displayValue can differ', () {
      const barcode = ScannedBarcode(
        rawValue: 'MECARD:N:John Doe;TEL:1234567890;;',
        displayValue: 'John Doe - 1234567890',
        format: BarcodeFormat.qrCode,
        type: BarcodeType.contactInfo,
      );
      expect(barcode.rawValue, isNot(equals(barcode.displayValue)));
    });

    test('displayValue null while rawValue present', () {
      const barcode = ScannedBarcode(
        rawValue: 'some-raw-data',
        displayValue: null,
        format: BarcodeFormat.code128,
        type: BarcodeType.unknown,
      );
      expect(barcode.rawValue, isNotNull);
      expect(barcode.displayValue, isNull);
    });
  });

  group('ScannedBarcode.fromMlKit', () {
    // Note: Barcode (from ML Kit) cannot be easily constructed in unit tests
    // without the native platform. The fromMlKit factory is integration-tested
    // via the real scanner pipeline. Here we verify the factory signature exists
    // and is accessible from the public API.
    test('factory exists and is callable type', () {
      // This test verifies the factory is exported and has the right type.
      // We can't call it without a real Barcode object from ML Kit.
      expect(ScannedBarcode.fromMlKit, isA<Function>());
    });
  });
}
