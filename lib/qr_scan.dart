import "dart:async";

import "package:camerawesome/camerawesome_plugin.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart";
import 'package:qr_scan/isolate.dart';
import "package:qr_scan/mlkit_utils.dart";

class QrScan extends StatefulWidget {
  const QrScan({super.key, required this.useBarcode});

  final FutureOr<dynamic> Function(String barcode) useBarcode;

  @override
  State<QrScan> createState() => _QrScanState();
}

class _QrScanState extends State<QrScan> {
  bool _isProcessing = false;
  final checkSet = <String?>{};
  Responder? responder;

  Future<void> initResponder() async {
    responder = await Responder.createImageProcessor();
    setState(() {});
  }

  @override
  void initState() {
    unawaited(initResponder());
    super.initState();
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
      await webService(processedBarcodes);
      // setState(() {});
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
      await widget.useBarcode(barcodes.first ?? "");
    } else if (barcodes.length > 1) {
      final List<Widget> actions = <Widget>[];
      for (final element in barcodes) {
        actions.add(
          CupertinoActionSheetAction(
            onPressed: () {
              widget.useBarcode(element ?? "");
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
