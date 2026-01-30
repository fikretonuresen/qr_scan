import "dart:async";

import "package:camerawesome/camerawesome_plugin.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart";
import "package:just_audio/just_audio.dart";
import 'package:qr_scan/src/enums.dart';
import 'package:qr_scan/src/isolate.dart';
import 'package:qr_scan/src/controller.dart';
import 'package:qr_scan/src/models.dart';
import "package:qr_scan/src/mlkit_utils.dart";

// Public exports so users only need: import 'package:qr_scan/qr_scan.dart';
export 'package:qr_scan/src/enums.dart';
export 'package:qr_scan/src/controller.dart';
export 'package:qr_scan/src/models.dart' show ScannedBarcode;
export 'package:qr_scan/src/scan_image.dart';
export 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart'
    show BarcodeFormat, BarcodeType, InputImage;

/// A camera-based barcode and QR code scanner widget.
///
/// Combines CamerAwesome for the camera preview with Google ML Kit for
/// barcode detection. Provides built-in audio feedback, duplicate scan
/// prevention, and flash/aspect-ratio/camera-switch controls.
///
/// ```dart
/// QrScan(
///   useBarcode: (ScannedBarcode barcode) async {
///     print('Scanned: ${barcode.rawValue}');
///     return ScanSoundResult.success;
///   },
/// )
/// ```
class QrScan extends StatefulWidget {
  const QrScan({
    super.key,
    required this.useBarcode,
    this.selectedCameraAspectRatio = 0,
    this.multiBarcodeTitle = "Multiple Barcodes Found",
    this.multiBarcodeMessage = "Select the barcode you want to use.",
    this.enableAudio = true,
    this.debounceDuration = const Duration(milliseconds: 2000),
    this.barcodeFormats = const [BarcodeFormat.all],
    this.controller,
    this.overlayBuilder,
    this.enableZoom = true,
  });

  /// Callback invoked when a barcode is detected.
  ///
  /// Receives a [ScannedBarcode] with raw value, display value, format, and
  /// type. Return a [ScanSoundResult] to trigger audio feedback, or `null`
  /// for no sound.
  final FutureOr<ScanSoundResult?> Function(ScannedBarcode barcode) useBarcode;

  /// Camera preview aspect ratio index: `0` for 16:9, `1` for 4:3.
  final int selectedCameraAspectRatio;

  /// Title shown in the multi-barcode selection dialog.
  final String multiBarcodeTitle;

  /// Message shown in the multi-barcode selection dialog.
  final String multiBarcodeMessage;

  /// Whether audio feedback is enabled. Defaults to `true`.
  final bool enableAudio;

  /// Duration to ignore duplicate scans of the same barcode.
  /// Defaults to 2 seconds.
  final Duration debounceDuration;

  /// Barcode formats to detect. Defaults to [BarcodeFormat.all].
  final List<BarcodeFormat> barcodeFormats;

  /// Optional controller to programmatically pause/resume scanning.
  final QrScanController? controller;

  /// Optional widget builder to overlay on top of the camera preview.
  ///
  /// The overlay is wrapped in [IgnorePointer] so it does not block
  /// touch events (pinch-to-zoom, tap-to-focus) on the camera.
  final Widget Function(BuildContext context)? overlayBuilder;

  /// Whether pinch-to-zoom is enabled on the camera preview.
  /// Defaults to `true`.
  final bool enableZoom;

  @override
  State<QrScan> createState() => _QrScanState();
}

class _QrScanState extends State<QrScan> {
  late int selectedCameraAspectRatio = widget.selectedCameraAspectRatio;
  bool _isProcessing = false;
  bool _isDisposing = false;
  final checkSet = <String?>{};
  Responder? responder;

  // Audio players — only initialized when enableAudio is true
  AudioPlayer? readSound;
  AudioPlayer? successSound;
  AudioPlayer? failSound;

  Future<void> _initAudio() async {
    readSound = AudioPlayer();
    await readSound!.setAsset("packages/qr_scan/assets/audio/read.wav");
    await readSound!.setVolume(0);

    successSound = AudioPlayer();
    await successSound!.setAsset("packages/qr_scan/assets/audio/success.wav");
    await successSound!.setVolume(0);

    failSound = AudioPlayer();
    await failSound!.setAsset("packages/qr_scan/assets/audio/fail.wav");
    await failSound!.setVolume(0);
  }

  Future<void> initResponder() async {
    responder = await Responder.createImageProcessor(
      formats: widget.barcodeFormats,
    );
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    if (widget.enableAudio) {
      unawaited(_initAudio().catchError(
        (e) => debugPrint('QrScan: audio init failed: $e'),
      ));
    }
    unawaited(initResponder());
  }

  @override
  void didUpdateWidget(QrScan oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.barcodeFormats != oldWidget.barcodeFormats) {
      responder?.dispose();
      responder = null;
      unawaited(initResponder());
    }
  }

  Future<void> disposeResponder() async {
    _isDisposing = true;
    responder?.dispose();
    await readSound?.dispose();
    await successSound?.dispose();
    await failSound?.dispose();
  }

  @override
  void dispose() {
    disposeResponder();
    super.dispose();
  }

  Future<void> playSound([ScanSoundResult? value]) async {
    if (!mounted || !widget.enableAudio) return;
    switch (value) {
      case ScanSoundResult.fail:
        await failSound?.setVolume(1);
        await failSound?.load();
        await failSound?.play();
      case ScanSoundResult.success:
        await successSound?.setVolume(1);
        await successSound?.load();
        await successSound?.play();
      case ScanSoundResult.read:
        await readSound?.setVolume(1);
        await readSound?.load();
        await readSound?.play();
      case ScanSoundResult.none:
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        return Material(
          child: responder == null
              ? const Center(child: CircularProgressIndicator())
              : SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxWidth *
                      (selectedCameraAspectRatio == 0 ? 16 / 9 : 4 / 3),
                  child: Stack(
                    children: [
                      CameraAwesomeBuilder.awesome(
                        imageAnalysisConfig:
                            AnalysisConfig(maxFramesPerSecond: 15),
                        onImageForAnalysis: _processImageBarcode,
                        saveConfig: SaveConfig.photo(),
                        sensorConfig: SensorConfig.single(
                          sensor: Sensor.position(SensorPosition.back),
                          flashMode: FlashMode.none,
                          aspectRatio: CameraAspectRatios
                              .values[selectedCameraAspectRatio],
                          zoom: 0.0,
                        ),
                        previewFit: CameraPreviewFit.cover,
                        onPreviewScaleBuilder: widget.enableZoom
                            ? null
                            : (_) => OnPreviewScale(onScale: (_) {}),
                        middleContentBuilder: (state) =>
                            const SizedBox.shrink(),
                        topActionsBuilder: (state) => const SizedBox.shrink(),
                        bottomActionsBuilder: (state) => AwesomeTopActions(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 10),
                          state: state,
                          children: [
                            AwesomeFlashButton(
                              state: state,
                              iconBuilder: (flashMode) {
                                final icon = flashMode == FlashMode.always
                                    ? Icons.flash_on
                                    : Icons.flash_off;
                                return AwesomeCircleWidget.icon(icon: icon);
                              },
                              onFlashTap: (sensorConfig, flashMode) async {
                                final newFlashMode =
                                    flashMode != FlashMode.always
                                        ? FlashMode.always
                                        : FlashMode.none;
                                await sensorConfig.setFlashMode(newFlashMode);
                              },
                            ),
                            if (state is PhotoCameraState)
                              AwesomeAspectRatioButton(
                                state: state,
                                onAspectRatioTap:
                                    (sensorConfig, cameraAspectRatios) async {
                                  final newCameraAspectRatios =
                                      cameraAspectRatios !=
                                              CameraAspectRatios.ratio_16_9
                                          ? CameraAspectRatios.ratio_16_9
                                          : CameraAspectRatios.ratio_4_3;
                                  setState(() => selectedCameraAspectRatio =
                                      newCameraAspectRatios.index);
                                  await sensorConfig
                                      .setAspectRatio(newCameraAspectRatios);
                                },
                              ),
                            AwesomeCameraSwitchButton(
                              state: state,
                              scale: 1,
                              onSwitchTap: (state) async =>
                                  await state.switchCameraSensor(
                                      aspectRatio:
                                          state.sensorConfig.aspectRatio),
                            ),
                          ],
                        ),
                      ),
                      if (widget.overlayBuilder != null)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: widget.overlayBuilder!(context),
                          ),
                        ),
                    ],
                  ),
                ),
        );
      });

  Future<void> _processImageBarcode(AnalysisImage img) async {
    if (_isProcessing) return;
    if (widget.controller?.isScanning == false) return;
    _isProcessing = true;
    final inputImage = img.toInputImage();
    try {
      final recognizedBarCodes =
          await responder?.getProcessedImages(inputImage);
      if (_isDisposing) return;
      if (recognizedBarCodes == null) return;
      final processedBarcodes = processBarcodes(recognizedBarCodes);
      if (processedBarcodes.isNotEmpty) {
        await playSound(ScanSoundResult.read);
        await webService(processedBarcodes);
      }
    } catch (e) {
      debugPrint('Barcode processing error: $e');
    } finally {
      _isProcessing = false;
    }
  }

  List<ScannedBarcode> processBarcodes(List<ScannedBarcode> barcodes) {
    final returnList = <ScannedBarcode>[];
    for (final barcode in barcodes) {
      final dedupeKey = barcode.rawValue ?? barcode.displayValue;
      if (!checkSet.contains(dedupeKey)) {
        returnList.add(barcode);
        checkSet.add(dedupeKey);
        Future<void>.delayed(
            widget.debounceDuration, () => checkSet.remove(dedupeKey));
      }
    }
    return returnList;
  }

  Future<void> webService(List<ScannedBarcode> barcodes) async {
    if (!mounted) return;
    if (_isDisposing) return;
    if (barcodes.length == 1) {
      final response = await widget.useBarcode(barcodes.first);
      await playSound(response);
    } else if (barcodes.length > 1) {
      await showCupertinoModalPopup<void>(
        context: context,
        builder: (context) => CupertinoActionSheet(
          title: Text(widget.multiBarcodeTitle),
          message: Text(widget.multiBarcodeMessage),
          actions: [
            for (final element in barcodes)
              CupertinoActionSheetAction(
                onPressed: () async {
                  Navigator.pop(context);
                  final response = await widget.useBarcode(element);
                  if (mounted) await playSound(response);
                },
                child: Text(element.rawValue ?? ""),
              ),
          ],
        ),
      );
    }
  }
}
