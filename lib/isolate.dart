import "dart:isolate";

import "package:flutter/services.dart";
import "package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart";

class Responder {
  Responder(this.rp, this.broadcastRp, this.communicatorSendPort);

  final ReceivePort rp;
  final Stream<dynamic> broadcastRp;
  final SendPort communicatorSendPort;

  static Future<Responder> createImageProcessor() async {
    final rootIsolateToken = RootIsolateToken.instance;
    final rp = ReceivePort();
    await Isolate.spawn(_imageProcessCommunicator, rp.sendPort);
    final broadcastRp = rp.asBroadcastStream();
    final SendPort communicatorSendPort = await broadcastRp.takeWhile((element) => element is SendPort).cast<SendPort>().take(1).first;
    communicatorSendPort.send(rootIsolateToken);
    return Responder(rp, broadcastRp, communicatorSendPort);
  }

  Future<List<Barcode>> getProcessedImages(InputImage inputImage) async {
    communicatorSendPort.send(inputImage);
    final x = broadcastRp.takeWhile((element) => element is List<Barcode>).cast<List<Barcode>>().take(1).first;
    return x;
  }
}

Future<void> _imageProcessCommunicator(SendPort sp) async {
  final rp = ReceivePort();
  sp.send(rp.sendPort);
  BarcodeScanner? barcodeScanner;

  final messages = rp.takeWhile((element) => true).cast<dynamic>();

  await for (final message in messages) {
    if (message is RootIsolateToken) {
      BackgroundIsolateBinaryMessenger.ensureInitialized(message);
      barcodeScanner = BarcodeScanner();
      continue;
    }
    if (message is InputImage && barcodeScanner != null) {
      final recognizedBarCodes = await barcodeScanner.processImage(message);
      sp.send(recognizedBarCodes);
      continue;
    }
    continue;
  }
}
