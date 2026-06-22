import 'package:flutter/material.dart';
import '../models/mission.dart';
import '../theme/app_colors.dart';

class MissionTile extends StatefulWidget {
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

  @override
  State<MissionTile> createState() => _MissionTileState();
}

class _MissionTileState extends State<MissionTile> {
  bool _isPressed = false;

  Color get _priorityColor {
    switch (widget.mission.priority) {
      case 'High':
        return AppColors.priorityHigh;
      case 'Medium':
        return AppColors.priorityMedium;
      case 'Low':
        return AppColors.priorityLow;
      default:
        return AppColors.priorityMedium;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mission = widget.mission;
    final isCompleted = mission.isCompleted;
    final opacity = isCompleted ? 0.6 : 1.0;

    String startStr = '';
    String endStr = '';
    bool isFutureDate = false;
    if (mission.startTime != null && mission.endTime != null) {
      startStr =
          '${mission.startTime!.hour.toString().padLeft(2, '0')}:${mission.startTime!.minute.toString().padLeft(2, '0')}';
      endStr =
          '${mission.endTime!.hour.toString().padLeft(2, '0')}:${mission.endTime!.minute.toString().padLeft(2, '0')}';
      final now = DateTime.now();
      isFutureDate =
          mission.startTime!.year != now.year ||
          mission.startTime!.month != now.month ||
          mission.startTime!.day != now.day;
    }

    return Dismissible(
      key: ValueKey(mission.id),
      onDismissed: (direction) => widget.onDelete(),
      background: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Opacity(
            opacity: opacity,
            child: InkWell(
              onTap: widget.onToggle,
              onLongPress: widget.onEdit,
              borderRadius: BorderRadius.circular(15),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: _priorityColor.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow.withValues(
                        alpha: 0.8,
                      ),
                      border: Border.all(
                        color: AppColors.onSurface.withValues(alpha: 0.08),
                      ),
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            width: 3,
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? AppColors.primary.withValues(alpha: 0.5)
                                  : _priorityColor,
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: widget.onToggle,
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      width: 24,
                                      height: 24,
                                      margin: const EdgeInsets.only(top: 2),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isCompleted
                                            ? AppColors.primary
                                            : Colors.transparent,
                                        border: Border.all(
                                          color: isCompleted
                                              ? AppColors.primary
                                              : _priorityColor.withValues(
                                                  alpha: 0.4,
                                                ),
                                          width: 2,
                                        ),
                                      ),
                                      child: isCompleted
                                          ? const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 14,
                                            )
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                mission.title,
                                                style: TextStyle(
                                                  color: isCompleted
                                                      ? AppColors
                                                            .onSurfaceVariant
                                                      : AppColors.onSurface,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  decoration: isCompleted
                                                      ? TextDecoration
                                                            .lineThrough
                                                      : null,
                                                  decorationColor: AppColors
                                                      .primary
                                                      .withValues(alpha: 0.4),
                                                ),
                                              ),
                                            ),
                                            if (!isCompleted &&
                                                mission.priority == 'High')
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  left: 6,
                                                ),
                                                child: Icon(
                                                  Icons.bolt,
                                                  color: AppColors.priorityHigh
                                                      .withValues(alpha: 0.6),
                                                  size: 16,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: [
                                            _badge(
                                              mission.category,
                                              AppColors.primary,
                                              isCompleted,
                                            ),
                                            _badge(
                                              mission.priority.toUpperCase(),
                                              _priorityColor,
                                              isCompleted,
                                            ),
                                            if (startStr.isNotEmpty)
                                              _timeBadge(
                                                startStr,
                                                endStr,
                                                isFutureDate,
                                                isCompleted,
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.more_vert,
                                    color: AppColors.onSurfaceVariant
                                        .withValues(alpha: 0.4),
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _badge(String text, Color color, bool isCompleted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isCompleted
            ? AppColors.surfaceContainerHighest
            : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isCompleted ? AppColors.onSurfaceVariant : color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.05,
        ),
      ),
    );
  }

  Widget _timeBadge(
    String startStr,
    String endStr,
    bool isFutureDate,
    bool isCompleted,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isCompleted
            ? AppColors.surfaceContainerHighest
            : AppColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFutureDate ? Icons.calendar_today : Icons.alarm,
            size: 12,
            color: isCompleted
                ? AppColors.onSurfaceVariant
                : AppColors.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            isFutureDate
                ? '${widget.mission.startTime!.day}.${widget.mission.startTime!.month}  $startStr - $endStr'
                : '$startStr - $endStr',
            style: TextStyle(
              color: isCompleted
                  ? AppColors.onSurfaceVariant
                  : AppColors.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
