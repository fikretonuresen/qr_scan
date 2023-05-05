import 'package:flutter/material.dart';
import 'package:qr_scan/qr_scan.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: QrScan(
        useBarcode: (String barcode) async {
          debugPrint("Barcode: $barcode");
          return "0";
        },
      ),
    );
  }
}
