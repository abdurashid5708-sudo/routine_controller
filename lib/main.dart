import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '/models/mission.dart';
import '/models/habit.dart';
import 'package:uuid/uuid.dart';

// Screens & Widgets
import 'screens/home_screen.dart';
import 'screens/habits_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/stats_screen.dart';
import 'widgets/bottom_navbar.dart';
import 'theme/app_colors.dart';

// Services
import 'services/notification_service.dart';
import 'services/penalty_service.dart';
import 'services/time_block_service.dart';
import 'services/block_list_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Init order matters — notifications first, then blocker, then workmanager
  await NotificationService.init();
  await BlockListService.init();
  await TimeBlockService.init();

  runApp(const RoutineControllerApp());
}

class RoutineControllerApp extends StatefulWidget {
  const RoutineControllerApp({super.key});

  @override
  State<RoutineControllerApp> createState() => _RoutineControllerAppState();
}

class _RoutineControllerAppState extends State<RoutineControllerApp>
    with WidgetsBindingObserver {
  List<Mission> missions = [];
  List<Habit> habits = [];
  TextEditingController missionController = TextEditingController();
  int currentIndex = 0;

  // Input field state
  String selectedCategory = 'General';
  String selectedPriority = 'Medium';
  DateTime? selectedDueDate;
  TimeOfDay? selectedStartTime;
  TimeOfDay? selectedEndTime;

  String selectedCategoryFilter = 'All';
  int streak = 0;
  DateTime? lastCompletedDate;
  bool isLoading = true;

  // Lock state
  bool isAppLocked = false;
  int lockTimeRemaining = 0;
  DateTime? lockUntil;

  // Permission state
  bool _hasBlockPermissions = false;
  bool _permissionBannerDismissed = false;

  // Undo state
  Mission? deletedMission;
  int? deletedMissionIndex;
  Habit? deletedHabit;
  int? deletedHabitIndex;

  final uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    loadAppData();
    _checkLockStatus();
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    missionController.dispose();
    super.dispose();
  }

  // Re-check lock when app comes back to foreground
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkLockStatus();
    }
  }

  // ─────────────────────────────────────────────
  // LOCK STATUS — polls every second while locked
  // ─────────────────────────────────────────────
  Future<void> _checkLockStatus() async {
    final locked = await PenaltyService.isAppLocked();
    final remaining = await PenaltyService.getRemainingLockSeconds();
    final until = await PenaltyService.getLockUntil();

    if (mounted) {
      setState(() {
        isAppLocked = locked;
        lockTimeRemaining = remaining > 0 ? remaining : 0;
        lockUntil = until;
      });
    }

    if (locked) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) _checkLockStatus();
    }
  }

  // ─────────────────────────────────────────────
  // PERMISSION CHECK
  // Shows banner if zo_app_blocker permissions not granted
  // ─────────────────────────────────────────────
  Future<void> _checkPermissions() async {
    final hasPerms = await BlockListService.hasRequiredPermissions();
    if (mounted) {
      setState(() => _hasBlockPermissions = hasPerms);
    }
  }

  // ─────────────────────────────────────────────
  // COMPUTED PROPERTIES
  // ─────────────────────────────────────────────
  int get overdueCount => missions
      .where(
        (m) =>
            m.dueDate != null &&
            m.dueDate!.isBefore(DateTime.now()) &&
            !m.isCompleted,
      )
      .length;

  int get dueTodayCount {
    final today = DateTime.now();
    return missions
        .where(
          (m) =>
              m.dueDate != null &&
              m.dueDate!.year == today.year &&
              m.dueDate!.month == today.month &&
              m.dueDate!.day == today.day,
        )
        .length;
  }

  int get highPriorityCount =>
      missions.where((m) => m.priority == 'High' && !m.isCompleted).length;

  int get completedCount => missions.where((m) => m.isCompleted).length;

  List<Mission> get categoryFilteredMissions {
    if (selectedCategoryFilter == 'All') return missions;
    return missions.where((m) => m.category == selectedCategoryFilter).toList();
  }

  // ─────────────────────────────────────────────
  // STREAK
  // ─────────────────────────────────────────────
  void updateStreak() {
    if (missions.isEmpty || completedCount != missions.length) return;
    final today = DateTime.now();
    if (lastCompletedDate == null) {
      streak = 1;
      lastCompletedDate = today;
      return;
    }
    final diff = today.difference(lastCompletedDate!).inDays;
    if (diff == 0) return;
    streak = diff == 1 ? streak + 1 : 1;
    lastCompletedDate = today;
  }

  // ─────────────────────────────────────────────
  // LOAD APP DATA
  // ─────────────────────────────────────────────
  Future<void> loadAppData() async {
    final prefs = await SharedPreferences.getInstance();

    streak = prefs.getInt('streak') ?? 0;
    final savedDate = prefs.getString('lastCompletedDate');
    if (savedDate != null) lastCompletedDate = DateTime.parse(savedDate);

    final missionList = prefs.getStringList('missions');
    if (missionList != null) {
      missions = missionList
          .map((m) => Mission.fromJson(jsonDecode(m)))
          .toList();
    }

    // Habits + midnight reset
    final habitList = prefs.getStringList('habits');
    final lastHabitCheckStr = prefs.getString('lastHabitCheckDate');
    final today = DateTime.now();
    bool isNewDay = false;

    if (lastHabitCheckStr != null) {
      final lastCheck = DateTime.parse(lastHabitCheckStr);
      isNewDay =
          lastCheck.year != today.year ||
          lastCheck.month != today.month ||
          lastCheck.day != today.day;
    } else {
      isNewDay = true;
    }

    if (habitList != null) {
      habits = habitList.map((h) {
        final habit = Habit.fromJson(jsonDecode(h));
        if (isNewDay) {
          if (!habit.isCompletedToday) habit.streak = 0;
          habit.isCompletedToday = false;
        }
        return habit;
      }).toList();
    }

    if (isNewDay) {
      await prefs.setString('lastHabitCheckDate', today.toIso8601String());
      await prefs.setStringList(
        'habits',
        habits.map((h) => jsonEncode(h.toJson())).toList(),
      );
    }

    // Re-register monitoring for any missions that have a future start time
    // (covers case where app was killed and restarted)
    for (final mission in missions) {
      if (!mission.isCompleted && mission.startTime != null) {
        final isInFuture = mission.startTime!.isAfter(DateTime.now());
        final isWithinWindow =
            DateTime.now().difference(mission.startTime!).inMinutes < 30;
        if (isInFuture || isWithinWindow) {
          _startMonitoringMission(mission);
        }
      }
    }

    if (mounted) setState(() => isLoading = false);
  }

  // ─────────────────────────────────────────────
  // SAVE MISSIONS
  // ─────────────────────────────────────────────
  Future<void> saveMissions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'missions',
      missions.map((m) => jsonEncode(m.toJson())).toList(),
    );
    await prefs.setInt('streak', streak);
    if (lastCompletedDate != null) {
      await prefs.setString(
        'lastCompletedDate',
        lastCompletedDate!.toIso8601String(),
      );
    }
  }

  // ─────────────────────────────────────────────
  // SAVE HABITS
  // ─────────────────────────────────────────────
  Future<void> saveHabits() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'habits',
      habits.map((h) => jsonEncode(h.toJson())).toList(),
    );
  }

  // ─────────────────────────────────────────────
  // COMBINE DATE + TIME
  // ─────────────────────────────────────────────
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

  // ─────────────────────────────────────────────
  // START MONITORING a mission's time block
  // Wires mission into notification + penalty system
  // ─────────────────────────────────────────────
  void _startMonitoringMission(Mission mission) {
    if (mission.startTime == null) return;
    TimeBlockService.startTimeBlockMonitoring(
      missionId: mission.id,
      missionTitle: mission.title,
      startTime: mission.startTime!,
    );
  }

  // ─────────────────────────────────────────────
  // ADD MISSION
  // ─────────────────────────────────────────────
  void _addNewMissionFromInputs() {
    if (missionController.text.trim().isEmpty) return;

    final baseDate = selectedDueDate ?? DateTime.now();
    final parsedStart = _combineDateTime(baseDate, selectedStartTime);
    final parsedEnd = _combineDateTime(baseDate, selectedEndTime);

    final newMission = Mission(
      id: uuid.v4(),
      title: missionController.text.trim(),
      category: selectedCategory,
      dueDate: selectedDueDate,
      priority: selectedPriority,
      startTime: parsedStart,
      endTime: parsedEnd,
    );

    setState(() => missions.add(newMission));

    // Wire into time block monitoring if start time is set
    if (parsedStart != null) {
      _startMonitoringMission(newMission);
    }

    missionController.clear();
    selectedPriority = 'Medium';
    selectedDueDate = null;
    selectedStartTime = null;
    selectedEndTime = null;
    saveMissions();
    FocusScope.of(context).unfocus();
  }

  // ─────────────────────────────────────────────
  // PERMISSION BANNER
  // Shown when zo_app_blocker permissions not granted
  // ─────────────────────────────────────────────
  Widget _buildPermissionBanner() {
    if (_hasBlockPermissions || _permissionBannerDismissed) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
              SizedBox(width: 8),
              Text(
                'App Blocking Not Active',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Grant permissions to block Instagram, TikTok & others during your time blocks.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    await BlockListService.requestUsageStatsPermission();
                    await Future.delayed(const Duration(seconds: 1));
                    await BlockListService.requestOverlayPermission();
                    await _checkPermissions();
                  },
                  child: const Text(
                    'Grant Permissions',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () =>
                    setState(() => _permissionBannerDismissed = true),
                child: const Text(
                  'Dismiss',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // LOCK SCREEN
  // ─────────────────────────────────────────────
  Widget _buildLockScreen() {
    final mins = lockTimeRemaining ~/ 60;
    final secs = (lockTimeRemaining % 60).toString().padLeft(2, '0');

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      size: 54,
                      color: Colors.redAccent,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'APP LOCKED',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'You ignored your scheduled\ntime block.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Streak has been reset. 🔴',
                    style: TextStyle(color: Colors.orange, fontSize: 14),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '$mins:$secs',
                      style: const TextStyle(
                        color: Colors.yellowAccent,
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'until unlocked',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // SCREEN ROUTER
  // ─────────────────────────────────────────────
  Widget getScreenForIndex(BuildContext context) {
    if (currentIndex == 0) {
      return HomeScreen(
        streak: streak,
        overdueCount: overdueCount,
        dueTodayCount: dueTodayCount,
        highPriorityCount: highPriorityCount,
        missions: categoryFilteredMissions,
        selectedPriority: selectedPriority,
        onPriorityChanged: (p) => setState(() => selectedPriority = p),
        selectedCategory: selectedCategory,
        selectedCategoryFilter: selectedCategoryFilter,
        onCategoryFilterChanged: (c) =>
            setState(() => selectedCategoryFilter = c),
        onCategoryChanged: (c) => setState(() => selectedCategory = c),
        totalMissionCount: missions.length,
        completedCount: completedCount,
        missionController: missionController,
        selectedStartTime: selectedStartTime,
        selectedEndTime: selectedEndTime,
        onStartTimeChanged: (t) => setState(() => selectedStartTime = t),
        onEndTimeChanged: (t) => setState(() => selectedEndTime = t),
        onAddMission: _addNewMissionFromInputs,
        onSubmitted: (_) => _addNewMissionFromInputs(),
        onDelete: (id) {
          final idx = missions.indexWhere((m) => m.id == id);
          if (idx == -1) return;

          // Stop monitoring this mission's time block
          TimeBlockService.stopTimeBlockMonitoring(id);

          final messenger = ScaffoldMessenger.of(context);
          deletedMission = missions[idx];
          deletedMissionIndex = idx;

          setState(() => missions.removeAt(idx));
          saveMissions();

          messenger.clearSnackBars();
          messenger.showSnackBar(
            SnackBar(
              content: const Text('Mission deleted'),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'UNDO',
                textColor: Colors.white,
                onPressed: () {
                  if (deletedMission != null && deletedMissionIndex != null) {
                    setState(
                      () => missions.insert(
                        deletedMissionIndex!,
                        deletedMission!,
                      ),
                    );
                    // Re-register monitoring if it had a start time
                    if (deletedMission!.startTime != null) {
                      _startMonitoringMission(deletedMission!);
                    }
                    saveMissions();
                  }
                },
              ),
            ),
          );
        },
        onEdit: (id) async {
          final idx = missions.indexWhere((m) => m.id == id);
          if (idx == -1) return;

          final editController = TextEditingController(
            text: missions[idx].title,
          );
          String selectedEditCategory = missions[idx].category;
          String selectedEditPriority = missions[idx].priority;
          DateTime? selectedEditDueDate = missions[idx].dueDate;
          TimeOfDay? selectedEditStartTime = missions[idx].startTime != null
              ? TimeOfDay.fromDateTime(missions[idx].startTime!)
              : null;
          TimeOfDay? selectedEditEndTime = missions[idx].endTime != null
              ? TimeOfDay.fromDateTime(missions[idx].endTime!)
              : null;

          showDialog(
            context: context,
            builder: (dialogContext) {
              return AlertDialog(
                backgroundColor: const Color(0xFF1E1E1E),
                title: const Text(
                  'Edit Structured Time',
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
                              labelText: 'Focus Title',
                              labelStyle: TextStyle(color: Colors.grey),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Category Allocation',
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
                                    ]
                                    .map(
                                      (v) => DropdownMenuItem(
                                        value: v,
                                        child: Text(v),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setDialogState(() => selectedEditCategory = v);
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
                                        ? 'Start'
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
                                        ? 'End'
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
                      'Cancel',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    onPressed: () {
                      if (editController.text.trim().isEmpty) return;

                      final baseDate = selectedEditDueDate ?? DateTime.now();
                      final newStart = _combineDateTime(
                        baseDate,
                        selectedEditStartTime,
                      );
                      final newEnd = _combineDateTime(
                        baseDate,
                        selectedEditEndTime,
                      );

                      // Cancel old monitoring before updating
                      TimeBlockService.stopTimeBlockMonitoring(
                        missions[idx].id,
                      );

                      setState(() {
                        missions[idx].title = editController.text.trim();
                        missions[idx].category = selectedEditCategory;
                        missions[idx].priority = selectedEditPriority;
                        missions[idx].dueDate = selectedEditDueDate;
                        missions[idx].startTime = newStart;
                        missions[idx].endTime = newEnd;
                      });

                      // Re-register monitoring with updated start time
                      if (newStart != null && !missions[idx].isCompleted) {
                        _startMonitoringMission(missions[idx]);
                      }

                      saveMissions();
                      Navigator.pop(dialogContext);
                    },
                    child: const Text(
                      'Save',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              );
            },
          );
        },
        onToggle: (id) {
          final idx = missions.indexWhere((m) => m.id == id);
          if (idx == -1) return;

          final wasCompleted = missions[idx].isCompleted;

          setState(() {
            missions[idx].isCompleted = !missions[idx].isCompleted;
            if (!wasCompleted && missions[idx].isCompleted) {
              updateStreak();
            }
          });

          if (missions[idx].isCompleted) {
            // Mark started + stop monitoring + unblock apps
            TimeBlockService.markTimeBlockStarted(id);
            BlockListService.unblockDistractions();

            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                const SnackBar(
                  content: Text('Time block completed! 🎉'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 1),
                ),
              );
          } else {
            // Uncompleting — restart monitoring if still within window
            if (missions[idx].startTime != null) {
              _startMonitoringMission(missions[idx]);
            }
          }

          saveMissions();
        },
      );
    }

    if (currentIndex == 1) {
      return HabitScreen(
        habits: habits,
        onAddHabit: (title) {
          setState(() => habits.add(Habit(id: uuid.v4(), title: title)));
          saveHabits();
        },
        onToggleHabit: (id) {
          final idx = habits.indexWhere((h) => h.id == id);
          if (idx == -1) return;
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
          final idx = habits.indexWhere((h) => h.id == id);
          if (idx == -1) return;

          final messenger = ScaffoldMessenger.of(context);
          deletedHabit = habits[idx];
          deletedHabitIndex = idx;

          setState(() => habits.removeAt(idx));
          saveHabits();

          messenger.clearSnackBars();
          messenger.showSnackBar(
            SnackBar(
              content: const Text('Habit deleted'),
              backgroundColor: const Color(0xFF2C2C2C),
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'UNDO',
                textColor: AppColors.primary,
                onPressed: () {
                  if (deletedHabit != null && deletedHabitIndex != null) {
                    setState(
                      () => habits.insert(deletedHabitIndex!, deletedHabit!),
                    );
                    saveHabits();
                  }
                },
              ),
            ),
          );
        },
      );
    }

    if (currentIndex == 2) return StatsScreen(missions: missions);

    if (currentIndex == 3) {
      return ProfileScreen(
        streak: streak,
        totalMissions: missions.length,
        completedMissions: completedCount,
      );
    }

    return const SizedBox();
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // Show lock screen when app is locked
    if (isAppLocked && lockTimeRemaining > 0) {
      return _buildLockScreen();
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: AppColors.background,
        body: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : Column(
                children: [
                  // Permission banner — shown until granted or dismissed
                  _buildPermissionBanner(),
                  Expanded(
                    child: Builder(builder: (ctx) => getScreenForIndex(ctx)),
                  ),
                ],
              ),
        bottomNavigationBar: BottomNavbar(
          currentIndex: currentIndex,
          onTap: (index) => setState(() => currentIndex = index),
        ),
      ),
    );
  }
}
