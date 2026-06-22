import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  final int streak;
  final int totalMissions;
  final int completedMissions;

  const ProfileScreen({
    super.key,
    required this.streak,
    required this.totalMissions,
    required this.completedMissions,
  });

  // Calculate user title level based on empirical completions
  String _getUserRank() {
    if (completedMissions >= 50) return "Grandmaster Strategist 👑";
    if (completedMissions >= 20) return "Time-Block Master ⚡";
    if (completedMissions >= 5) return "Routine Warrior 🔥";
    return "Novice Planner 🌱";
  }

  double _getNextLevelProgress() {
    if (completedMissions >= 50) return 1.0;
    if (completedMissions >= 20) return (completedMissions - 20) / 30;
    if (completedMissions >= 5) return (completedMissions - 5) / 15;
    return completedMissions / 5;
  }

  int _getMissionsNeededForNextLevel() {
    if (completedMissions >= 50) return 0;
    if (completedMissions >= 20) return 50 - completedMissions;
    if (completedMissions >= 5) return 20 - completedMissions;
    return 5 - completedMissions;
  }

  @override
  Widget build(BuildContext context) {
    final rank = _getUserRank();
    final progress = _getNextLevelProgress();
    final remaining = _getMissionsNeededForNextLevel();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Text(
                "Operator Profile",
                style: TextStyle(
                  color: AppColors.onSurface,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Your system status and behavioral achievements.",
                style: TextStyle(color: AppColors.secondaryText, fontSize: 14),
              ),
              const SizedBox(height: 30),

              // Premium Profile Avatar & Rank Badge Card
              Center(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 52,
                          backgroundColor: AppColors.primary.withValues(
                            alpha: 0.15,
                          ),
                          child: const Icon(
                            Icons.shield_rounded,
                            size: 54,
                            color: AppColors.primary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.secondary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.bolt,
                            size: 16,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      rank,
                      style: const TextStyle(
                        color: AppColors.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Current Streak: $streak Days 🔥",
                      style: const TextStyle(
                        color: AppColors.secondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Leveling Progression Meter
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Rank Experience",
                          style: TextStyle(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (remaining > 0)
                          Text(
                            "$remaining more to rank up",
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                            ),
                          )
                        else
                          const Text(
                            "Max Rank Achieved",
                            style: TextStyle(
                              color: AppColors.secondary,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: AppColors.surfaceContainerLow,
                        color: AppColors.primary,
                        minHeight: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              const Text(
                "System Operational Statistics",
                style: TextStyle(
                  color: AppColors.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),

              // Grid-style statistics metrics cards
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
                children: [
                  _statsBox(
                    "Total Allocated",
                    "$totalMissions",
                    "Time Blocks",
                    Colors.blueAccent,
                  ),
                  _statsBox(
                    "Execution Output",
                    "$completedMissions",
                    "Success Logs",
                    Colors.greenAccent,
                  ),
                  _statsBox(
                    "Database Sync",
                    "Local",
                    "SharedPreferences",
                    Colors.purpleAccent,
                  ),
                  _statsBox(
                    "System Core",
                    "v2.5.0",
                    "Flutter Native",
                    Colors.amberAccent,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statsBox(
    String label,
    String value,
    String subtitle,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.onSurface.withValues(alpha: 0.02)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: accentColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
