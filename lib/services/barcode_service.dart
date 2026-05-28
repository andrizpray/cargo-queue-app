import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeResult {
  final String value;
  final BarcodeFormat format;

  BarcodeResult({required this.value, required this.format});
}

class BarcodeService {
  MobileScannerController createController({
    CameraFacing facing = CameraFacing.back,
    bool torchEnabled = false,
  }) {
    return MobileScannerController(
      facing: facing,
      torchEnabled: torchEnabled,
    );
  }

  BarcodeResult? parseBarcode(BarcodeCapture capture) {
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return null;

    final barcode = barcodes.first;
    final value = barcode.rawValue;
    if (value == null || value.isEmpty) return null;

    return BarcodeResult(
      value: value,
      format: barcode.format,
    );
  }

  String? extractPlateNumber(String barcodeValue) {
    final trimmed = barcodeValue.trim().toUpperCase();
    // Basic plate number validation — adjust regex to match local format
    final plateRegex = RegExp(r'^[A-Z0-9\s\-]{2,15}$');
    return plateRegex.hasMatch(trimmed) ? trimmed : null;
  }
}
