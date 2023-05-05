import "dart:async";

import "package:camerawesome/camerawesome_plugin.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart";
import "package:just_audio/just_audio.dart";
import 'package:qr_scan/isolate.dart';
import "package:qr_scan/mlkit_utils.dart";

class QrScan extends StatefulWidget {
  const QrScan({super.key, required this.useBarcode});

  final FutureOr<String?> Function(String barcode) useBarcode;

  @override
  State<QrScan> createState() => _QrScanState();
}

class _QrScanState extends State<QrScan> {
  bool _isProcessing = false;
  final checkSet = <String?>{};
  Responder? responder;

  AudioPlayer readSound = AudioPlayer();
  AudioPlayer successSound = AudioPlayer();
  AudioPlayer failSound = AudioPlayer();

  Future<void> initResponder() async {
    responder = await Responder.createImageProcessor();
    await readSound.setAsset("packages/qr_scan/assets/audio/read.wav", initialPosition: const Duration(milliseconds: 1));
    await successSound.setAsset("packages/qr_scan/assets/audio/success.wav", initialPosition: const Duration(milliseconds: 1));
    await failSound.setAsset("packages/qr_scan/assets/audio/fail.wav", initialPosition: const Duration(milliseconds: 1));
    setState(() {});
  }

  @override
  void initState() {
    unawaited(initResponder());
    super.initState();
  }

  Future<void> disposeResponder() async {
    await readSound.dispose();
    await successSound.dispose();
    await failSound.dispose();
  }

  @override
  void dispose() {
    disposeResponder();
    super.dispose();
  }

  Future<void> playSound([String? value = ""]) async {
    switch (value) {
      case "-1":
        // await failSound.setAsset("packages/qr_scan/assets/audio/fail.wav", initialPosition: const Duration(milliseconds: 1));
        await failSound.load();
        await failSound.play();
        break;
      case "0":
        // await successSound.setAsset("packages/qr_scan/assets/audio/success.wav", initialPosition: const Duration(milliseconds: 1));
        await successSound.load();
        await successSound.play();
        break;
      case "1":
        // await readSound.setAsset("packages/qr_scan/assets/audio/read.wav", initialPosition: const Duration(milliseconds: 1));
        await readSound.load();
        await readSound.play();
        break;
    }
  }

  @override
  Widget build(BuildContext context) => Material(
        child: responder == null
            ? const Center(child: CircularProgressIndicator())
            : CameraAwesomeBuilder.awesome(
                imageAnalysisConfig: AnalysisConfig(maxFramesPerSecond: 5),
                onImageForAnalysis: _processImageBarcode,
                bottomActionsBuilder: (state) => const SizedBox.shrink(),
                middleContentBuilder: (state) => const SizedBox.shrink(),
                saveConfig: SaveConfig.photo(pathBuilder: () => Future<String>.value("")),
                aspectRatio: CameraAspectRatios.ratio_16_9,
                previewFit: CameraPreviewFit.fitWidth,
                topActionsBuilder: (state) => AwesomeTopActions(
                  state: state,
                  children: [
                    AwesomeFlashButton(
                      state: state,
                      iconBuilder: (flashMode) {
                        final IconData icon;
                        if (flashMode == FlashMode.none) {
                          icon = Icons.flash_off;
                        } else {
                          icon = Icons.flash_on;
                        }
                        return AwesomeCircleWidget.icon(icon: icon);
                      },
                      onFlashTap: (sensorConfig, flashMode) async {
                        final FlashMode newFlashMode;
                        if (flashMode == FlashMode.none) {
                          newFlashMode = FlashMode.always;
                        } else {
                          newFlashMode = FlashMode.none;
                        }
                        await sensorConfig.setFlashMode(newFlashMode);
                      },
                    ),
                    if (state is PhotoCameraState) AwesomeAspectRatioButton(state: state),
                    AwesomeCameraSwitchButton(
                      state: state,
                      scale: 1,
                      onSwitchTap: (state) async {
                        await state.switchCameraSensor(aspectRatio: state.sensorConfig.aspectRatio);
                      },
                    ),
                    // if (state is PhotoCameraState) AwesomeLocationButton(state: state),
                  ],
                ),
              ),
      );

  Future<void> _processImageBarcode(AnalysisImage img) async {
    if (_isProcessing) return;
    _isProcessing = true;
    final inputImage = img.toInputImage();
    try {
      final recognizedBarCodes = await responder?.getProcessedImages(inputImage);
      if (recognizedBarCodes == null) return;
      final processedBarcodes = processBarcodes(recognizedBarCodes);
      if (processedBarcodes.isNotEmpty) {
        playSound("1");
        await webService(processedBarcodes);
      }
    } catch (e) {
      debugPrint(e.toString());
    }
    _isProcessing = false;
  }

  List<String?> processBarcodes(List<Barcode> barcodes) {
    final returnList = <String?>[];
    for (final barcode in barcodes) {
      if (!checkSet.contains(barcode.rawValue)) {
        returnList.add(barcode.rawValue);
        checkSet.add(barcode.rawValue);
        Future<void>.delayed(const Duration(milliseconds: 2000), () => checkSet.remove(barcode.rawValue));
      }
    }
    return returnList;
  }

  Future<void> webService(List<String?> barcodes) async {
    if (barcodes.length == 1) {
      final response = await widget.useBarcode(barcodes.first ?? "");
      playSound(response);
    } else if (barcodes.length > 1) {
      final List<Widget> actions = <Widget>[];
      for (final element in barcodes) {
        actions.add(
          CupertinoActionSheetAction(
            onPressed: () async {
              final response = await widget.useBarcode(element ?? "");
              playSound(response);
              if (!mounted) return;
              Navigator.pop(context);
            },
            child: Text(element ?? ""),
          ),
        );
      }
      await showCupertinoModalPopup<void>(
        context: context,
        builder: (context) => CupertinoActionSheet(
          title: const Text("Birden Fazla Barkod Bulundu!"),
          message: const Text("İşlem yapmak istediğiniz barkodu seçiniz."),
          actions: actions,
        ),
      );
    }
  }
}
