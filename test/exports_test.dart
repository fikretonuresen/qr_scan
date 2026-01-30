import 'package:flutter_test/flutter_test.dart';
import 'package:qr_scan/qr_scan.dart';

/// Verifies the public API surface exported from package:qr_scan/qr_scan.dart.
/// If any export is removed or renamed, these tests will fail at compile time
/// or at the expect() checks, catching accidental breaking changes.
void main() {
  group('Public API exports', () {
    test('QrScan widget is exported', () {
      // ignore: unnecessary_type_check
      expect(QrScan.new, isA<Function>());
    });

    test('QrScanController is exported', () {
      final controller = QrScanController();
      expect(controller, isA<QrScanController>());
      controller.dispose();
    });

    test('ScannedBarcode is exported', () {
      const barcode = ScannedBarcode(
        format: BarcodeFormat.qrCode,
        type: BarcodeType.unknown,
      );
      expect(barcode, isA<ScannedBarcode>());
    });

    test('ScanSoundResult is exported', () {
      expect(ScanSoundResult.success, isA<ScanSoundResult>());
    });

    test('scanImageForBarcodes function is exported', () {
      expect(scanImageForBarcodes, isA<Function>());
    });

    test('BarcodeFormat is re-exported', () {
      expect(BarcodeFormat.qrCode, isA<BarcodeFormat>());
    });

    test('BarcodeType is re-exported', () {
      expect(BarcodeType.url, isA<BarcodeType>());
    });

    test('InputImage is re-exported', () {
      // Verify InputImage class is accessible (can't construct without file)
      expect(InputImage.fromFilePath, isA<Function>());
    });
  });
}
