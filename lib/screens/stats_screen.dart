import 'package:flutter/material.dart';
import '../models/mission.dart';
import '../theme/app_colors.dart';

class StatsScreen extends StatelessWidget {
  final List<Mission> missions;

  const StatsScreen({super.key, required this.missions});

  // Gathers completion allocations over the trailing 7 calendar days
  List<int> _getTrailing7DayData() {
    final Map<int, int> completionCounts = {};
    final today = DateTime.now();

    for (int i = 0; i < 7; i++) {
      final dateToCheck = today.subtract(Duration(days: i));
      final midnightKey = DateTime(
        dateToCheck.year,
        dateToCheck.month,
        dateToCheck.day,
      ).millisecondsSinceEpoch;
      completionCounts[midnightKey] = 0;
    }

    for (var mission in missions) {
      if (mission.isCompleted && mission.dueDate != null) {
        final dayKey = DateTime(
          mission.dueDate!.year,
          mission.dueDate!.month,
          mission.dueDate!.day,
        ).millisecondsSinceEpoch;
        if (completionCounts.containsKey(dayKey)) {
          completionCounts[dayKey] = completionCounts[dayKey]! + 1;
        }
      }
    }

    return completionCounts.values.toList().reversed.toList();
  }

  @override
  Widget build(BuildContext context) {
    final trailingData = _getTrailing7DayData();
    final maxVal = trailingData.reduce(
      (curr, next) => curr > next ? curr : next,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Analytics Engine",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Rolling performance matrices and historical tracking.",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 30),

              // Rolling 7-Day Performance Micro-Graph Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "7-Day Output Trend",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 120,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: trailingData.map((count) {
                          final double heightFactor = maxVal == 0
                              ? 0.05
                              : (count / maxVal);
                          return Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  "$count",
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  height: 80 * heightFactor,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.8,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.2,
                                        ),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Context Ratios
              const Text(
                "Efficiency Distribution",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),

              ...['Work', 'Study', 'Fitness', 'General'].map((category) {
                final catTotal = missions
                    .where((m) => m.category == category)
                    .length;
                final catDone = missions
                    .where((m) => m.category == category && m.isCompleted)
                    .length;
                final double ratio = catTotal == 0 ? 0.0 : (catDone / catTotal);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        "${(ratio * 100).toStringAsFixed(0)}% Done ($catDone/$catTotal)",
                        style: TextStyle(
                          color: ratio > 0.7 ? Colors.green : Colors.amber,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
