import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerView extends StatelessWidget {
  final Function(String code) onDetect;

  const QrScannerView({
    super.key,
    required this.onDetect,
  });

  @override
  Widget build(BuildContext context) {
    return MobileScanner(
      onDetect: (capture) {
        final List<Barcode> barcodes = capture.barcodes;

        if (barcodes.isNotEmpty) {
          final String code = barcodes.first.rawValue ?? '';

          if (code.isNotEmpty) {
            onDetect(code);
          }
        }
      },
    );
  }
}