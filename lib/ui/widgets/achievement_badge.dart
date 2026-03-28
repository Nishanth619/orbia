import 'package:flutter/material.dart';

import '../../models/achievement_model.dart';
import '../../state/achievement_provider.dart';

class AchievementBadge extends StatelessWidget {
  const AchievementBadge({super.key, required this.progress});
  final AchievementProgress progress;

  @override
  Widget build(BuildContext context) {
    final AchievementModel m = progress.model;
    final bool unlocked = progress.isUnlocked;
    final bool hidden = m.isSecret && !unlocked;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFF3D0020),
        border: Border.all(
          color: unlocked ? Colors.white38 : Colors.white12,
          width: 1.0,
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withAlpha(unlocked ? 31 : 13),
            ),
            child: Icon(
              hidden ? Icons.help_outline : _iconFor(m.category),
              color: unlocked ? Colors.white : Colors.white24,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  hidden ? '???' : m.displayName,
                  style: TextStyle(
                    color: unlocked ? Colors.white : Colors.white54,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hidden ? 'Keep playing to discover this.' : m.description,
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!unlocked && !hidden) ...<Widget>[
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: progress.progressFraction,
                      backgroundColor: Colors.white10,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white54),
                      minHeight: 3,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: <Widget>[
              Icon(
                unlocked ? Icons.check_circle : Icons.circle_outlined,
                color: unlocked ? Colors.white : Colors.white24,
                size: 16,
              ),
              const SizedBox(height: 3),
              Text('+${m.coinReward}',
                  style: TextStyle(
                    color: unlocked ? Colors.white60 : Colors.white24,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  )),
            ],
          ),
        ],
      ),
    );
  }

  IconData _iconFor(AchievementCategory cat) => switch (cat) {
        AchievementCategory.gameplay => Icons.sports_esports,
        AchievementCategory.economy => Icons.monetization_on_outlined,
        AchievementCategory.social => Icons.calendar_today,
        AchievementCategory.collection => Icons.palette_outlined,
      };
}
