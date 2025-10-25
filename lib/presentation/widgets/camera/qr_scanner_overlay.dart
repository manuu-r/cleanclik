import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:cleanclik/core/theme/neon_colors.dart';
import 'package:cleanclik/core/theme/app_theme.dart';
import 'package:cleanclik/presentation/widgets/common/glassmorphism_container.dart';
import 'package:cleanclik/presentation/widgets/common/neon_icon_button.dart';

/// QR Scanner overlay that appears over the camera view
class QRScannerOverlay extends StatefulWidget {
  final Function(String) onQRScanned;
  final VoidCallback onClose;

  const QRScannerOverlay({
    super.key,
    required this.onQRScanned,
    required this.onClose,
  });

  @override
  State<QRScannerOverlay> createState() => _QRScannerOverlayState();
}

class _QRScannerOverlayState extends State<QRScannerOverlay>
    with SingleTickerProviderStateMixin {
  QRViewController? _qrController;
  bool _isScanning = true;
  bool _isInitializing = true;
  String? _errorMessage;
  bool _flashEnabled = false;
  late AnimationController _animationController;
  late Animation<double> _scanLineAnimation;
  final GlobalKey _qrKey = GlobalKey(debugLabel: 'QR');

  @override
  void initState() {
    super.initState();

    // Initialize animation for scan line
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _scanLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.repeat(reverse: true);

    // Set initializing to false since QRView handles initialization
    _isInitializing = false;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      _qrController = controller;
      _isInitializing = false;
    });

    controller.scannedDataStream.listen((scanData) {
      if (_isScanning && scanData.code != null) {
        _onQRScanned(scanData.code!);
      }
    });

    print('📱 [QR_SCANNER] QR scanner initialized successfully');
  }

  void _onQRScanned(String qrData) {
    if (!_isScanning) return;

    print('✅ [QR_SCANNER] QR code detected: ${qrData.length} characters');

    // Provide haptic feedback
    HapticFeedback.mediumImpact();

    // Stop scanning to prevent duplicates
    setState(() {
      _isScanning = false;
    });

    // Call the callback with the scanned data
    widget.onQRScanned(qrData);
  }

  void _toggleTorch() async {
    if (_qrController != null) {
      await _qrController!.toggleFlash();
      setState(() {
        _flashEnabled = !_flashEnabled;
      });
    }
  }

  void _resetScanner() {
    print('🔄 [QR_SCANNER] Resetting scanner state...');
    setState(() {
      _isScanning = true;
      _errorMessage = null;
    });

    // Resume camera if it was paused
    _qrController?.resumeCamera();
    print('✅ [QR_SCANNER] Scanner reset complete');
  }

  /// Public method to reset scanner from external calls
  void resetScannerState() {
    _resetScanner();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.8),
      child: SafeArea(
        child: Stack(
          children: [
            // Scanner view
            if (_errorMessage == null) _buildScannerView(),

            // Loading view
            if (_isInitializing) _buildLoadingView(),

            // Error view
            if (_errorMessage != null) _buildErrorView(),

            // Overlay UI
            _buildOverlayUI(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Positioned.fill(
      child: Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: NeonColors.electricGreen),
              const SizedBox(height: 16),
              Text(
                'Initializing Camera...',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScannerView() {
    return Positioned.fill(
      child: QRView(
        key: _qrKey,
        onQRViewCreated: _onQRViewCreated,
        overlay: QrScannerOverlayShape(
          borderColor: NeonColors.electricGreen,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: 250,
        ),
        onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
      ),
    );
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    print('📱 [QR_SCANNER] Camera permission: $p');
    if (!p) {
      setState(() {
        _errorMessage =
            'Camera permission denied. Please enable camera access in settings.';
      });
    }
  }

  Widget _buildErrorView() {
    return Positioned.fill(
      child: Center(
        child: GlassmorphismContainer(
          padding: const EdgeInsets.all(UIConstants.spacing6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: NeonColors.glowRed,
                size: 64,
              ),
              const SizedBox(height: UIConstants.spacing4),
              Text(
                'Scanner Error',
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: UIConstants.spacing2),
              Text(
                _errorMessage!,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: UIConstants.spacing4),
              NeonIconButton.primary(
                label: 'Retry',
                color: Colors.green,
                onTap: () {
                  setState(() {
                    _errorMessage = null;
                  });
                },
                buttonSize: ButtonSize.medium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverlayUI(BuildContext context) {
    return Stack(
      children: [
        // Top bar with close button and title
        Positioned(
          top: UIConstants.spacing4,
          left: UIConstants.spacing4,
          right: UIConstants.spacing4,
          child: GlassmorphismContainer(
            padding: const EdgeInsets.symmetric(
              horizontal: UIConstants.spacing4,
              vertical: UIConstants.spacing2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Scan Bin QR Code',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                NeonIconButton(
                  icon: Icons.close,
                  color: Colors.white,
                  onTap: widget.onClose,
                  tooltip: 'Close',
                ),
              ],
            ),
          ),
        ),

        // Animated scan line overlay (optional since QRView has its own overlay)
        if (_isScanning && _errorMessage == null) _buildScanLineOverlay(),

        // Bottom controls
        Positioned(
          bottom: UIConstants.spacing4,
          left: UIConstants.spacing4,
          right: UIConstants.spacing4,
          child: _buildBottomControls(),
        ),

        // Instructions
        Positioned(
          bottom: 120,
          left: UIConstants.spacing4,
          right: UIConstants.spacing4,
          child: _buildInstructions(),
        ),
      ],
    );
  }

  Widget _buildScanLineOverlay() {
    return Center(
      child: SizedBox(
        width: 250,
        height: 250,
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: _scanLineAnimation,
              builder: (context, child) {
                return Positioned(
                  top: _scanLineAnimation.value * 230,
                  left: 10,
                  right: 10,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          NeonColors.electricGreen,
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: NeonColors.electricGreen.withOpacity(0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return GlassmorphismContainer(
      padding: const EdgeInsets.all(UIConstants.spacing4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Torch toggle
          NeonIconButton(
            icon: Icons.flash_on,
            color: _flashEnabled ? NeonColors.solarYellow : Colors.white,
            onTap: _toggleTorch,
            tooltip: 'Toggle Flashlight',
          ),

          // Reset scanner
          if (!_isScanning)
            NeonIconButton(
              icon: Icons.refresh,
              color: Colors.white,
              onTap: _resetScanner,
              tooltip: 'Scan Again',
            ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return GlassmorphismContainer(
      padding: const EdgeInsets.all(UIConstants.spacing4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isScanning ? Icons.qr_code_scanner : Icons.check_circle,
            color: _isScanning
                ? NeonColors.oceanBlue
                : NeonColors.electricGreen,
            size: 32,
          ),
          const SizedBox(height: UIConstants.spacing2),
          Text(
            _isScanning
                ? 'Position the QR code within the frame'
                : 'QR code detected! Processing...',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          if (_isScanning) ...[
            const SizedBox(height: UIConstants.spacing1),
            Text(
              'Make sure the code is well-lit and clearly visible',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
