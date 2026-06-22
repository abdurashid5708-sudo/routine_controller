import 'package:flutter/material.dart';
import '../models/mission.dart';

class MissionTile extends StatelessWidget {
  final Mission mission;
  final VoidCallback onDelete;
  final VoidCallback onToggle;
  final VoidCallback onEdit;

  const MissionTile({
    super.key,
    required this.mission,
    required this.onDelete,
    required this.onToggle,
    required this.onEdit,
  });

  Color get _priorityColor {
    switch (mission.priority) {
      case 'High':
        return Colors.redAccent;
      case 'Medium':
        return Colors.amber;
      case 'Low':
        return Colors.grey;
      default:
        return Colors.amber;
    }
  }

  Color get _priorityBg {
    return _priorityColor.withValues(alpha: 0.1);
  }

  Color get _priorityBorder {
    return _priorityColor.withValues(alpha: 0.3);
  }

  @override
  Widget build(BuildContext context) {
    String timeDisplay = '';
    if (mission.startTime != null && mission.endTime != null) {
      final startStr =
          '${mission.startTime!.hour.toString().padLeft(2, '0')}:${mission.startTime!.minute.toString().padLeft(2, '0')}';
      final endStr =
          '${mission.endTime!.hour.toString().padLeft(2, '0')}:${mission.endTime!.minute.toString().padLeft(2, '0')}';
      final now = DateTime.now();
      final isFutureDate =
          mission.startTime!.year != now.year ||
          mission.startTime!.month != now.month ||
          mission.startTime!.day != now.day;
      if (isFutureDate) {
        timeDisplay =
            '📅 ${mission.startTime!.day}.${mission.startTime!.month}  $startStr - $endStr';
      } else {
        timeDisplay = '⏰ $startStr - $endStr';
      }
    }

    final isCompleted = mission.isCompleted;

    return Dismissible(
      key: ValueKey(mission.id),
      onDismissed: (direction) => onDelete(),
      background: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: InkWell(
        onTap: onToggle,
        onLongPress: onEdit,
        borderRadius: BorderRadius.circular(15),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isCompleted
                ? Colors.green.withValues(alpha: 0.06)
                : _priorityBg,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isCompleted
                  ? Colors.green.withValues(alpha: 0.3)
                  : _priorityBorder,
              width: 1.2,
            ),
            boxShadow: isCompleted
                ? []
                : [
                    BoxShadow(
                      color: _priorityColor.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted ? Colors.green : Colors.transparent,
                  border: Border.all(
                    color: isCompleted
                        ? Colors.green
                        : _priorityColor.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            mission.title,
                            style: TextStyle(
                              color: isCompleted
                                  ? Colors.grey[500]
                                  : Colors.white,
                              fontSize: 16,
                              fontWeight: isCompleted
                                  ? FontWeight.normal
                                  : FontWeight.w600,
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              decorationColor: Colors.grey[500],
                            ),
                          ),
                        ),
                        if (!isCompleted && mission.priority == 'High')
                          const SizedBox(width: 8),
                        if (!isCompleted && mission.priority == 'High')
                          Icon(
                            Icons.bolt,
                            color: Colors.redAccent.withValues(alpha: 0.6),
                            size: 16,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            mission.category,
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? Colors.grey.withValues(alpha: 0.1)
                                : _priorityBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            mission.priority.toUpperCase(),
                            style: TextStyle(
                              color: isCompleted
                                  ? Colors.grey[600]
                                  : _priorityColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (timeDisplay.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? Colors.grey.withValues(alpha: 0.08)
                                  : Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              timeDisplay,
                              style: TextStyle(
                                color: isCompleted
                                    ? Colors.grey[600]
                                    : Colors.grey[400],
                                fontSize: 11,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
