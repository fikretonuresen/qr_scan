import 'dart:async';

import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:qr_scan/src/models.dart';

/// Scans barcodes from a still image (e.g., a gallery photo).
///
/// This is independent of the camera widget — a pure utility function.
///
/// [timeout] guards against ML Kit hanging on corrupted or very large images.
/// Defaults to 10 seconds. Throws a [TimeoutException] if exceeded.
///
/// For best results, downscale images before scanning (e.g., max 1920px).
/// Very high-resolution images may cause slow processing or timeouts.
///
/// ```dart
/// final inputImage = InputImage.fromFilePath('/path/to/image.jpg');
/// final barcodes = await scanImageForBarcodes(inputImage);
/// ```
Future<List<ScannedBarcode>> scanImageForBarcodes(
  InputImage image, {
  List<BarcodeFormat> formats = const [BarcodeFormat.all],
  Duration timeout = const Duration(seconds: 10),
}) async {
  final scanner = BarcodeScanner(formats: formats);
  try {
    final barcodes = await scanner.processImage(image).timeout(timeout);
    return barcodes.map((b) => ScannedBarcode.fromMlKit(b)).toList();
  } finally {
    await scanner.close();
  }
}
