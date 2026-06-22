import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../theme/app_colors.dart';

class HabitScreen extends StatefulWidget {
  final List<Habit> habits;
  final Function(String) onAddHabit;
  final Function(String) onToggleHabit;
  final Function(String) onDeleteHabit;

  const HabitScreen({
    super.key,
    required this.habits,
    required this.onAddHabit,
    required this.onToggleHabit,
    required this.onDeleteHabit,
  });

  @override
  State<HabitScreen> createState() => _HabitScreenState();
}

class _HabitScreenState extends State<HabitScreen> {
  final TextEditingController _habitController = TextEditingController();

  void _submitHabit() {
    final text = _habitController.text.trim();
    if (text.isNotEmpty) {
      widget.onAddHabit(text);
      _habitController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  @override
  void dispose() {
    _habitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Text(
                "Atomic Habits",
                style: TextStyle(
                  color: AppColors.onSurface,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Daily routines reset automatically at midnight.",
                style: TextStyle(color: AppColors.secondaryText, fontSize: 14),
              ),
              const SizedBox(height: 25),

              // Quick Entry Box
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _habitController,
                      style: const TextStyle(color: AppColors.onSurface),
                      onSubmitted: (_) => _submitHabit(),
                      decoration: InputDecoration(
                        hintText: "Build a new daily ritual...",
                        hintStyle: const TextStyle(
                          color: AppColors.onSurfaceVariant,
                        ),
                        filled: true,
                        fillColor: AppColors.surfaceContainer,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 54,
                    width: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: _submitHabit,
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),

              // Interactive Tracking List Feed
              Expanded(
                child: widget.habits.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.repeat_on_rounded,
                              size: 64,
                              color: AppColors.surfaceContainerHigh,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "No daily habits tracking yet",
                              style: TextStyle(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: widget.habits.length,
                        itemBuilder: (context, index) {
                          final habit = widget.habits[index];
                          return Dismissible(
                            key: ValueKey(habit.id),
                            direction: DismissDirection.endToStart,
                            onDismissed: (_) => widget.onDeleteHabit(habit.id),
                            background: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              alignment: Alignment.centerRight,
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.delete_outline,
                                color: Colors.white,
                              ),
                            ),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLow.withValues(
                                  alpha: 0.8,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: habit.isCompletedToday
                                      ? AppColors.primary.withValues(alpha: 0.3)
                                      : AppColors.onSurface.withValues(
                                          alpha: 0.06,
                                        ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Custom Check Circular Wrapper Action
                                  IconButton(
                                    icon: Icon(
                                      habit.isCompletedToday
                                          ? Icons.check_circle
                                          : Icons.radio_button_unchecked,
                                      color: habit.isCompletedToday
                                          ? AppColors.primary
                                          : AppColors.onSurfaceVariant,
                                      size: 28,
                                    ),
                                    onPressed: () =>
                                        widget.onToggleHabit(habit.id),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          habit.title,
                                          style: TextStyle(
                                            color: AppColors.onSurface,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            decoration: habit.isCompletedToday
                                                ? TextDecoration.lineThrough
                                                : null,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Streak: ${habit.streak} days 🔥",
                                          style: TextStyle(
                                            color: habit.streak > 0
                                                ? AppColors.secondary
                                                : AppColors.onSurfaceVariant,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
