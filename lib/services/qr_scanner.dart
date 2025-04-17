import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile_scanner/mobile_scanner.dart'; // Add this import

class QRScannerScreen extends StatefulWidget {
  final Function(String, String) onQRScanned;

  const QRScannerScreen({super.key, required this.onQRScanned});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isPermissionGranted = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkCameraPermission();
  }

  Future<void> _checkCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      setState(() {
        _isPermissionGranted = true;
      });
    } else {
      setState(() {
        _errorMessage = 'Camera permission denied. Please enable it in settings.';
      });
    }
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Scan QR Code')),
        body: Center(
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (!_isPermissionGranted) {
      return Scaffold(
        appBar: AppBar(title: const Text('Scan QR Code')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code')),
      body: Stack(
        children: [
          MobileScanner(
            // Updated to match mobile_scanner v6.0.7 API
            controller: cameraController,
            onDetect: (BarcodeCapture capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _processQR(barcode.rawValue!);
                }
              }
            },
          ),
          Center(
            child: CustomPaint(
              painter: ScannerFramePainter(),
              child: const SizedBox(
                width: 250,
                height: 250,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _processQR(String qrData) {
    try {
      final uri = Uri.parse(qrData);
      if (uri.scheme != 'otpauth' || uri.host != 'totp') {
        throw Exception('Invalid TOTP QR code');
      }
      final label = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'Unknown';
      final secret = uri.queryParameters['secret'] ?? '';
      if (secret.isEmpty) {
        throw Exception('No secret found in QR code');
      }
      widget.onQRScanned(label, secret);
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid QR Code: $e')),
      );
    }
  }
}

class ScannerFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    const cornerLength = 30.0;

    paint.color = Colors.blue;
    canvas.drawLine(const Offset(0, 0), const Offset(cornerLength, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, cornerLength), paint);

    paint.color = Colors.yellow;
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - cornerLength, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, cornerLength), paint);

    paint.color = Colors.green;
    canvas.drawLine(Offset(0, size.height), Offset(cornerLength, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - cornerLength), paint);

    paint.color = Colors.red;
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - cornerLength, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - cornerLength), paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}