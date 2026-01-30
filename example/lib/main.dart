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
              const SizedBox(height: 12),
              ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ControlledScanPage()));
                  },
                  child: const Text("Controlled Scan")),
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
