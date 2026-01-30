import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:qr_scan/models.dart';

/// Utility for scanning barcodes from still images (e.g., gallery photos).
///
/// This is independent of the camera widget — a pure utility function.
///
/// Usage:
/// ```dart
/// final inputImage = InputImage.fromFilePath('/path/to/image.jpg');
/// final barcodes = await scanImageForBarcodes(inputImage);
/// ```
Future<List<ScannedBarcode>> scanImageForBarcodes(
  InputImage image, {
  List<BarcodeFormat> formats = const [BarcodeFormat.all],
}) async {
  final scanner = BarcodeScanner(formats: formats);
  try {
    final barcodes = await scanner.processImage(image);
    return barcodes.map((b) => ScannedBarcode.fromMlKit(b)).toList();
  } finally {
    await scanner.close();
  }
}
