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
  Widget build(BuildContext context) => const MaterialApp(home: MainPage());
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  String oneTimeScanResult = "";
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("One Time Scan Result : $oneTimeScanResult"),
              const SizedBox(height: 20),
              ElevatedButton(
                  onPressed: () async {
                    final result = await Navigator.push(
                        context,
                        MaterialPageRoute<String?>(
                            builder: (context) => const OneTimeScanPage()));
                    if (result == null) return;
                    setState(() => oneTimeScanResult = result);
                  },
                  child: const Text("One Time Scan")),
              const SizedBox(height: 12),
              ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute<String?>(
                            builder: (context) => const ContinuousScanPage()));
                  },
                  child: const Text("Continuous Scan")),
            ],
          ),
        ),
      );
}

class OneTimeScanPage extends StatefulWidget {
  const OneTimeScanPage({super.key});

  @override
  State<OneTimeScanPage> createState() => _OneTimeScanPageState();
}

class _OneTimeScanPageState extends State<OneTimeScanPage> {
  String _barcode = "";
  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        onPopInvoked: (didPop) {
          if (!didPop) Navigator.pop(context, _barcode);
        },
        child: QrScan(
          useBarcode: (ScannedBarcode barcode) async {
            _barcode = barcode.rawValue ?? "";
            debugPrint("One Time Scan Barcode: ${barcode.rawValue}");
            Navigator.pop(context);
            return ScanSoundResult.success;
          },
        ),
      );
}

class ContinuousScanPage extends StatelessWidget {
  const ContinuousScanPage({super.key});

  @override
  Widget build(BuildContext context) => QrScan(
        useBarcode: (ScannedBarcode barcode) async {
          debugPrint("Continuous Scan Barcode: ${barcode.rawValue}");
          return ScanSoundResult.success;
        },
      );
}
