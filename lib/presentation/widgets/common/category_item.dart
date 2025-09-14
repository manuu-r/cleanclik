import 'package:flutter/material.dart';
import 'package:cleanclik/core/theme/app_theme.dart';
import 'package:cleanclik/core/theme/neon_colors.dart';

/// Reusable category item component with Material 3 design
class CategoryItem extends StatelessWidget {
  final String name;
  final String description;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;
  final int? count;
  final bool showCount;

  const CategoryItem({
    super.key,
    required this.name,
    required this.description,
    required this.color,
    required this.icon,
    this.onTap,
    this.count,
    this.showCount = false,
  });

  /// Create category item for EcoGems (recyclable materials)
  factory CategoryItem.ecoGems({
    Key? key,
    VoidCallback? onTap,
    int? count,
    bool showCount = false,
  }) {
    return CategoryItem(
      key: key,
      name: 'EcoGems',
      description: 'Recyclable materials',
      color: NeonColors.electricGreen,
      icon: Icons.recycling,
      onTap: onTap,
      count: count,
      showCount: showCount,
    );
  }

  /// Create category item for FuelShards (organic waste)
  factory CategoryItem.fuelShards({
    Key? key,
    VoidCallback? onTap,
    int? count,
    bool showCount = false,
  }) {
    return CategoryItem(
      key: key,
      name: 'FuelShards',
      description: 'Organic waste',
      color: NeonColors.oceanBlue,
      icon: Icons.eco,
      onTap: onTap,
      count: count,
      showCount: showCount,
    );
  }

  /// Create category item for VoidDust (general landfill)
  factory CategoryItem.voidDust({
    Key? key,
    VoidCallback? onTap,
    int? count,
    bool showCount = false,
  }) {
    return CategoryItem(
      key: key,
      name: 'VoidDust',
      description: 'General landfill',
      color: Colors.grey,
      icon: Icons.delete,
      onTap: onTap,
      count: count,
      showCount: showCount,
    );
  }

  /// Create category item for SparkCores (electronic waste)
  factory CategoryItem.sparkCores({
    Key? key,
    VoidCallback? onTap,
    int? count,
    bool showCount = false,
  }) {
    return CategoryItem(
      key: key,
      name: 'SparkCores',
      description: 'Electronic waste',
      color: NeonColors.earthOrange,
      icon: Icons.electrical_services,
      onTap: onTap,
      count: count,
      showCount: showCount,
    );
  }

  /// Create category item for ToxicCrystals (hazardous materials)
  factory CategoryItem.toxicCrystals({
    Key? key,
    VoidCallback? onTap,
    int? count,
    bool showCount = false,
  }) {
    return CategoryItem(
      key: key,
      name: 'ToxicCrystals',
      description: 'Hazardous materials',
      color: NeonColors.toxicPurple,
      icon: Icons.warning,
      onTap: onTap,
      count: count,
      showCount: showCount,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(UIConstants.radiusLarge),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: UIConstants.spacing2),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(UIConstants.radiusXLarge),
                  border: Border.all(
                    color: color.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              SizedBox(width: UIConstants.spacing4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    SizedBox(height: UIConstants.spacing1),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              if (showCount && count != null) ...[
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: UIConstants.spacing3,
                    vertical: UIConstants.spacing1,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(UIConstants.radiusXLarge),
                  ),
                  child: Text(
                    '$count',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}