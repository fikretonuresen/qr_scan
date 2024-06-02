import "dart:async";

import "package:camerawesome/camerawesome_plugin.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart";
import "package:just_audio/just_audio.dart";
import 'package:qr_scan/isolate.dart';
import "package:qr_scan/mlkit_utils.dart";

class QrScan extends StatefulWidget {
  const QrScan({super.key, required this.useBarcode, this.selectedCameraAspectRatio = 0});

  final FutureOr<String?> Function(String barcode) useBarcode;
  final int selectedCameraAspectRatio;

  @override
  State<QrScan> createState() => _QrScanState();
}

class _QrScanState extends State<QrScan> {
  late int selectedCameraAspectRatio = widget.selectedCameraAspectRatio;
  bool _isProcessing = false;
  bool _isDisposing = false;
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
    setState(() {});
  }

  @override
  void initState() {
    unawaited(initResponder());
    super.initState();
  }

  Future<void> disposeResponder() async {
    if (!mounted) return;
    _isDisposing = true;
    responder?.dispose();
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
    if (!mounted) return;
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
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
        return Material(
          child: responder == null
              ? const Center(child: CircularProgressIndicator())
              : SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxWidth * (selectedCameraAspectRatio == 0 ? 16 / 9 : 4 / 3),
                  child: CameraAwesomeBuilder.awesome(
                    imageAnalysisConfig: AnalysisConfig(maxFramesPerSecond: 15),
                    onImageForAnalysis: _processImageBarcode,
                    saveConfig: SaveConfig.photo(),
                    sensorConfig: SensorConfig.single(
                      sensor: Sensor.position(SensorPosition.back),
                      flashMode: FlashMode.none,
                      aspectRatio: CameraAspectRatios.values[selectedCameraAspectRatio],
                      zoom: 0.0,
                    ),
                    previewFit: CameraPreviewFit.cover,
                    middleContentBuilder: (state) => const SizedBox.shrink(),
                    topActionsBuilder: (state) => const SizedBox.shrink(),
                    // bottomActionsBuilder: (state) => const SizedBox.shrink(),
                    bottomActionsBuilder: (state) => AwesomeTopActions(
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                      state: state,
                      children: [
                        AwesomeFlashButton(
                          state: state,
                          iconBuilder: (flashMode) {
                            final icon = flashMode == FlashMode.always ? Icons.flash_on : Icons.flash_off;
                            return AwesomeCircleWidget.icon(icon: icon);
                          },
                          onFlashTap: (sensorConfig, flashMode) async {
                            final newFlashMode = flashMode != FlashMode.always ? FlashMode.always : FlashMode.none;
                            await sensorConfig.setFlashMode(newFlashMode);
                          },
                        ),
                        if (state is PhotoCameraState)
                          AwesomeAspectRatioButton(
                            state: state,
                            onAspectRatioTap: (sensorConfig, cameraAspectRatios) async {
                              final newCameraAspectRatios = cameraAspectRatios != CameraAspectRatios.ratio_16_9 ? CameraAspectRatios.ratio_16_9 : CameraAspectRatios.ratio_4_3;
                              setState(() => selectedCameraAspectRatio = newCameraAspectRatios.index);
                              await sensorConfig.setAspectRatio(newCameraAspectRatios);
                            },
                          ),
                        AwesomeCameraSwitchButton(
                          state: state,
                          scale: 1,
                          onSwitchTap: (state) async => await state.switchCameraSensor(aspectRatio: state.sensorConfig.aspectRatio),
                        ),
                        // if (state is PhotoCameraState) AwesomeLocationButton(state: state),
                      ],
                    ),
                  ),
                ),
        );
      });

  Future<void> _processImageBarcode(AnalysisImage img) async {
    if (_isProcessing) return;
    _isProcessing = true;
    final inputImage = img.toInputImage();
    // try {
    final recognizedBarCodes = await responder?.getProcessedImages(inputImage);
    if (_isDisposing) return;
    if (recognizedBarCodes == null) return;
    final processedBarcodes = processBarcodes(recognizedBarCodes);
    if (processedBarcodes.isNotEmpty) {
      await playSound("1");
      await webService(processedBarcodes);
    }
    // } catch (e) {
    //   debugPrint(e.toString());
    // }
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
    if (!mounted) return;
    if (_isDisposing) return;
    if (barcodes.length == 1) {
      final response = await widget.useBarcode(barcodes.first ?? "");
      await playSound(response);
    } else if (barcodes.length > 1) {
      await showCupertinoModalPopup<void>(
        context: context,
        builder: (context) => CupertinoActionSheet(
          title: const Text("Birden Fazla Barkod Bulundu!"),
          message: const Text("İşlem yapmak istediğiniz barkodu seçiniz."),
          actions: [
            for (final element in barcodes)
              CupertinoActionSheetAction(
                onPressed: () async {
                  Navigator.pop(context);
                  final response = await widget.useBarcode(element ?? "");
                  if (mounted) await playSound(response);
                },
                child: Text(element ?? ""),
              ),
          ],
        ),
      );
    }
  }
}
