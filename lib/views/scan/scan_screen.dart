// lib/views/scan/scan_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../utils/app_constants.dart';
import '../../widgets/shared_widgets.dart';
import '../../models/signal_model.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {

  // ── Contrôleur mobile_scanner ──────────────────────────────────────────
  late final MobileScannerController _cameraController;

  // ── Animation ligne de scan ────────────────────────────────────────────
  late AnimationController _lineAnimController;
  late Animation<double> _lineAnim;

  // ── État ──────────────────────────────────────────────────────────────
  bool _isProcessing   = false;
  bool _torchEnabled   = false;
  bool _hasPermission  = false;
  bool _permissionChecked = false;
  String? _errorMessage;

  final List<ScanHistoryModel> _history = ScanHistoryModel.samples();

  // ── Mapping QR → projectId ─────────────────────────────────────────────
  // Le QR collé sur chaque chantier contient l'une de ces valeurs.
  // Format recommandé : "BUDGETOUVERT:<id>"
  static const Map<String, String> _qrToProjectId = {
    'BUDGETOUVERT:proj001': 'proj001',
    'BUDGETOUVERT:proj002': 'proj002',
    'BUDGETOUVERT:proj003': 'proj003',
    'BUDGETOUVERT:proj004': 'proj004',
    // Fallback : ID seul (pour les QR legacy)
    'proj001': 'proj001',
    'proj002': 'proj002',
    'proj003': 'proj003',
    'proj004': 'proj004',
  };

  static const Map<String, String> _projectTitles = {
    'proj001': 'Construction Centre Santé',
    'proj002': 'Réhabilitation Lycée Classique',
    'proj003': 'Voirie Riviera',
    'proj004': 'Espaces Verts',
  };

  // ── Lifecycle ─────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    _lineAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _lineAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _lineAnimController, curve: Curves.easeInOut),
    );

    _startCamera();
  }

  Future<void> _startCamera() async {
    try {
      await _cameraController.start();
      if (mounted) setState(() { _hasPermission = true; _permissionChecked = true; });
    } catch (e) {
      if (mounted) setState(() {
        _hasPermission = false;
        _permissionChecked = true;
        _errorMessage = 'Accès caméra refusé.\nVérifiez les permissions dans Paramètres.';
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_hasPermission) return;
    if (state == AppLifecycleState.resumed) {
      _cameraController.start();
    } else if (state == AppLifecycleState.paused ||
               state == AppLifecycleState.inactive) {
      _cameraController.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController.dispose();
    _lineAnimController.dispose();
    super.dispose();
  }

  // ── Logique QR ────────────────────────────────────────────────────────
  void _onQrDetected(BarcodeCapture capture) {
    if (_isProcessing || capture.barcodes.isEmpty) return;
    final rawValue = capture.barcodes.first.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    setState(() => _isProcessing = true);
    _cameraController.stop();

    final projectId = _qrToProjectId[rawValue.trim()];
    if (projectId != null) {
      _handleValidQr(projectId);
    } else {
      _handleInvalidQr(rawValue);
    }
  }

  void _handleValidQr(String projectId) {
    _addToHistory(projectId);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) context.go('/projet/$projectId');
    });
  }

  void _handleInvalidQr(String rawValue) {
    setState(() => _isProcessing = false);
    _cameraController.start();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.white, size: 18),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'QR non reconnu. Scannez un code officiel BudgetOuvert.',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 13,
                  color: AppColors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _addToHistory(String projectId) {
    setState(() {
      _history.insert(0, ScanHistoryModel(
        id: 'scan_${DateTime.now().millisecondsSinceEpoch}',
        projetTitre: _projectTitles[projectId] ?? 'Projet $projectId',
        localisation: 'Abidjan, Adjamé',
        date: '• Maintenant',
      ));
    });
  }

  Future<void> _toggleTorch() async {
    await _cameraController.toggleTorch();
    setState(() => _torchEnabled = !_torchEnabled);
  }

  // ── BUILD ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(flex: 3, child: _buildCameraZone()),
          Expanded(flex: 2, child: _buildHistoryPanel()),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primaryDark,
      elevation: 0,
      title: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: const BoxDecoration(color: Colors.white10, shape: BoxShape.circle),
            child: const Icon(Icons.location_on, size: 14, color: AppColors.white),
          ),
          const SizedBox(width: 8),
          Text("Commune d'Adjamé",
            style: AppTextStyles.titleLarge.copyWith(color: AppColors.white, fontSize: 14)),
        ],
      ),
      actions: [
        if (_hasPermission)
          IconButton(
            onPressed: _toggleTorch,
            tooltip: _torchEnabled ? 'Éteindre la lampe' : 'Allumer la lampe',
            icon: Icon(
              _torchEnabled ? Icons.flashlight_on : Icons.flashlight_off,
              color: _torchEnabled ? AppColors.accent : Colors.white54,
              size: 22,
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(AppDimens.radiusFull),
            ),
            child: const Center(
              child: Text('K', style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.white,
              )),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCameraZone() {
    if (!_permissionChecked) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    }
    if (!_hasPermission) return _buildPermissionError();

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final frameW = w * 0.68;
        final frameH = h * 0.58;
        final frameLeft = (w - frameW) / 2;
        final frameTop  = (h - frameH) / 2 - 10;

        return Stack(
          children: [
            // ── Flux caméra réel ──────────────────────────────────────
            Positioned.fill(
              child: MobileScanner(
                controller: _cameraController,
                onDetect: _isProcessing ? null : _onQrDetected,
              ),
            ),

            // ── Overlay sombre (4 bandes autour du cadre) ─────────────
            ..._buildDarkBands(w, h, frameLeft, frameTop, frameW, frameH),

            // ── Cadre avec coins colorés ──────────────────────────────
            Positioned(
              left: frameLeft, top: frameTop,
              width: frameW,   height: frameH,
              child: CustomPaint(painter: _CornerPainter()),
            ),

            // ── Ligne de scan animée ──────────────────────────────────
            if (!_isProcessing)
              AnimatedBuilder(
                animation: _lineAnim,
                builder: (ctx, _) => Positioned(
                  left: frameLeft,
                  top: frameTop + _lineAnim.value * (frameH - 2),
                  child: Container(
                    width: frameW, height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        Colors.transparent,
                        AppColors.accent.withOpacity(0.9),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                ),
              ),

            // ── Overlay de traitement ─────────────────────────────────
            if (_isProcessing) _buildProcessingOverlay(),

            // ── Badge instruction ─────────────────────────────────────
            if (!_isProcessing)
              Positioned(
                bottom: 20, left: 0, right: 0,
                child: Center(child: _buildInstructionBadge()),
              ),
          ],
        );
      },
    );
  }

  List<Widget> _buildDarkBands(double w, double h,
      double fl, double ft, double fw, double fh) {
    const color = Colors.black54;
    return [
      Positioned(top: 0, left: 0, right: 0, height: ft,
          child: ColoredBox(color: color)),
      Positioned(top: ft + fh, left: 0, right: 0, bottom: 0,
          child: ColoredBox(color: color)),
      Positioned(top: ft, left: 0, width: fl, height: fh,
          child: ColoredBox(color: color)),
      Positioned(top: ft, right: 0, width: fl, height: fh,
          child: ColoredBox(color: color)),
    ];
  }

  Widget _buildProcessingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppDimens.radiusL),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 36, height: 36,
                  child: CircularProgressIndicator(
                      color: AppColors.accent, strokeWidth: 3),
                ),
                const SizedBox(height: 14),
                Text('QR détecté !',
                  style: AppTextStyles.titleLarge.copyWith(color: AppColors.white)),
                const SizedBox(height: 4),
                Text('Chargement du projet...',
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.88),
        borderRadius: BorderRadius.circular(AppDimens.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.qr_code_scanner, size: 16, color: AppColors.accent),
          const SizedBox(width: 8),
          Text('Pointez vers le QR du chantier',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white)),
        ],
      ),
    );
  }

  Widget _buildPermissionError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.no_photography_outlined,
                  size: 36, color: AppColors.error),
            ),
            const SizedBox(height: 20),
            Text('Caméra inaccessible',
              style: AppTextStyles.headlineMedium.copyWith(color: AppColors.white),
              textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text(
              _errorMessage ?? 'Autorisez l\'accès à la caméra dans les paramètres.',
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            PrimaryButton(label: 'Réessayer', onPressed: _startCamera, width: 160),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryPanel() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 2),
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: SectionHeader(
              title: 'Historique des Scans',
              actionLabel: 'Voir tout',
              onAction: () {},
            ),
          ),
          Expanded(
            child: _history.isEmpty
                ? Center(
                    child: Text('Aucun scan récent', style: AppTextStyles.bodyMedium),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _history.length,
                    itemBuilder: (context, i) => _ScanHistoryTile(
                      scan: _history[i],
                      onTap: () => context.go('/projet/proj001'),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── CADRE DE SCAN ────────────────────────────────────────────────────────
class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Contour léger
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(10),
      ),
      Paint()
        ..color = AppColors.white.withOpacity(0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Coins orange
    final p = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const len = 28.0;
    const r   = 10.0;

    void tl() {
      canvas.drawLine(Offset(0, len), Offset(0, r), p);
      canvas.drawArc(const Rect.fromLTWH(0, 0, r * 2, r * 2), 3.14159, -1.5708, false, p);
      canvas.drawLine(Offset(r, 0), const Offset(len, 0), p);
    }
    void tr() {
      canvas.drawLine(Offset(size.width, len), Offset(size.width, r), p);
      canvas.drawArc(Rect.fromLTWH(size.width - r * 2, 0, r * 2, r * 2), 0, -1.5708, false, p);
      canvas.drawLine(Offset(size.width - len, 0), Offset(size.width - r, 0), p);
    }
    void bl() {
      canvas.drawLine(Offset(0, size.height - len), Offset(0, size.height - r), p);
      canvas.drawArc(Rect.fromLTWH(0, size.height - r * 2, r * 2, r * 2), 3.14159, 1.5708, false, p);
      canvas.drawLine(Offset(r, size.height), Offset(len, size.height), p);
    }
    void br() {
      canvas.drawLine(Offset(size.width, size.height - len), Offset(size.width, size.height - r), p);
      canvas.drawArc(Rect.fromLTWH(size.width - r * 2, size.height - r * 2, r * 2, r * 2), 0, 1.5708, false, p);
      canvas.drawLine(Offset(size.width - len, size.height), Offset(size.width - r, size.height), p);
    }

    tl(); tr(); bl(); br();
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─── HISTORIQUE TILE ──────────────────────────────────────────────────────
class _ScanHistoryTile extends StatelessWidget {
  final ScanHistoryModel scan;
  final VoidCallback? onTap;
  const _ScanHistoryTile({required this.scan, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.qr_code, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(scan.projetTitre,
                    style: AppTextStyles.titleLarge.copyWith(fontSize: 13)),
                  Text('${scan.localisation} ${scan.date}',
                    style: AppTextStyles.caption),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}