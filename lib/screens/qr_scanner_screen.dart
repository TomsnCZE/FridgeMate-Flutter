import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/api_service.dart';
import '../models/product.dart';
import 'product_detail_screen.dart';
import 'add_product_screen.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen>
    with SingleTickerProviderStateMixin {
  bool _isScanning = false;
  String? _lastScannedCode;
  bool _isTorchOn = false;

  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  late final AnimationController _scanLineController;

  @override
  void initState() {
    super.initState();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _startScan() {
    setState(() {
      _isScanning = true;
      _lastScannedCode = null;
    });
  }

  void _stopScan() {
    setState(() {
      _isScanning = false;
    });
  }

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
      final action = await showDialog<String>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) {
          final theme = Theme.of(ctx);
          final cs = theme.colorScheme;

          return AlertDialog(
            backgroundColor: cs.surface,
            surfaceTintColor: cs.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: Text(
              'Produkt nebyl nalezen',
              style: theme.textTheme.titleLarge?.copyWith(color: cs.onSurface),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kód: $code',
                  style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurface),
                ),
                const SizedBox(height: 12),
                Text(
                  'Chceš skenovat znovu, nebo přidat produkt ručně?',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withOpacity(0.8),
                  ),
                ),
              ],
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            actions: [
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, 'rescan'),
                  child: const Text('Skenovat znovu'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, 'manual'),
                  child: const Text('Přidat ručně'),
                ),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      if (action == 'manual') {
        final insertedManual = await Navigator.push<Product?>(
          context,
          MaterialPageRoute(builder: (_) => const AddProductScreen()),
        );

        if (!mounted) return;

        if (insertedManual != null) {
          Navigator.pop(context, insertedManual);
          return;
        }

        _stopScan();
        return;
      }

      if (action == 'rescan') {
        _startScan();
      } else {
        _stopScan();
      }

      return;
    }

    final inserted = await Navigator.push<Product?>(
      context,
      MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
    );

    if (!mounted) return;

    if (inserted != null) {
      Navigator.pop(context, inserted);
    } else {
      _stopScan();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    const double cutOutSize = 260;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Skenovat čárový kód'),
        actions: [
          IconButton(
            tooltip: 'Blesk',
            onPressed: () async {
              await _controller.toggleTorch();
              if (mounted) setState(() => _isTorchOn = !_isTorchOn);
            },
            icon: Icon(_isTorchOn ? Icons.flash_on : Icons.flash_off),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) async {
              if (!_isScanning) return;
              final barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final code = barcodes.first.rawValue ?? '';
                if (code.isNotEmpty) {
                  await _handleBarcode(code);
                }
              }
            },
          ),

          // Overlay se "zatemněním" + výřezem (jen zaoblený čtverec, bez rohů)
          CustomPaint(
            painter: _ScannerOverlayPainter(
              overlayColor: Colors.black.withOpacity(0.55),
              borderColor: cs.primary,
              cutOutSize: cutOutSize,
              borderRadius: 18,
              borderWidth: 3,
            ),
          ),

          // Scan-line (indikace běžícího skenování)
          IgnorePointer(
            child: Center(
              child: SizedBox(
                width: cutOutSize,
                height: cutOutSize,
                child: AnimatedBuilder(
                  animation: _scanLineController,
                  builder: (_, __) {
                    final y = _scanLineController.value * (cutOutSize - 6);
                    return Stack(
                      children: [
                        Positioned(
                          left: 8,
                          right: 8,
                          top: y,
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: cs.primary.withOpacity(
                                _isScanning ? 0.75 : 0.0,
                              ),
                              boxShadow: _isScanning
                                  ? [
                                      BoxShadow(
                                        blurRadius: 12,
                                        spreadRadius: 2,
                                        color: cs.primary.withOpacity(0.25),
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),

          // Horní info karta
          Positioned(
            left: 16,
            right: 16,
            top: 16,
            child: SafeArea(
              bottom: false,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: cs.surface.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.qr_code_scanner, color: cs.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Namiř kameru na čárový kód.\nSkenování spustíš tlačítkem níže.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurface,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Chip se stavem
          Positioned(
            left: 16,
            right: 16,
            top: MediaQuery.of(context).size.height / 2 + (cutOutSize / 2) + 18,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: cs.surface.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
                ),
                child: Text(
                  _lastScannedCode == null
                      ? (_isScanning
                          ? 'Skenování běží…'
                          : 'Stiskni „Spustit skenování“')
                      : 'Poslední kód: $_lastScannedCode',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: cs.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),

          // Spodní panel: jen Start/Stop
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: cs.surface.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: _isScanning
                      ? OutlinedButton.icon(
                          onPressed: _stopScan,
                          icon: const Icon(Icons.pause),
                          label: const Text('Zastavit skenování'),
                        )
                      : ElevatedButton.icon(
                          onPressed: _startScan,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Spustit skenování'),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  final Color overlayColor;
  final Color borderColor;
  final double cutOutSize;
  final double borderRadius;
  final double borderWidth;

  _ScannerOverlayPainter({
    required this.overlayColor,
    required this.borderColor,
    required this.cutOutSize,
    required this.borderRadius,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = overlayColor;

    final cutOutRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: cutOutSize,
      height: cutOutSize,
    );

    final cutOutRRect = RRect.fromRectAndRadius(
      cutOutRect,
      Radius.circular(borderRadius),
    );

    // overlay s dírou
    final overlayPath = Path()..addRect(Offset.zero & size);
    final cutOutPath = Path()..addRRect(cutOutRRect);
    final finalPath =
        Path.combine(PathOperation.difference, overlayPath, cutOutPath);
    canvas.drawPath(finalPath, paint);

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..color = borderColor;
    canvas.drawRRect(cutOutRRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) {
    return overlayColor != oldDelegate.overlayColor ||
        borderColor != oldDelegate.borderColor ||
        cutOutSize != oldDelegate.cutOutSize ||
        borderRadius != oldDelegate.borderRadius ||
        borderWidth != oldDelegate.borderWidth;
  }
}