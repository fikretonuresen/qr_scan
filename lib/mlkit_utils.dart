import "package:camerawesome/camerawesome_plugin.dart";
import "package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart";

extension MLKitUtils on AnalysisImage {
  InputImage toInputImage() {
    final planeData = when(nv21: (img) => img.planes, bgra8888: (img) => img.planes)
        ?.map(
          (plane) => InputImagePlaneMetadata(
            bytesPerRow: plane.bytesPerRow,
            height: height,
            width: width,
          ),
        )
        .toList();

    final inputImageData = InputImageData(
      size: size,
      imageRotation: inputImageRotation,
      inputImageFormat: inputImageFormat,
      planeData: planeData,
    );

    return when(
      nv21: (image) => InputImage.fromBytes(
        bytes: image.bytes,
        inputImageData: inputImageData,
      ),
      bgra8888: (image) {
        return InputImage.fromBytes(
          bytes: image.bytes,
          inputImageData: inputImageData,
        );
      },
    )!;
  }

  InputImageRotation get inputImageRotation => InputImageRotation.values.byName(rotation.name);

  InputImageFormat get inputImageFormat {
    switch (format) {
      case InputAnalysisImageFormat.bgra8888:
        return InputImageFormat.bgra8888;
      case InputAnalysisImageFormat.nv21:
        return InputImageFormat.nv21;
      default:
        return InputImageFormat.yuv420;
    }
  }
}
