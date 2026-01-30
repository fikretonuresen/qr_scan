import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
              const SizedBox(height: 12),
              ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ControlledScanPage()));
                  },
                  child: const Text("Controlled Scan")),
              const SizedBox(height: 12),
              ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const GalleryScanPage()));
                  },
                  child: const Text("Scan from Gallery")),
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
  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) Navigator.pop(context, "");
        },
        child: QrScan(
          useBarcode: (ScannedBarcode barcode) async {
            debugPrint("One Time Scan Barcode: ${barcode.rawValue}");
            Navigator.pop(context, barcode.rawValue ?? "");
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

class ControlledScanPage extends StatefulWidget {
  const ControlledScanPage({super.key});

  @override
  State<ControlledScanPage> createState() => _ControlledScanPageState();
}

class _ControlledScanPageState extends State<ControlledScanPage> {
  final _controller = QrScanController();
  ScannedBarcode? _lastBarcode;

  @override
  void initState() {
    super.initState();
    _controller.pause();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Controlled Scan")),
      body: Stack(
        children: [
          Positioned.fill(
            child: QrScan(
              controller: _controller,
              overlayBuilder: (context) =>
                  _ScanOverlay(controller: _controller),
              useBarcode: (barcode) {
                setState(() => _lastBarcode = barcode);
                debugPrint("Controlled Scan: ${barcode.rawValue}");
                return ScanSoundResult.success;
              },
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: ListenableBuilder(
                listenable: _controller,
                builder: (context, _) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_lastBarcode != null)
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.qr_code),
                          title: Text(_lastBarcode!.rawValue ?? "",
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(_lastBarcode!.format.name),
                        ),
                      ),
                    if (_lastBarcode != null) const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonalIcon(
                        onPressed: () => _controller.toggle(),
                        icon: Icon(_controller.isScanning
                            ? Icons.stop
                            : Icons.qr_code_scanner),
                        label: Text(_controller.isScanning
                            ? "Stop Scanning"
                            : "Start Scanning"),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: GestureDetector(
                        onTapDown: (_) => _controller.resume(),
                        onTapUp: (_) => _controller.pause(),
                        onTapCancel: () => _controller.pause(),
                        child: FilledButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.touch_app),
                          label: const Text("Hold to Scan"),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GalleryScanPage extends StatefulWidget {
  const GalleryScanPage({super.key});

  @override
  State<GalleryScanPage> createState() => _GalleryScanPageState();
}

class _GalleryScanPageState extends State<GalleryScanPage> {
  List<ScannedBarcode>? _results;
  bool _scanning = false;
  String? _errorMessage;

  Future<void> _pickAndScan() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
    );
    if (picked == null) return;

    setState(() {
      _scanning = true;
      _errorMessage = null;
    });
    try {
      final inputImage = InputImage.fromFilePath(picked.path);
      final barcodes = await scanImageForBarcodes(inputImage);
      setState(() => _results = barcodes);
    } on TimeoutException {
      setState(() {
        _results = null;
        _errorMessage =
            "Processing timed out. Try a smaller or lower-resolution image.";
      });
    } catch (e) {
      debugPrint('Gallery scan error: $e');
      setState(() {
        _results = null;
        _errorMessage = "Failed to process image.";
      });
    } finally {
      setState(() => _scanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gallery Scan")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              onPressed: _scanning ? null : _pickAndScan,
              icon: const Icon(Icons.photo_library),
              label: const Text("Pick Image"),
            ),
            const SizedBox(height: 24),
            if (_scanning) const Center(child: CircularProgressIndicator()),
            if (_errorMessage != null)
              Text(_errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red)),
            if (_errorMessage == null && _results != null && _results!.isEmpty)
              const Text("No barcodes found in the image.",
                  textAlign: TextAlign.center),
            if (_results != null && _results!.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _results!.length,
                  itemBuilder: (context, index) {
                    final barcode = _results![index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.qr_code),
                        title: Text(barcode.rawValue ?? ""),
                        subtitle: Text(
                            "${barcode.format.name} \u2022 ${barcode.type.name}"),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ScanOverlay extends StatelessWidget {
  const _ScanOverlay({required this.controller});

  final QrScanController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final isScanning = controller.isScanning;
        final borderColor = isScanning ? Colors.green : Colors.white54;

        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor, width: 3),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isScanning ? "Scanning..." : "Point at barcode",
                style: TextStyle(
                  color: isScanning ? Colors.green : Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
