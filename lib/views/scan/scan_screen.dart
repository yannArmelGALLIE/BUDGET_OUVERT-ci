// lib/views/scan/scan_screen.dart
// ✅ QR Code retiré de l'AppBar des autres écrans → la page de scan est le
//    point d'entrée dédié (accessible via la barre de navigation principale)
// ✅ Analyse complète corrigée :
//    - Gestion des permissions caméra explicite
//    - Feedback visuel immédiat lors d'un scan réussi
//    - Redirection sécurisée avec gestion d'erreur
//    - Compatibilité des formats QR (URL, prefixe, UUID brut)
//    - Bouton torche et flip caméra fonctionnels
//    - Animation de cadre de scan
//    - UX guidée pour le citoyen

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../utils/app_constants.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: false,
  );

  bool _scanned = false;
  bool _torchOn = false;
  String? _feedbackMessage;
  bool _feedbackError = false;

  // Animation pour le cadre de scan
  late AnimationController _animController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scanAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_animController);
  }

  @override
  void dispose() {
    _controller.dispose();
    _animController.dispose();
    super.dispose();
  }

  /// ✅ Détection d'un QR code
  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    setState(() => _scanned = true);
    _controller.stop();
    _animController.stop();

    final value = barcode.rawValue!;
    _naviguerDepuisQR(value);
  }

  /// ✅ Parsing robuste du contenu QR
  /// Formats supportés :
  ///   https://budgetouvert.ci/transaction/{id}
  ///   https://budgetouvert.ci/commune/{id}
  ///   transaction:{id}
  ///   commune:{id}
  ///   {uuid brut} → suppose une transaction
  void _naviguerDepuisQR(String value) {
    String? route;
    String? type;

    final trimmed = value.trim();

    // Format URL complet
    if (trimmed.contains('/transaction/')) {
      final id = trimmed.split('/transaction/').last.split('?').first.trim();
      if (id.isNotEmpty) {
        route = '/transaction/$id';
        type = 'transaction';
      }
    } else if (trimmed.contains('/commune/')) {
      final id = trimmed.split('/commune/').last.split('?').first.trim();
      if (id.isNotEmpty) {
        route = '/commune/$id';
        type = 'commune';
      }
    }
    // Format préfixé
    else if (trimmed.startsWith('transaction:')) {
      final id = trimmed.substring(12).trim();
      if (id.isNotEmpty) {
        route = '/transaction/$id';
        type = 'transaction';
      }
    } else if (trimmed.startsWith('commune:')) {
      final id = trimmed.substring(8).trim();
      if (id.isNotEmpty) {
        route = '/commune/$id';
        type = 'commune';
      }
    }
    // UUID brut → assume transaction
    else if (_ressembleUUID(trimmed)) {
      route = '/transaction/$trimmed';
      type = 'transaction';
    }

    if (route != null && mounted) {
      // Feedback succès bref avant navigation
      setState(() {
        _feedbackMessage =
            '✓ ${type == 'commune' ? 'Commune' : 'Opération'} trouvée !';
        _feedbackError = false;
      });

      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) context.push(route!);
      });
    } else {
      // ✅ Feedback erreur lisible par le citoyen
      setState(() {
        _feedbackMessage =
            'Ce QR Code n\'est pas reconnu.\nVérifiez qu\'il provient d\'une transaction ou d\'une commune.';
        _feedbackError = true;
      });
    }
  }

  bool _ressembleUUID(String s) {
    // UUID format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
    // ou format court TX-xxx, COM-xxx
    return RegExp(
                r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
                caseSensitive: false)
            .hasMatch(s) ||
        RegExp(r'^(TX|COM|PROJ)-\w+$', caseSensitive: false).hasMatch(s);
  }

  void _relancer() {
    setState(() {
      _scanned = false;
      _feedbackMessage = null;
      _feedbackError = false;
    });
    _controller.start();
    _animController.repeat(reverse: true);
  }

  void _toggleTorch() {
    _controller.toggleTorch();
    setState(() => _torchOn = !_torchOn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: AppColors.white,
        elevation: 0,
        title: Text(
          'Scanner un QR Code',
          style: AppTextStyles.titleLarge.copyWith(color: AppColors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        actions: [
          // Torche
          IconButton(
            icon: Icon(
              _torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: _torchOn ? Colors.amber : Colors.white60,
            ),
            tooltip: 'Lampe torche',
            onPressed: _toggleTorch,
          ),
          // Flip caméra
          IconButton(
            icon: const Icon(Icons.flip_camera_ios_rounded,
                color: Colors.white60),
            tooltip: 'Changer de caméra',
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Caméra ───────────────────────────────────────────────────
          if (!_scanned)
            MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
              errorBuilder: (context, error) {
                return _PermissionRefusee(onRetry: _relancer);
              },
            )
          else
            Container(color: Colors.black),

          // ── Overlay assombri autour du cadre ─────────────────────────
          if (!_scanned) ...[
            // Zones sombres
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _OverlayPainter(),
                ),
              ),
            ),

            // ── Cadre animé de scan ───────────────────────────────────
            Center(
              child: AnimatedBuilder(
                animation: _scanAnimation,
                builder: (context, child) {
                  return Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.accent.withOpacity(0.9),
                        width: 2.5,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Stack(
                      children: [
                        // Coins du cadre
                        ..._buildCorners(),
                        // Ligne de scan animée
                        Positioned(
                          top: _scanAnimation.value * 220,
                          left: 10,
                          right: 10,
                          child: Container(
                            height: 2,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  AppColors.accent,
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],

          // ── Feedback succès (vert) ───────────────────────────────────
          if (_scanned && _feedbackMessage != null && !_feedbackError)
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E6B45),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: Colors.white, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      _feedbackMessage!,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Redirection en cours…',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),

          // ── Feedback erreur (rouge) ───────────────────────────────────
          if (_feedbackError && _feedbackMessage != null)
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.error, width: 1),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.qr_code_rounded,
                        color: AppColors.error, size: 40),
                    const SizedBox(height: 12),
                    Text(
                      _feedbackMessage!,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.9), fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _relancer,
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Scanner à nouveau'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Instruction en bas ────────────────────────────────────────
          if (!_scanned)
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  const Icon(Icons.qr_code_rounded,
                      color: Colors.white38, size: 20),
                  const SizedBox(height: 8),
                  const Text(
                    'Pointez le QR Code d\'une opération\nou d\'une commune',
                    style: TextStyle(color: Colors.white60, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildCorners() {
    const size = 20.0;
    const width = 3.0;
    final color = AppColors.accent;

    return [
      // Top-left
      Positioned(
          top: 0,
          left: 0,
          child: _Corner(
              color: color, size: size, width: width, top: true, left: true)),
      // Top-right
      Positioned(
          top: 0,
          right: 0,
          child: _Corner(
              color: color, size: size, width: width, top: true, left: false)),
      // Bottom-left
      Positioned(
          bottom: 0,
          left: 0,
          child: _Corner(
              color: color, size: size, width: width, top: false, left: true)),
      // Bottom-right
      Positioned(
          bottom: 0,
          right: 0,
          child: _Corner(
              color: color, size: size, width: width, top: false, left: false)),
    ];
  }
}

// Coins du cadre de scan
class _Corner extends StatelessWidget {
  final Color color;
  final double size;
  final double width;
  final bool top;
  final bool left;

  const _Corner({
    required this.color,
    required this.size,
    required this.width,
    required this.top,
    required this.left,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter:
            _CornerPainter(color: color, width: width, top: top, left: left),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final double width;
  final bool top;
  final bool left;

  _CornerPainter(
      {required this.color,
      required this.width,
      required this.top,
      required this.left});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    if (top && left) {
      path.moveTo(0, size.height);
      path.lineTo(0, 0);
      path.lineTo(size.width, 0);
    } else if (top && !left) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
    } else if (!top && left) {
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, size.height);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width, 0);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Overlay sombre autour du cadre
class _OverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.55);
    const frameSize = 240.0;
    final left = (size.width - frameSize) / 2;
    final top = (size.height - frameSize) / 2;

    // 4 rectangles sombres autour du cadre
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, top), paint);
    canvas.drawRect(
        Rect.fromLTWH(0, top + frameSize, size.width, size.height), paint);
    canvas.drawRect(Rect.fromLTWH(0, top, left, frameSize), paint);
    canvas.drawRect(
        Rect.fromLTWH(left + frameSize, top, size.width, frameSize), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Écran affiché si les permissions caméra sont refusées
class _PermissionRefusee extends StatelessWidget {
  final VoidCallback onRetry;
  const _PermissionRefusee({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt_outlined,
                color: Colors.white38, size: 56),
            const SizedBox(height: 20),
            const Text(
              'Accès à la caméra requis',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Pour scanner un QR Code, veuillez autoriser l\'accès à la caméra dans les paramètres de votre téléphone.',
              style: TextStyle(color: Colors.white54, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
