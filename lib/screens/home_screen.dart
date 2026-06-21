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
  final VoidCallback onAddMission;
  final Function(String) onSubmitted;
  final Function(String) onDelete;
  final Function(String) onToggle;
  final Function(String) onEdit;

  final String selectedCategory;
  final Function(String) onCategoryChanged;
  final String selectedCategoryFilter;
  final Function(String) onCategoryFilterChanged;

 
  final String selectedPriority;
  final Function(String) onPriorityChanged;

  final int streak;
  final int overdueCount;
  final int dueTodayCount;
  final int highPriorityCount;

  final TimeOfDay? selectedStartTime;
  final TimeOfDay? selectedEndTime;
  final Function(TimeOfDay?) onStartTimeChanged;
  final Function(TimeOfDay?) onEndTimeChanged;

  const HomeScreen({
    super.key,
    required this.missions,
    required this.completedCount,
    required this.totalMissionCount,
    required this.missionController,
    required this.onAddMission,
    required this.onSubmitted,
    required this.onDelete,
    required this.onToggle,
    required this.onEdit,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.selectedCategoryFilter,
    required this.onCategoryFilterChanged,
    required this.selectedPriority,
    required this.onPriorityChanged,
    required this.streak,
    required this.overdueCount,
    required this.dueTodayCount,
    required this.highPriorityCount,
    required this.selectedStartTime,
    required this.selectedEndTime,
    required this.onStartTimeChanged,
    required this.onEndTimeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final availableCategories = [
      'General',
      'Work',
      'Study',
      'Fitness',
      'Sleep',
      'Meal',
    ];

    return Scaffold( 
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dashboard Statistics Grid
                // In screens/home_screen.dart
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

                // Core Entry Input Field
                AddMissionInput(
                  controller: missionController,
                  onAdd: onAddMission,
                  onSubmitted: onSubmitted,
                ),
                const SizedBox(height: 12),

                // Parametric Tray Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Allocation Category:",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // Mini priority selector readout
                          DropdownButton<String>(
                            value: selectedPriority,
                            dropdownColor: AppColors.card,
                            style: TextStyle(
                              color: selectedPriority == 'High'
                                  ? Colors.redAccent
                                  : Colors.amber,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            underline: Container(),
                            items: ['High', 'Medium', 'Low'].map((String p) {
                              return DropdownMenuItem<String>(
                                value: p,
                                child: Text("$p Priority"),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) onPriorityChanged(val);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 38,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: availableCategories.length,
                          itemBuilder: (context, index) {
                            final cat = availableCategories[index];
                            final isSelected = selectedCategory == cat;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: Text(cat),
                                selected: isSelected,
                                selectedColor: AppColors.primary,
                                backgroundColor: Colors.grey[900],
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey[400],
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                showCheckmark: false,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(
                                    color: isSelected
                                        ? AppColors.primary
                                        : Colors.transparent,
                                  ),
                                ),
                                onSelected: (selected) {
                                  if (selected) onCategoryChanged(cat);
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Divider(color: Colors.white10),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[900],
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime:
                                      selectedStartTime ?? TimeOfDay.now(),
                                );
                                onStartTimeChanged(picked);
                              },
                              child: Text(
                                selectedStartTime == null
                                    ? "⏰ Start Time"
                                    : "Start: ${selectedStartTime!.format(context)}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[900],
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime:
                                      selectedEndTime ?? TimeOfDay.now(),
                                );
                                onEndTimeChanged(picked);
                              },
                              child: Text(
                                selectedEndTime == null
                                    ? "⏰ End Time"
                                    : "End: ${selectedEndTime!.format(context)}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
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
                    DropdownButton<String>(
                      value: selectedCategoryFilter,
                      dropdownColor: AppColors.card,
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                      items:
                          [
                            'All',
                            'General',
                            'Work',
                            'Study',
                            'Fitness',
                            'Sleep',
                            'Meal',
                          ].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                      onChanged: (val) => onCategoryFilterChanged(val ?? 'All'),
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
