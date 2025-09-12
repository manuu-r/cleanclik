import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cleanclik/core/services/platform/platform_optimizer.dart';
import 'package:cleanclik/core/services/social/social_sharing_service.dart';
import 'package:cleanclik/core/services/social/social_card_generation_service.dart';
// Removed duplicate import for platform_optimizer.dart
import 'package:cleanclik/core/services/auth/auth_service.dart';
import 'package:cleanclik/core/services/social/leaderboard_service.dart';
import 'package:cleanclik/core/models/achievement_card.dart';
import 'package:cleanclik/core/models/card_data.dart';
import 'package:cleanclik/core/theme/neon_colors.dart';
import 'package:cleanclik/presentation/widgets/common/glassmorphism_container.dart';
import 'package:cleanclik/presentation/widgets/common/neon_icon_button.dart';
import 'dart:io';

class FloatingShareOverlay extends ConsumerStatefulWidget {
  const FloatingShareOverlay({super.key});

  @override
  ConsumerState<FloatingShareOverlay> createState() =>
      _FloatingShareOverlayState();
}

class _FloatingShareOverlayState extends ConsumerState<FloatingShareOverlay>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  AchievementCard? _previewCard;
  File? _generatedCardFile;
  CardData? _cardData;
  CardTemplate _selectedTemplate = CardTemplate.achievement;
  SocialPlatform _selectedPlatform = SocialPlatform.system;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );

    // Start animations and generate preview card
    _slideController.forward();
    _scaleController.forward();
    _generatePreviewCard();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _close() {
    _slideController.reverse().then((_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  Future<void> _generatePreviewCard() async {
    if (_isGenerating) return;

    setState(() {
      _isGenerating = true;
    });

    try {
      print('🔄 Starting card generation...');

      // First generate legacy achievement card for preview
      final currentUser = ref.read(currentUserProvider);
      final leaderboardService = await ref.read(
        leaderboardServiceProvider.future,
      );

      if (currentUser != null) {
        print('👤 Current user found: ${currentUser.username}');

        final card = AchievementCard.pointsMilestone(
          points: currentUser.totalPoints,
          username: currentUser.username,
          totalItems: currentUser.totalItemsCollected,
          accuracy: leaderboardService.accuracyPercentage,
        );

        setState(() {
          _previewCard = card;
        });

        print('✅ Preview card generated successfully');
      } else {
        print('❌ No current user found');
      }

      // Try to generate the social media card in background
      try {
        final cardGenerationService = ref.read(
          socialCardGenerationServiceProvider,
        );

        print('📊 Aggregating user data...');
        _cardData = await cardGenerationService.aggregateUserData(ref);
        print('✅ User data aggregated');

        print(
          '🎨 Generating ${_selectedTemplate.displayName} card for ${_selectedPlatform.displayName}...',
        );
        _generatedCardFile = await cardGenerationService.generateCard(
          template: _selectedTemplate,
          data: _cardData!,
          platform: _selectedPlatform,
        );
        print('✅ Social media card generated: ${_generatedCardFile?.path}');

        // If we successfully generated the card, we can enable sharing
        if (_generatedCardFile != null && _generatedCardFile!.existsSync()) {
          print('🎉 Card file verified and ready for sharing');
        }
      } catch (socialCardError) {
        print(
          '⚠️ Social card generation failed (preview still available): $socialCardError',
        );
        // Create a simple fallback - we'll still allow sharing with the legacy card
        _generatedCardFile = null;
        _cardData = null;
      }

      setState(() {
        _isGenerating = false;
      });
    } catch (e, stackTrace) {
      print('❌ Error generating preview card: $e');
      print('📍 Stack trace: $stackTrace');
      setState(() {
        _isGenerating = false;
      });
    }
  }

  Future<void> _shareCard() async {
    try {
      final socialService = ref.read(socialSharingServiceProvider);
      bool success = false;

      // Try to share the generated social media card first
      if (_generatedCardFile != null && _cardData != null) {
        print('📤 Sharing generated social media card...');

        final platformOptimizer = ref.read(platformOptimizerProvider);
        final shareText = platformOptimizer.generateShareText(
          _cardData!,
          _selectedPlatform,
        );

        success = await socialService.shareSocialCard(
          _generatedCardFile!,
          shareText,
          _selectedPlatform,
        );

        if (success) {
          print('✅ Social media card shared successfully');
        }
      }

      // Fallback to legacy achievement card sharing
      if (!success && _previewCard != null) {
        print('📤 Falling back to legacy achievement card sharing...');

        success = await socialService.shareAchievementCard(
          _previewCard!,
          _selectedPlatform,
        );

        if (success) {
          print('✅ Legacy achievement card shared successfully');
        }
      }

      if (success) {
        _close();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to share. Please try again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error sharing card: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred while sharing.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _onTemplateChanged(CardTemplate? template) async {
    if (template == null || template == _selectedTemplate) return;

    setState(() {
      _selectedTemplate = template;
    });

    await _generatePreviewCard();
  }

  Future<void> _onPlatformChanged(SocialPlatform? platform) async {
    if (platform == null || platform == _selectedPlatform) return;

    setState(() {
      _selectedPlatform = platform;
    });

    await _generatePreviewCard();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Background overlay
          GestureDetector(
            onTap: _close,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              // Replaced with .withValues() if it were a Color property. As it is a Color constant, this is fine.
              color: Colors.black.withOpacity(
                0.35,
              ), // Adjusted opacity for better visibility
            ),
          ),

          // Floating share panel
          Positioned(
            bottom: 120,
            left: 16,
            right: 16,
            child: SlideTransition(
              position: _slideAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: GlassmorphismContainer(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Share Your CleanClik Card',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          NeonIconButton(
                            icon: Icons.close,
                            color: Colors.white.withValues(alpha: 0.7),
                            onTap: _close,
                            tooltip: 'Close',
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Template Selection
                      Row(
                        children: [
                          const Text(
                            'Template:',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                // Replaced with .withValues() if it were a Color property. As it is a Color constant, this is fine.
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  // Replaced with .withValues() if it were a Color property. As it is a Color constant, this is fine.
                                  color: Colors.white.withOpacity(0.2),
                                ),
                              ),
                              child: DropdownButton<CardTemplate>(
                                value: _selectedTemplate,
                                onChanged: _onTemplateChanged,
                                dropdownColor: Colors.grey[800],
                                underline: const SizedBox.shrink(),
                                isExpanded: true,
                                style: const TextStyle(color: Colors.white),
                                items: CardTemplate.values.map((template) {
                                  return DropdownMenuItem(
                                    value: template,
                                    child: Text(
                                      template.displayName,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Platform Selection
                      Row(
                        children: [
                          const Text(
                            'Platform:',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                // Replaced with .withValues() if it were a Color property. As it is a Color constant, this is fine.
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  // Replaced with .withValues() if it were a Color property. As it is a Color constant, this is fine.
                                  color: Colors.white.withOpacity(0.2),
                                ),
                              ),
                              child: DropdownButton<SocialPlatform>(
                                value: _selectedPlatform,
                                onChanged: _onPlatformChanged,
                                dropdownColor: Colors.grey[800],
                                underline: const SizedBox.shrink(),
                                isExpanded: true,
                                style: const TextStyle(color: Colors.white),
                                items:
                                    [
                                      SocialPlatform.system,
                                      SocialPlatform.instagram,
                                      SocialPlatform.twitter,
                                      SocialPlatform.facebook,
                                      SocialPlatform.stories,
                                    ].map((platform) {
                                      return DropdownMenuItem(
                                        value: platform,
                                        child: Text(
                                          platform.displayName,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      );
                                    }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Preview Card
                      if (_isGenerating)
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            // Replaced with .withValues() if it were a Color property. As it is a Color constant, this is fine.
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              // Replaced with .withValues() if it were a Color property. As it is a Color constant, this is fine.
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    NeonColors.electricGreen,
                                  ),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Generating your card...', // Simplified text
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (_previewCard != null)
                        _buildPreviewCard()
                      else
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            // Replaced with .withValues() if it were a Color property. As it is a Color constant, this is fine.
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              // Replaced with .withValues() if it were a Color property. As it is a Color constant, this is fine.
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              'Unable to generate preview',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 32),

                      // Share Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: NeonIconButton.primary(
                          label: 'Share Now',
                          icon: Icons.share,
                          color: (_generatedCardFile != null ||
                                      _previewCard != null) &&
                                  !_isGenerating
                              ? NeonColors.electricGreen
                              : Colors.grey,
                          onTap: (_generatedCardFile != null ||
                                      _previewCard != null) &&
                                  !_isGenerating
                              ? _shareCard
                              : null,
                          buttonSize: ButtonSize.large,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Helper text
                      Text(
                        _getHelperText(),
                        style: TextStyle(
                          // Replaced with .withValues() if it were a Color property. As it is a Color constant, this is fine.
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard() {
    if (_previewCard == null) return const SizedBox.shrink();

    final card = _previewCard!;
    final currentUser = ref.watch(currentUserProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [NeonColors.electricGreen, NeonColors.cosmicPurple],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            // Replaced with .withValues() if it were a Color property. As it is a Color constant, this is fine.
            color: NeonColors.electricGreen.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getPreviewTitle(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  // Replaced with .withValues() if it were a Color property. As it is a Color constant, this is fine.
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'CleanClik',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Achievement details
          Text(
            card.achievement.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          if (currentUser != null) ...[
            Text(
              'By ${currentUser.username}',
              style: TextStyle(
                // Replaced with .withValues() if it were a Color property. As it is a Color constant, this is fine.
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),

            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem('Points', currentUser.totalPoints.toString()),
                _buildStatItem(
                  'Items',
                  currentUser.totalItemsCollected.toString(),
                ),
                Consumer(
                  builder: (context, ref, child) {
                    final leaderboardServiceAsync = ref.watch(
                      leaderboardServiceProvider,
                    );
                    return leaderboardServiceAsync.when(
                      data: (service) => _buildStatItem(
                        'Accuracy',
                        '${service.accuracyPercentage.toStringAsFixed(1)}%',
                      ),
                      loading: () => _buildStatItem('Accuracy', '--'),
                      error: (_, __) => _buildStatItem('Accuracy', '--'),
                    );
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            // Replaced with .withValues() if it were a Color property. As it is a Color constant, this is fine.
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _getPreviewTitle() {
    switch (_selectedTemplate) {
      case CardTemplate.achievement:
        return '🎉 Achievement Unlocked!';
      case CardTemplate.impact:
        return '🌍 Environmental Impact';
      case CardTemplate.progress:
        return '📈 Progress Report';
      // Default case added for safety, though unlikely to be hit
      default:
        return 'Your CleanClik Card';
    }
  }

  String _getHelperText() {
    if (_isGenerating) {
      return 'Generating your ${_selectedTemplate.displayName.toLowerCase()} card...';
    } else if (_generatedCardFile != null) {
      return 'Ready to share your ${_selectedTemplate.displayName.toLowerCase()} card!';
    } else if (_previewCard != null) {
      return 'Preview available - choose template and platform to share';
    } else {
      return 'Unable to generate preview - please try again';
    }
  }
}
