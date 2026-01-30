import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

import 'package:qr_scan/src/models.dart';

/// Manages communication with the background barcode processing isolate.
class Responder {
  Responder(
    this._isolate,
    this._receivePort,
    this._broadcastStream,
    this._isolateSendPort,
  );

  final Isolate _isolate;
  final ReceivePort _receivePort;
  final Stream<dynamic> _broadcastStream;
  final SendPort _isolateSendPort;
  bool _disposed = false;

  /// Creates a new background isolate for barcode processing.
  /// [formats] determines which barcode formats the scanner will detect.
  static Future<Responder> createImageProcessor({
    List<BarcodeFormat> formats = const [BarcodeFormat.all],
  }) async {
    final rootIsolateToken = RootIsolateToken.instance;
    if (rootIsolateToken == null) {
      throw StateError('RootIsolateToken is not available');
    }

    final receivePort = ReceivePort();
    final broadcastStream = receivePort.asBroadcastStream();

    final isolate = await Isolate.spawn(
      _barcodeIsolateEntryPoint,
      IsolateInitConfig(
        sendPort: receivePort.sendPort,
        rootIsolateToken: rootIsolateToken,
        formats: formats,
      ),
    );

    // Wait for the isolate to send back its SendPort (handshake)
    final isolateSendPort = await broadcastStream
        .where((message) => message is SendPort)
        .cast<SendPort>()
        .first;

    final responder = Responder(
      isolate,
      receivePort,
      broadcastStream,
      isolateSendPort,
    );
    return responder;
  }

  /// Sends an image to the isolate for processing and awaits results.
  Future<List<ScannedBarcode>> getProcessedImages(InputImage inputImage) async {
    if (_disposed) return [];
    _isolateSendPort.send(inputImage);
    try {
      final result = await _broadcastStream
          .where((message) => message is List<ScannedBarcode>)
          .cast<List<ScannedBarcode>>()
          .first;
      return result;
    } catch (e) {
      // Stream closed during dispose — expected, not an error
      return [];
    }
  }

  /// Disposes the isolate and cleans up resources.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    try {
      _isolateSendPort.send('dispose');
    } catch (_) {
      // If send fails, isolate is already gone — just cleanup
      _receivePort.close();
      return;
    }
    // Listen for the 'disposed' acknowledgment, then cleanup.
    // Use a timeout as safety net in case isolate is stuck.
    _broadcastStream
        .where((message) => message == 'disposed')
        .first
        .timeout(const Duration(seconds: 2), onTimeout: () => 'timeout')
        .whenComplete(() {
      _receivePort.close();
      _isolate.kill(priority: Isolate.immediate);
    });
  }
}

/// Entry point for the background barcode processing isolate.
@pragma('vm:entry-point')
Future<void> _barcodeIsolateEntryPoint(IsolateInitConfig config) async {
  // 1. Initialize background bindings
  BackgroundIsolateBinaryMessenger.ensureInitialized(config.rootIsolateToken);

  // 2. Initialize scanner with correct formats immediately
  final barcodeScanner = BarcodeScanner(formats: config.formats);

  // 3. Setup communication — send our SendPort back to main isolate
  final receivePort = ReceivePort();
  config.sendPort.send(receivePort.sendPort);

  // 4. Process loop
  await for (final message in receivePort) {
    if (message == 'dispose') {
      // CRITICAL: Close scanner FIRST — cancels pending native ML Kit operations
      await barcodeScanner.close();
      // Signal back that cleanup is done
      try {
        config.sendPort.send('disposed');
      } catch (_) {}
      receivePort.close();
      break;
    }
    if (message is InputImage) {
      List<ScannedBarcode> result;
      try {
        final barcodes = await barcodeScanner.processImage(message);
        result = barcodes.map((b) => ScannedBarcode.fromMlKit(b)).toList();
      } catch (_) {
        result = <ScannedBarcode>[];
      }
      try {
        config.sendPort.send(result);
      } catch (_) {
        // Port closed during dispose — expected
      }
    }
  }
}
