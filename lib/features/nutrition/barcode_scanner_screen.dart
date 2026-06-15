import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/theme/app_colors.dart';

/// Full-screen barcode scanner. Returns the first decoded barcode string.
class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
    ],
  );
  bool _handled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan barcode'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_handled) return;
              final code = capture.barcodes.firstOrNull?.rawValue;
              if (code != null && code.isNotEmpty) {
                _handled = true;
                Navigator.pop(context, code);
              }
            },
          ),
          // Reticle overlay.
          Container(
            width: 260,
            height: 160,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary, width: 3),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const Positioned(
            bottom: 60,
            child: Text(
              'Align the barcode within the frame',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                backgroundColor: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
