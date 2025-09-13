import 'package:flutter/material.dart';
import 'mock_providers.dart';

// Mock AR overlay widgets for golden tests

class EnhancedObjectOverlay extends StatelessWidget {
  final Map<String, dynamic> detectedObject;
  final Size screenSize;

  const EnhancedObjectOverlay({
    Key? key,
    required this.detectedObject,
    required this.screenSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final category = detectedObject['category'] as String? ?? 'unknown';
    final confidence = detectedObject['confidence'] as double? ?? 0.0;
    
    Color categoryColor = _getCategoryColor(category);
    
    return Stack(
      children: [
        Positioned(
          left: 50,
          top: 200,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: categoryColor.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: categoryColor, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getCategoryIcon(category),
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  category.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '${(confidence * 100).toInt()}%',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'recycle':
        return Colors.green;
      case 'organic':
        return Colors.brown;
      case 'landfill':
        return Colors.grey;
      case 'ewaste':
        return Colors.blue;
      case 'hazardous':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'recycle':
        return Icons.recycling;
      case 'organic':
        return Icons.eco;
      case 'landfill':
        return Icons.delete;
      case 'ewaste':
        return Icons.electrical_services;
      case 'hazardous':
        return Icons.warning;
      default:
        return Icons.help;
    }
  }
}

class IndicatorWidget extends StatelessWidget {
  final WasteCategory category;
  final double confidence;
  final Offset position;
  final bool isAnimating;

  const IndicatorWidget({
    Key? key,
    required this.category,
    required this.confidence,
    required this.position,
    this.isAnimating = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final categoryColor = _getCategoryColor(category);
    
    return Stack(
      children: [
        Positioned(
          left: position.dx,
          top: position.dy,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: categoryColor.withOpacity(0.8),
              shape: BoxShape.circle,
              border: Border.all(
                color: isAnimating ? Colors.white : categoryColor,
                width: isAnimating ? 3 : 2,
              ),
            ),
            child: Icon(
              _getCategoryIcon(category),
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Color _getCategoryColor(WasteCategory category) {
    switch (category) {
      case WasteCategory.recycle:
        return Colors.green;
      case WasteCategory.organic:
        return Colors.brown;
      case WasteCategory.landfill:
        return Colors.grey;
      case WasteCategory.ewaste:
        return Colors.blue;
      case WasteCategory.hazardous:
        return Colors.red;
    }
  }

  IconData _getCategoryIcon(WasteCategory category) {
    switch (category) {
      case WasteCategory.recycle:
        return Icons.recycling;
      case WasteCategory.organic:
        return Icons.eco;
      case WasteCategory.landfill:
        return Icons.delete;
      case WasteCategory.ewaste:
        return Icons.electrical_services;
      case WasteCategory.hazardous:
        return Icons.warning;
    }
  }
}

class DisposalCelebrationOverlay extends StatelessWidget {
  final bool isVisible;
  final WasteCategory category;
  final int pointsEarned;
  final double? streakMultiplier;
  final String? achievementUnlocked;

  const DisposalCelebrationOverlay({
    Key? key,
    required this.isVisible,
    required this.category,
    required this.pointsEarned,
    this.streakMultiplier,
    this.achievementUnlocked,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              
              // Title
              const Text(
                'Great Job!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              
              // Category
              Text(
                'Correctly disposed ${category.name}',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              
              // Points
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 24),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '+$pointsEarned points',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (streakMultiplier != null && streakMultiplier! > 1.0) ...[
                    const SizedBox(width: 8),
                    Text(
                      'x${streakMultiplier!.toStringAsFixed(1)}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
              
              // Achievement
              if (achievementUnlocked != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.emoji_events, color: Colors.amber),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Achievement: $achievementUnlocked',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Continue button
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(120, 40),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Camera mode switching widgets
class CameraModeSwitching extends StatelessWidget {
  const CameraModeSwitching({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ModeButton(
            icon: Icons.camera_alt,
            label: 'ML Detection',
            isActive: true,
            onTap: () {},
          ),
          _ModeButton(
            icon: Icons.qr_code_scanner,
            label: 'QR Scanner',
            isActive: false,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ModeButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.green : Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QRScannerOverlay extends StatelessWidget {
  final bool isScanning;
  final Size screenSize;
  final String? detectedQRCode;
  final String? errorMessage;

  const QRScannerOverlay({
    Key? key,
    required this.isScanning,
    required this.screenSize,
    this.detectedQRCode,
    this.errorMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Scanning frame
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(
                color: isScanning ? Colors.green : Colors.grey,
                width: 3,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                // Corner indicators
                ...List.generate(4, (index) => _buildCornerIndicator(index)),
                
                // Scanning line animation
                if (isScanning)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 100, // Simulated animation position
                    child: Container(
                      height: 2,
                      color: Colors.green,
                    ),
                  ),
              ],
            ),
          ),
        ),
        
        // Instructions
        Positioned(
          bottom: 150,
          left: 0,
          right: 0,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              detectedQRCode != null
                  ? 'QR Code Detected: $detectedQRCode'
                  : errorMessage != null
                      ? 'Error: $errorMessage'
                      : 'Position QR code within the frame',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCornerIndicator(int index) {
    final positions = [
      const Alignment(-1, -1), // Top-left
      const Alignment(1, -1),  // Top-right
      const Alignment(-1, 1),  // Bottom-left
      const Alignment(1, 1),   // Bottom-right
    ];

    return Align(
      alignment: positions[index],
      child: Container(
        width: 20,
        height: 20,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}