import 'package:flutter/material.dart';
import '../models/mission.dart';
import '../widgets/add_mission_input.dart';
import '../widgets/mission_list.dart';
import '../theme/app_colors.dart';

class HomeScreen extends StatelessWidget {
  final List<Mission> missions;
  final int completedCount;
  final int totalMissionCount;
  final TextEditingController missionController;
  final void Function(
    String title,
    String category,
    String priority,
    DateTime? dueDate,
    TimeOfDay? start,
    TimeOfDay? end,
  )
  onAddMission;
  final Function(String) onDelete;
  final Function(String) onToggle;
  final Function(String) onEdit;

  final String selectedCategoryFilter;
  final Function(String) onCategoryFilterChanged;

  final int streak;
  final int overdueCount;
  final int dueTodayCount;
  final int highPriorityCount;

  const HomeScreen({
    super.key,
    required this.missions,
    required this.completedCount,
    required this.totalMissionCount,
    required this.missionController,
    required this.onAddMission,
    required this.onDelete,
    required this.onToggle,
    required this.onEdit,
    required this.selectedCategoryFilter,
    required this.onCategoryFilterChanged,
    required this.streak,
    required this.overdueCount,
    required this.dueTodayCount,
    required this.highPriorityCount,
  });

  int get _todayBlockCount {
    final now = DateTime.now();
    return missions.where((m) {
      if (m.isCompleted) return false;
      if (m.startTime == null) return true;
      return m.startTime!.year == now.year &&
          m.startTime!.month == now.month &&
          m.startTime!.day == now.day;
    }).length;
  }

  double get _progressPercent =>
      totalMissionCount == 0 ? 0 : completedCount / totalMissionCount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // Top App Bar
                Row(
                  children: [
                    const Text(
                      "Schedule Time Block",
                      style: TextStyle(
                        color: AppColors.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Search & Add Section
                AddMissionInput(
                  controller: missionController,
                  onAddMission: onAddMission,
                ),
                const SizedBox(height: 24),

                // Today's Plan Summary
                const Text(
                  "Today's Plan",
                  style: TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow.withValues(
                            alpha: 0.8,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.onSurface.withValues(alpha: 0.08),
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "PROGRESS",
                              style: TextStyle(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.08,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      "${(_progressPercent * 100).toStringAsFixed(0)}%",
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 32,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.02,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 48,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: _progressPercent.clamp(
                                      0.0,
                                      1.0,
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow.withValues(
                            alpha: 0.8,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.onSurface.withValues(alpha: 0.08),
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "BLOCKS",
                              style: TextStyle(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.08,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      "$_todayBlockCount",
                                      style: const TextStyle(
                                        color: AppColors.secondary,
                                        fontSize: 32,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.02,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text(
                                    "Today",
                                    style: TextStyle(
                                      color: AppColors.onSurfaceVariant,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.05,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Filter Row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Today's Schedule",
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.onSurface.withValues(alpha: 0.9),
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      selected: selectedCategoryFilter,
                      onChanged: onCategoryFilterChanged,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                RepaintBoundary(
                  child: MissionList(
                    missions: missions,
                    onDelete: onDelete,
                    onToggle: onToggle,
                    onEdit: onEdit,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Small filter chip — stateless, no PopupMenuButton freeze
// ─────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _FilterChip({
    required this.selected,
    required this.onChanged,
  });

  static const _options = ['All', 'General', 'Work', 'Study', 'Fitness'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.onSurface.withValues(alpha: 0.06),
        ),
      ),
      child: GestureDetector(
        onTap: () => _showPicker(context),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.filter_list_rounded,
                color: AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                selected,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.primary.withValues(alpha: 0.7),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _options.map((v) {
              final isSel = selected == v;
              return InkWell(
                onTap: () {
                  onChanged(v);
                  Navigator.pop(ctx);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSel
                              ? AppColors.primary
                              : Colors.transparent,
                          border: Border.all(
                            color: isSel
                                ? AppColors.primary
                                : AppColors.onSurfaceVariant,
                            width: 2,
                          ),
                        ),
                        child: isSel
                            ? const Icon(Icons.check, color: Colors.white, size: 11)
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Text(
                        v,
                        style: TextStyle(
                          color: isSel
                              ? AppColors.primary
                              : AppColors.onSurfaceVariant,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
