import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/api_service.dart';
import '../models/product.dart';
import 'product_detail_screen.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool _isScanning = true;
  String? _lastScannedCode;

  Future<void> _handleBarcode(String code) async {
    if (!_isScanning) return;
    
    setState(() {
      _isScanning = false;
      _lastScannedCode = code;
    });

    final api = ApiService();
    final product = await api.fetchProductByBarcode(code);

    if (!mounted) return;

    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produkt nebyl nalezen')),
      );
      setState(() => _isScanning = true);
      return;
    }

    // ✅ Zobrazíme detail produktu
    final addedProduct = await Navigator.push<Product>(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(product: product, index: -1),
      ),
    );

    if (!mounted) return;

    // ✅ VRÁTÍME PRODUKT ZPĚT DO INVENTORY SCREEN
    if (addedProduct != null) {
      Navigator.pop(context, addedProduct);
    } else {
      setState(() => _isScanning = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Skenovat QR kód'),
        backgroundColor: const Color(0xFFEC9B05),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: MobileScannerController(
              detectionSpeed: DetectionSpeed.normal,
              facing: CameraFacing.back,
            ),
            onDetect: (capture) async {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String code = barcodes.first.rawValue ?? '';
                if (code.isNotEmpty) {
                  await _handleBarcode(code);
                }
              }
            },
          ),

          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.orange, width: 3),
                borderRadius: BorderRadius.circular(12),
                color: Colors.transparent,
              ),
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode 
                    ? Colors.grey[900]!.withOpacity(0.9)
                    : Colors.white.withOpacity(0.9),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_lastScannedCode != null)
                    Text(
                      'Poslední kód: $_lastScannedCode',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _isScanning = true;
                            _lastScannedCode = null;
                          });
                        },
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Skenovat znovu'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Zpět'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}