import 'package:flutter/material.dart';
import '../../core/models/achievement_card.dart';

class AchievementCardWidget extends StatelessWidget {
  final AchievementCard card;
  final VoidCallback? onTap;
  final bool showShareButton;

  const AchievementCardWidget({
    super.key,
    required this.card,
    this.onTap,
    this.showShareButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    ),
                    child: card.achievement.iconPath.isNotEmpty
                        ? Image.asset(
                            card.achievement.iconPath,
                            width: 32,
                            height: 32,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.emoji_events,
                                color: Theme.of(context).primaryColor,
                                size: 32,
                              );
                            },
                          )
                        : Icon(
                            Icons.emoji_events,
                            color: Theme.of(context).primaryColor,
                            size: 32,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card.achievement.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          card.achievement.category,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showShareButton)
                    IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: () {
                        // Handle share action
                      },
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                card.achievement.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Level ${card.achievement.level}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (card.achievement.isUnlocked)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Unlocked',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}