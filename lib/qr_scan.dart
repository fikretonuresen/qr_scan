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

  AudioPlayer readSound = AudioPlayer()
    ..setVolume(0)
    ..setAsset("packages/qr_scan/assets/audio/read.wav")
    ..load()
    ..play();
  AudioPlayer successSound = AudioPlayer()
    ..setVolume(0)
    ..setAsset("packages/qr_scan/assets/audio/success.wav")
    ..load()
    ..play();
  AudioPlayer failSound = AudioPlayer()
    ..setVolume(0)
    ..setAsset("packages/qr_scan/assets/audio/fail.wav")
    ..load()
    ..play();

  Future<void> initResponder() async {
    responder = await Responder.createImageProcessor();
    // await readSound.setAsset("packages/qr_scan/assets/audio/read.wav");
    // await readSound.setVolume(0);
    // await readSound.load();
    // await readSound.play();
    // await successSound.setAsset("packages/qr_scan/assets/audio/success.wav");
    // await failSound.setAsset("packages/qr_scan/assets/audio/fail.wav");
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
        await failSound.setVolume(1);
        await failSound.load();
        await failSound.play();
      case "0":
        await successSound.setVolume(1);
        await successSound.load();
        await successSound.play();
      case "1":
        await readSound.setVolume(1);
        await readSound.load();
        await readSound.play();
    }
  }

  @override
  Widget build(BuildContext context) => Material(
        child: responder == null
            ? const Center(child: CircularProgressIndicator())
            : CameraAwesomeBuilder.awesome(
                imageAnalysisConfig: AnalysisConfig(maxFramesPerSecond: 5),
                onImageForAnalysis: _processImageBarcode,
                saveConfig: SaveConfig.photo(),
                sensorConfig: SensorConfig.single(
                  sensor: Sensor.position(SensorPosition.back),
                  flashMode: FlashMode.auto,
                  aspectRatio: CameraAspectRatios.ratio_16_9,
                ),
                previewFit: CameraPreviewFit.fitWidth,
                middleContentBuilder: (state) => const SizedBox.shrink(),
                topActionsBuilder: (state) => const SizedBox.shrink(),
                // bottomActionsBuilder: (state) => const SizedBox.shrink(),
                bottomActionsBuilder: (state) => AwesomeTopActions(
                  padding: const EdgeInsets.only(left: 30, right: 30, bottom: 20),
                  state: state,
                  children: [
                    AwesomeFlashButton(
                      state: state,
                      iconBuilder: (flashMode) {
                        final IconData icon;
                        if (flashMode == FlashMode.always) {
                          icon = Icons.flash_on;
                        } else {
                          icon = Icons.flash_off;
                        }
                        return AwesomeCircleWidget.icon(icon: icon);
                      },
                      onFlashTap: (sensorConfig, flashMode) async {
                        final FlashMode newFlashMode;
                        if (flashMode != FlashMode.always) {
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
