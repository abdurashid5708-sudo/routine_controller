import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '/models/mission.dart';
import '/models/habit.dart'; // Import your Habit model
import 'package:uuid/uuid.dart';
import 'package:flutter/services.dart';

// Import screens and widgets to ensure proper compilation
import 'screens/home_screen.dart';
import 'screens/habits_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/stats_screen.dart';
import 'widgets/bottom_navbar.dart';
import 'theme/app_colors.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init(); // Initialize notifications
  runApp(const RoutineControllerApp());
}

// --- This goes at the bottom of your main.dart file ---

@pragma('vm:entry-point')
void onBlockScreenRequested() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "FOCUS MODE ACTIVE",
                style: TextStyle(color: Colors.red, fontSize: 24),
              ),
              const SizedBox(height: 20),

              // --- REPLACE YOUR PREVIOUS BUTTON WITH THIS ---
              ElevatedButton(
                onPressed: () {
                  // This closes the block screen process and sends the user back
                  // to their phone's home screen
                  SystemNavigator.pop();
                },
                child: const Text("Unlock (Not recommended!)"),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class RoutineControllerApp extends StatefulWidget {
  const RoutineControllerApp({super.key});

  @override
  State<RoutineControllerApp> createState() => _RoutineControllerAppState();
}

class _RoutineControllerAppState extends State<RoutineControllerApp> {
  List<Mission> missions = [];
  List<Habit> habits = []; // Global habits array
  TextEditingController missionController = TextEditingController();
  int currentIndex = 0;

  // Structured Field Inputs
  String selectedCategory = 'General';
  String selectedPriority = 'Medium';
  DateTime? selectedDueDate;
  TimeOfDay? selectedStartTime;
  TimeOfDay? selectedEndTime;

  String selectedCategoryFilter = 'All';
  int streak = 0;
  DateTime? lastCompletedDate;
  bool isLoading = true;
  final uuid = const Uuid();

  Mission? deletedMission;
  int? deletedMissionIndex;
  Habit? deletedHabit;
  int? deletedHabitIndex;

  @override
  void initState() {
    super.initState();
    loadAppData();
  }

  int get overdueCount {
    return missions.where((mission) {
      return mission.dueDate != null &&
          mission.dueDate!.isBefore(DateTime.now()) &&
          !mission.isCompleted;
    }).length;
  }

  int get dueTodayCount {
    final today = DateTime.now();
    return missions.where((mission) {
      if (mission.dueDate == null) return false;
      return mission.dueDate!.year == today.year &&
          mission.dueDate!.month == today.month &&
          mission.dueDate!.day == today.day;
    }).length;
  }

  int get highPriorityCount {
    return missions.where((mission) {
      return mission.priority == "High" && !mission.isCompleted;
    }).length;
  }

  int get completedCount {
    return missions.where((mission) => mission.isCompleted).length;
  }

  List<Mission> get categoryFilteredMissions {
    if (selectedCategoryFilter == "All") {
      return missions;
    }
    return missions
        .where((mission) => mission.category == selectedCategoryFilter)
        .toList();
  }

  void updateStreak() {
    if (missions.isEmpty) return;
    if (completedCount != missions.length) return;

    final today = DateTime.now();
    if (lastCompletedDate == null) {
      streak = 1;
      lastCompletedDate = today;
      return;
    }

    final difference = today.difference(lastCompletedDate!).inDays;
    if (difference == 0) return;
    if (difference == 1) {
      streak++;
    } else {
      streak = 1;
    }
    lastCompletedDate = today;
  }

  // Combined Loading Sequence for Application State
  Future<void> loadAppData() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Load Missions
    streak = prefs.getInt('streak') ?? 0;
    final savedDate = prefs.getString('lastCompletedDate');
    if (savedDate != null) {
      lastCompletedDate = DateTime.parse(savedDate);
    }
    List<String>? missionList = prefs.getStringList('missions');
    if (missionList != null) {
      missions = missionList
          .map((m) => Mission.fromJson(jsonDecode(m)))
          .toList();
    }

    // 2. Load Habits & Execute Midnight Reset Evaluations
    List<String>? habitList = prefs.getStringList('habits');
    String? lastHabitCheckStr = prefs.getString('lastHabitCheckDate');
    DateTime today = DateTime.now();
    bool isNewDay = false;

    if (lastHabitCheckStr != null) {
      DateTime lastCheck = DateTime.parse(lastHabitCheckStr);
      if (lastCheck.year != today.year ||
          lastCheck.month != today.month ||
          lastCheck.day != today.day) {
        isNewDay = true;
      }
    } else {
      isNewDay = true;
    }

    if (habitList != null) {
      habits = habitList.map((h) {
        Habit habit = Habit.fromJson(jsonDecode(h));
        if (isNewDay) {
          // If they missed completing it yesterday, the habit streak breaks down back to 0
          if (!habit.isCompletedToday) {
            habit.streak = 0;
          }
          habit.isCompletedToday = false;
        }
        return habit;
      }).toList();
    }

    if (isNewDay) {
      await prefs.setString('lastHabitCheckDate', today.toIso8601String());
      List<String> synchronizedHabits = habits
          .map((h) => jsonEncode(h.toJson()))
          .toList();
      await prefs.setStringList('habits', synchronizedHabits);
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> saveMissions() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> missionList = missions
        .map((m) => jsonEncode(m.toJson()))
        .toList();
    await prefs.setStringList('missions', missionList);
    await prefs.setInt('streak', streak);
    if (lastCompletedDate != null) {
      await prefs.setString(
        'lastCompletedDate',
        lastCompletedDate!.toIso8601String(),
      );
    }
  }

  // Habits State Persistors
  Future<void> saveHabits() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> habitList = habits.map((h) => jsonEncode(h.toJson())).toList();
    await prefs.setStringList('habits', habitList);
  }

  DateTime? _combineDateTime(DateTime? baseDate, TimeOfDay? time) {
    if (baseDate == null || time == null) return null;
    return DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      time.hour,
      time.minute,
    );
  }

  void _addNewMissionFromInputs() {
    if (missionController.text.trim().isEmpty) return;

    final baseDate = selectedDueDate ?? DateTime.now();
    final parsedStart = _combineDateTime(baseDate, selectedStartTime);
    final parsedEnd = _combineDateTime(baseDate, selectedEndTime);

    setState(() {
      missions.add(
        Mission(
          id: uuid.v4(),
          title: missionController.text.trim(),
          category: selectedCategory,
          dueDate: selectedDueDate,
          priority: selectedPriority,
          startTime: parsedStart,
          endTime: parsedEnd,
        ),
      );
    });

    missionController.clear();
    selectedPriority = 'Medium';
    selectedDueDate = null;
    selectedStartTime = null;
    selectedEndTime = null;
    saveMissions();
    FocusScope.of(context).unfocus();
  }

  Widget getScreenForIndex(BuildContext context) {
    if (currentIndex == 0) {
      return HomeScreen(
        streak: streak,
        overdueCount: overdueCount,
        dueTodayCount: dueTodayCount,
        highPriorityCount: highPriorityCount,
        missions: categoryFilteredMissions,
        selectedPriority: selectedPriority,
        onPriorityChanged: (priority) =>
            setState(() => selectedPriority = priority),
        selectedCategory: selectedCategory,
        selectedCategoryFilter: selectedCategoryFilter,
        onCategoryFilterChanged: (category) =>
            setState(() => selectedCategoryFilter = category),
        onCategoryChanged: (category) =>
            setState(() => selectedCategory = category),
        totalMissionCount: missions.length,
        completedCount: completedCount,
        missionController: missionController,
        selectedStartTime: selectedStartTime,
        selectedEndTime: selectedEndTime,
        onStartTimeChanged: (time) => setState(() => selectedStartTime = time),
        onEndTimeChanged: (time) => setState(() => selectedEndTime = time),
        onAddMission: _addNewMissionFromInputs,
        onSubmitted: (value) => _addNewMissionFromInputs(),
        onDelete: (id) {
          final missionIndex = missions.indexWhere((m) => m.id == id);
          if (missionIndex == -1) {
            return;
          }

          final messenger = ScaffoldMessenger.of(context);
          deletedMission = missions[missionIndex];
          deletedMissionIndex = missionIndex;

          setState(() {
            missions.removeAt(missionIndex);
          });
          saveMissions();

          messenger.clearSnackBars();
          messenger.showSnackBar(
            SnackBar(
              content: const Text("Mission deleted"),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: "UNDO",
                textColor: Colors.white,
                onPressed: () {
                  if (deletedMission != null && deletedMissionIndex != null) {
                    setState(() {
                      missions.insert(deletedMissionIndex!, deletedMission!);
                    });
                    saveMissions();
                  }
                },
              ),
            ),
          );
        },
        onEdit: (id) async {
          final missionIndex = missions.indexWhere((m) => m.id == id);
          if (missionIndex == -1) {
            return;
          }

          final editController = TextEditingController(
            text: missions[missionIndex].title,
          );
          String selectedEditCategory = missions[missionIndex].category;
          String selectedEditPriority = missions[missionIndex].priority;
          DateTime? selectedEditDueDate = missions[missionIndex].dueDate;

          TimeOfDay? selectedEditStartTime =
              missions[missionIndex].startTime != null
              ? TimeOfDay.fromDateTime(missions[missionIndex].startTime!)
              : null;
          TimeOfDay? selectedEditEndTime =
              missions[missionIndex].endTime != null
              ? TimeOfDay.fromDateTime(missions[missionIndex].endTime!)
              : null;

          showDialog(
            context: context,
            builder: (dialogContext) {
              return AlertDialog(
                backgroundColor: const Color(0xFF1E1E1E),
                title: const Text(
                  "Edit Structured Time",
                  style: TextStyle(color: Colors.white),
                ),
                content: StatefulBuilder(
                  builder: (context, setDialogState) {
                    return SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: editController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: "Focus Title",
                              labelStyle: TextStyle(color: Colors.grey),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            "Category Allocation",
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          DropdownButton<String>(
                            value: selectedEditCategory,
                            dropdownColor: const Color(0xFF1E1E1E),
                            isExpanded: true,
                            style: const TextStyle(color: Colors.white),
                            items:
                                [
                                  'General',
                                  'Work',
                                  'Study',
                                  'Fitness',
                                  'Sleep',
                                  'Meal',
                                ].map((String val) {
                                  return DropdownMenuItem<String>(
                                    value: val,
                                    child: Text(val),
                                  );
                                }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(
                                  () => selectedEditCategory = val,
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 15),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey[800],
                                  ),
                                  onPressed: () async {
                                    final picked = await showTimePicker(
                                      context: dialogContext,
                                      initialTime:
                                          selectedEditStartTime ??
                                          TimeOfDay.now(),
                                    );
                                    if (picked != null) {
                                      setDialogState(
                                        () => selectedEditStartTime = picked,
                                      );
                                    }
                                  },
                                  child: Text(
                                    selectedEditStartTime == null
                                        ? "Start"
                                        : selectedEditStartTime!.format(
                                            dialogContext,
                                          ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey[800],
                                  ),
                                  onPressed: () async {
                                    final picked = await showTimePicker(
                                      context: dialogContext,
                                      initialTime:
                                          selectedEditEndTime ??
                                          TimeOfDay.now(),
                                    );
                                    if (picked != null) {
                                      setDialogState(
                                        () => selectedEditEndTime = picked,
                                      );
                                    }
                                  },
                                  child: Text(
                                    selectedEditEndTime == null
                                        ? "End"
                                        : selectedEditEndTime!.format(
                                            dialogContext,
                                          ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    onPressed: () {
                      if (editController.text.trim().isNotEmpty) {
                        final baseDate = selectedEditDueDate ?? DateTime.now();
                        setState(() {
                          missions[missionIndex].title = editController.text
                              .trim();
                          missions[missionIndex].category =
                              selectedEditCategory;
                          missions[missionIndex].priority =
                              selectedEditPriority;
                          missions[missionIndex].dueDate = selectedEditDueDate;
                          missions[missionIndex].startTime = _combineDateTime(
                            baseDate,
                            selectedEditStartTime,
                          );
                          missions[missionIndex].endTime = _combineDateTime(
                            baseDate,
                            selectedEditEndTime,
                          );
                        });
                        saveMissions();
                        Navigator.pop(dialogContext);
                      }
                    },
                    child: const Text(
                      "Save",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              );
            },
          );
        },
        onToggle: (id) {
          final missionIndex = missions.indexWhere((m) => m.id == id);
          if (missionIndex == -1) {
            return;
          }

          final wasCompleted = missions[missionIndex].isCompleted;
          setState(() {
            missions[missionIndex].isCompleted =
                !missions[missionIndex].isCompleted;
            if (!wasCompleted && missions[missionIndex].isCompleted) {
              updateStreak();
            }
          });

          if (missions[missionIndex].isCompleted) {
            final messenger = ScaffoldMessenger.of(context);
            messenger.hideCurrentSnackBar();
            messenger.showSnackBar(
              const SnackBar(
                content: Text("Time block completed! 🎉"),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 1),
              ),
            );
          }
          saveMissions();
        },
      );
    }

    if (currentIndex == 1) {
      return HabitScreen(
        habits: habits,
        onAddHabit: (title) {
          setState(() {
            habits.add(Habit(id: uuid.v4(), title: title));
          });
          saveHabits();
        },
        onToggleHabit: (id) {
          final idx = habits.indexWhere((h) => h.id == id);
          if (idx == -1) {
            return;
          }
          setState(() {
            habits[idx].isCompletedToday = !habits[idx].isCompletedToday;
            if (habits[idx].isCompletedToday) {
              habits[idx].streak++;
            } else {
              habits[idx].streak = (habits[idx].streak - 1).clamp(0, 9999);
            }
          });
          saveHabits();
        },
        onDeleteHabit: (id) {
          final habitIndex = habits.indexWhere((h) => h.id == id);
          if (habitIndex == -1) {
            return;
          }

          final messenger = ScaffoldMessenger.of(context);
          deletedHabit = habits[habitIndex];
          deletedHabitIndex = habitIndex;

          setState(() {
            habits.removeAt(habitIndex);
          });
          saveHabits();

          messenger.clearSnackBars();
          messenger.showSnackBar(
            SnackBar(
              content: const Text("Habit deleted"),
              backgroundColor: const Color(0xFF2C2C2C),
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: "UNDO",
                textColor: AppColors.primary,
                onPressed: () {
                  if (deletedHabit != null && deletedHabitIndex != null) {
                    setState(() {
                      habits.insert(deletedHabitIndex!, deletedHabit!);
                    });
                    saveHabits();
                  }
                },
              ),
            ),
          );
        },
      );
    }

    if (currentIndex == 2) {
      return ProfileScreen(
        streak: streak,
        totalMissions: missions.length,
        completedMissions: completedCount,
      );
    }

    if (currentIndex == 3) {
      return StatsScreen(
        missions: missions,
      );
    }

    return const SizedBox();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: AppColors.background,
        body: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : Builder(builder: (context) => getScreenForIndex(context)),
        bottomNavigationBar: BottomNavbar(
          currentIndex: currentIndex,
          onTap: (index) => setState(() => currentIndex = index),
        ),
      ),
    );
  }
}
