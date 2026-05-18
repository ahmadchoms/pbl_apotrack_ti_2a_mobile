import 'package:flutter/material.dart';

import '../../../../shared/widgets/qr_scanner_overlay.dart';
import '../../../../shared/widgets/qr_scanner_view.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  bool _isScanCompleted = false;

  void _onQrDetected(String code) {
    if (_isScanCompleted) return;

    setState(() => _isScanCompleted = true);

    debugPrint('QR Result: $code');

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.pop(context, code);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          QrScannerView(
            onDetect: _onQrDetected,
          ),

          Positioned.fill(
            child: Container(
              decoration: ShapeDecoration(
                shape: QrScannerOverlayShape(
                  borderColor: const Color(0xFF1D70F5),
                  borderRadius: 24,
                  borderLength: 30,
                  borderWidth: 10,
                  cutOutSize: 260,
                ),
              ),
            ),
          ),

          Positioned(
            top: 60,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.2),
              child: IconButton(
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: const Text(
              'Arahkan kamera ke QR Undangan',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}