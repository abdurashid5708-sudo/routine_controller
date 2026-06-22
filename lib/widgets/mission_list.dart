import 'package:flutter/material.dart';
import '../models/mission.dart';
import '../widgets/mission_tile.dart';

class MissionList extends StatelessWidget {
  final List<Mission> missions;
  final Function(String) onDelete;
  final Function(String) onToggle;
  final Function(String) onEdit;

  const MissionList({
    super.key,
    required this.missions,
    required this.onDelete,
    required this.onToggle,
    required this.onEdit,
  });

  // Helper method to convert textual priorities into weighted values for strict sorting
  int _getPriorityWeight(String priority) {
    switch (priority) {
      case 'High':
        return 3;
      case 'Medium':
        return 2;
      case 'Low':
        return 1;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Separate Active and Completed blocks
    final activeMissions = missions.where((m) => !m.isCompleted).toList();
    final completedMissions = missions.where((m) => m.isCompleted).toList();

    // 2. Separate today's and upcoming active missions
    final now = DateTime.now();
    final todayMissions = activeMissions.where((m) {
      if (m.startTime == null) return true;
      return m.startTime!.year == now.year &&
          m.startTime!.month == now.month &&
          m.startTime!.day == now.day;
    }).toList();
    final upcomingMissions = activeMissions.where((m) {
      if (m.startTime == null) return false;
      return m.startTime!.year != now.year ||
          m.startTime!.month != now.month ||
          m.startTime!.day != now.day;
    }).toList();

    // 3. Apply explicit urgency sort weights to the active allocation list
    todayMissions.sort((a, b) {
      int weightA = _getPriorityWeight(a.priority);
      int weightB = _getPriorityWeight(b.priority);
      return weightB.compareTo(weightA);
    });
    upcomingMissions.sort((a, b) {
      if (a.startTime == null || b.startTime == null) return 0;
      return a.startTime!.compareTo(b.startTime!);
    });

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: missions.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: Column(
                  children: [
                    Icon(Icons.track_changes, size: 70, color: Colors.grey),
                    SizedBox(height: 20),
                    Text(
                      "No schedule items logged yet",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (todayMissions.isNotEmpty) ...[
                  const Text(
                    "Today's Schedule",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...todayMissions.map((mission) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: MissionTile(
                        mission: mission,
                        onDelete: () => onDelete(mission.id),
                        onToggle: () => onToggle(mission.id),
                        onEdit: () => onEdit(mission.id),
                      ),
                    );
                  }),
                ],
                if (upcomingMissions.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text(
                    "Upcoming",
                    style: TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...upcomingMissions.map((mission) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: MissionTile(
                        mission: mission,
                        onDelete: () => onDelete(mission.id),
                        onToggle: () => onToggle(mission.id),
                        onEdit: () => onEdit(mission.id),
                      ),
                    );
                  }),
                ],
                if (completedMissions.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text(
                    "Completed Blocks",
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...completedMissions.map((mission) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: MissionTile(
                        mission: mission,
                        onDelete: () => onDelete(mission.id),
                        onToggle: () => onToggle(mission.id),
                        onEdit: () => onEdit(mission.id),
                      ),
                    );
                  }),
                ],
              ],
            ),
    );
  }
}
