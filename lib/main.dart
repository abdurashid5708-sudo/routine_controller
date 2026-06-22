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
import 'services/device_service.dart';

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
  bool _batteryOptEnabled = false;
  bool _notificationsDisabled = false;
  bool _noExactAlarmPermission = false;

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

  // Re-check lock + permissions when app comes back to foreground
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkLockStatus();
      _checkPermissions();
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
  // Shows banner if zo_app_blocker / battery / notification issues
  // ─────────────────────────────────────────────
  Future<void> _checkPermissions() async {
    final results = await Future.wait([
      BlockListService.hasRequiredPermissions(),
      DeviceService.isBatteryOptimizationEnabled(),
      DeviceService.areNotificationsEnabled(),
      DeviceService.hasExactAlarmPermission(),
    ]);
    if (mounted) {
      setState(() {
        _hasBlockPermissions = results[0];
        _batteryOptEnabled = results[1];
        _notificationsDisabled = !results[2];
        _noExactAlarmPermission = !results[3];
      });
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
  void _addMission(
    String title,
    String category,
    String priority,
    DateTime? dueDate,
    TimeOfDay? start,
    TimeOfDay? end,
  ) {
    final baseDate = dueDate ?? DateTime.now();
    final parsedStart = _combineDateTime(baseDate, start);
    final parsedEnd = _combineDateTime(baseDate, end);
    final effectiveStart =
        parsedStart ??
        (dueDate != null
            ? DateTime(dueDate.year, dueDate.month, dueDate.day, 9, 0)
            : null);

    final newMission = Mission(
      id: uuid.v4(),
      title: title,
      category: category,
      dueDate: dueDate,
      priority: priority,
      startTime: effectiveStart,
      endTime: parsedEnd,
    );

    setState(() => missions.add(newMission));

    if (effectiveStart != null) {
      _startMonitoringMission(newMission);
    }

    saveMissions();
    FocusScope.of(context).unfocus();
  }

  // ─────────────────────────────────────────────
  // SETTINGS BANNERS
  // Shows warnings for battery opt / notification / block permissions
  // ─────────────────────────────────────────────
  Widget _buildPermissionBanner() {
    final issues = <Widget>[];

    if (_batteryOptEnabled && !_permissionBannerDismissed) {
      issues.add(
        _settingsRow(
          icon: Icons.battery_alert_rounded,
          message:
              'Battery optimization may delay notifications. Disable it for reliable alerts.',
          buttonLabel: 'Disable',
          onPressed: () async {
            await DeviceService.openBatteryOptimizationSettings();
            await Future.delayed(const Duration(seconds: 2));
            await _checkPermissions();
          },
        ),
      );
    }

    if (_notificationsDisabled && !_permissionBannerDismissed) {
      issues.add(
        _settingsRow(
          icon: Icons.notifications_off_rounded,
          message:
              'Notifications are disabled. Enable them to get time block reminders.',
          buttonLabel: 'Open Settings',
          onPressed: () async {
            await DeviceService.openNotificationSettings();
            await Future.delayed(const Duration(seconds: 2));
            await _checkPermissions();
          },
        ),
      );
    }

    if (_noExactAlarmPermission && !_permissionBannerDismissed) {
      issues.add(
        _settingsRow(
          icon: Icons.timer_off_rounded,
          message:
              'Exact alarm permission not granted. Notifications may arrive late or not at all.',
          buttonLabel: 'Grant',
          onPressed: () async {
            await DeviceService.requestExactAlarmPermission();
            await Future.delayed(const Duration(seconds: 2));
            await _checkPermissions();
          },
        ),
      );
    }

    if (!_hasBlockPermissions && !_permissionBannerDismissed) {
      issues.add(
        _settingsRow(
          icon: Icons.warning_amber_rounded,
          message:
              'Grant permissions to block Instagram, TikTok & others during your time blocks.',
          buttonLabel: 'Grant Permissions',
          onPressed: () async {
            await BlockListService.requestUsageStatsPermission();
            await Future.delayed(const Duration(seconds: 1));
            await BlockListService.requestOverlayPermission();
            await _checkPermissions();
          },
        ),
      );
    }

    if (issues.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ...issues,
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () =>
                  setState(() => _permissionBannerDismissed = true),
              child: const Text(
                'Dismiss All',
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsRow({
    required IconData icon,
    required String message,
    required String buttonLabel,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.orange, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                height: 32,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: onPressed,
                  child: Text(
                    buttonLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
        selectedCategoryFilter: selectedCategoryFilter,
        onCategoryFilterChanged: (c) =>
            setState(() => selectedCategoryFilter = c),
        totalMissionCount: missions.length,
        completedCount: completedCount,
        missionController: missionController,
        onAddMission: _addMission,
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
                            items: ['General', 'Work', 'Study', 'Fitness']
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
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.surface,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          onPrimary: AppColors.onPrimary,
          primaryContainer: AppColors.primaryContainer,
          onPrimaryContainer: AppColors.onPrimaryContainer,
          secondary: AppColors.secondary,
          onSecondary: AppColors.onSecondary,
          secondaryContainer: AppColors.secondaryContainer,
          onSecondaryContainer: AppColors.onSecondaryContainer,
          tertiary: AppColors.tertiary,
          error: AppColors.error,
          errorContainer: AppColors.errorContainer,
          surface: AppColors.surface,
          onSurface: AppColors.onSurface,
          onSurfaceVariant: AppColors.onSurfaceVariant,
          outline: AppColors.outline,
          outlineVariant: AppColors.outlineVariant,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontFamily: 'Inter',
            fontSize: 32,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.02,
            color: AppColors.onSurface,
          ),
          headlineMedium: TextStyle(
            fontFamily: 'Inter',
            fontSize: 24,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.01,
            color: AppColors.onSurface,
          ),
          headlineSmall: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
          bodyLarge: TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: AppColors.onSurface,
          ),
          bodyMedium: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.onSurface,
          ),
          labelLarge: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.05,
            color: AppColors.onSurface,
          ),
          labelSmall: TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.08,
            color: AppColors.onSurface,
          ),
        ),
      ),
      home: Scaffold(
        backgroundColor: AppColors.background,
        body: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : Column(
                children: [
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
