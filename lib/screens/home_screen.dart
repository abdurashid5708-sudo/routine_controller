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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 25),

                const Text(
                  "Schedule Time Block",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                AddMissionInput(
                  controller: missionController,
                  onAddMission: onAddMission,
                ),
                const SizedBox(height: 25),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Today's Plan",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                      child: PopupMenuButton<String>(
                        initialValue: selectedCategoryFilter,
                        onSelected: (v) => onCategoryFilterChanged(v),
                        offset: const Offset(0, 40),
                        color: const Color(0xFF1E1E1E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                        itemBuilder: (context) =>
                            ['All', 'General', 'Work', 'Study', 'Fitness'].map((
                              v,
                            ) {
                              final isSel = selectedCategoryFilter == v;
                              return PopupMenuItem<String>(
                                value: v,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSel
                                        ? Colors.green.withValues(alpha: 0.12)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 16,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isSel
                                              ? Colors.green
                                              : Colors.transparent,
                                          border: Border.all(
                                            color: isSel
                                                ? Colors.green
                                                : Colors.grey[600]!,
                                            width: 2,
                                          ),
                                        ),
                                        child: isSel
                                            ? const Icon(
                                                Icons.check,
                                                color: Colors.white,
                                                size: 10,
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        v,
                                        style: TextStyle(
                                          color: isSel
                                              ? Colors.green
                                              : Colors.grey[300],
                                          fontWeight: isSel
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.filter_list_rounded,
                              color: Colors.green,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              selectedCategoryFilter,
                              style: const TextStyle(
                                color: Colors.green,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Colors.green.withValues(alpha: 0.7),
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                MissionList(
                  missions: missions,
                  onDelete: onDelete,
                  onToggle: onToggle,
                  onEdit: onEdit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
