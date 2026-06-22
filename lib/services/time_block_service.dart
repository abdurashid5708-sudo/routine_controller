import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'notification_service.dart';
import 'penalty_service.dart';
import 'block_list_service.dart';

// ─────────────────────────────────────────────────────────────
// BACKGROUND TASK NAME — must match callbackDispatcher in main.dart
// ─────────────────────────────────────────────────────────────
const String kPenaltyCheckTask = 'penaltyCheck';

// ─────────────────────────────────────────────────────────────
// BACKGROUND DISPATCHER — top-level function, required by workmanager
// Must be annotated with @pragma so it survives Flutter tree-shaking
// ─────────────────────────────────────────────────────────────
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName == kPenaltyCheckTask) {
      final missionId = inputData?['missionId'] as String?;
      final missionTitle = inputData?['missionTitle'] as String?;

      if (missionId == null || missionTitle == null) return true;

      // Check if user already started the block
      final started = await TimeBlockService.isTimeBlockStarted(missionId);
      if (!started) {
        // Apply penalty — lock app + reset streak
        await PenaltyService.applyPenalty(missionId);

        // Show lock notification (instant, fires from background)
        await NotificationService.init();
        await NotificationService.showInstant(
          id: 9999,
          title: '⛔ APP LOCKED',
          body: 'You ignored "$missionTitle". Streak reset! 🔴',
          urgent: true,
        );
      }
    }
    return true;
  });
}

// ─────────────────────────────────────────────────────────────
// TIME BLOCK SERVICE
// ─────────────────────────────────────────────────────────────
class TimeBlockService {
  /// Initialize workmanager — call once in main() before runApp()
  static Future<void> init() async {
    await Workmanager().initialize(callbackDispatcher);
  }

  // ─────────────────────────────────────────────
  // START MONITORING a time block
  // Schedules OS notifications + background penalty check
  // ─────────────────────────────────────────────
  static Future<void> startTimeBlockMonitoring({
    required String missionId,
    required String missionTitle,
    required DateTime startTime,
  }) async {
    // Cancel any previous monitoring for this mission
    await stopTimeBlockMonitoring(missionId);

    // Schedule the 4 escalating notifications via OS
    await NotificationService.scheduleEscalatingNotifications(
      missionId: missionId,
      missionTitle: missionTitle,
      startTime: startTime,
    );

    // Block distracting apps only if the mission is for today
    final now = DateTime.now();
    final isToday =
        startTime.year == now.year &&
        startTime.month == now.month &&
        startTime.day == now.day;
    if (isToday) {
      await BlockListService.blockDistractions();
    }

    // Schedule background penalty check 30 min after start
    // workmanager will run this even if the app is fully closed
    final penaltyTime = startTime.add(const Duration(minutes: 30));
    final delayUntilPenalty = penaltyTime.difference(DateTime.now());

    if (delayUntilPenalty.isNegative) {
      // Start time already passed — check immediately if not started
      final started = await isTimeBlockStarted(missionId);
      if (!started) {
        await PenaltyService.applyPenalty(missionId);
        await NotificationService.showInstant(
          id: 9999,
          title: '⛔ APP LOCKED',
          body: 'You ignored "$missionTitle". Streak reset! 🔴',
          urgent: true,
        );
      }
      return;
    }

    await Workmanager().registerOneOffTask(
      'penalty_$missionId', // unique task name
      kPenaltyCheckTask, // task identifier for dispatcher
      initialDelay: delayUntilPenalty,
      inputData: {'missionId': missionId, 'missionTitle': missionTitle},
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }

  // ─────────────────────────────────────────────
  // MARK AS STARTED — user tapped "I'm doing it!"
  // Cancels penalty check + all reminder notifications
  // ─────────────────────────────────────────────
  static Future<void> markTimeBlockStarted(String missionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'started_$missionId',
      DateTime.now().toIso8601String(),
    );
    await stopTimeBlockMonitoring(missionId);
  }

  // ─────────────────────────────────────────────
  // MARK AS COMPLETED — user toggled mission done
  // Same as started but clears the started flag too
  // ─────────────────────────────────────────────
  static Future<void> markTimeBlockCompleted(String missionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('started_$missionId');
    await stopTimeBlockMonitoring(missionId);
  }

  // ─────────────────────────────────────────────
  // STOP MONITORING — cancel both notifications and
  // the background workmanager penalty task
  // ─────────────────────────────────────────────
  static Future<void> stopTimeBlockMonitoring(String missionId) async {
    // Cancel OS-scheduled notifications
    await NotificationService.cancelMissionNotifications(missionId);

    // Cancel background penalty task
    await Workmanager().cancelByUniqueName('penalty_$missionId');
  }

  // ─────────────────────────────────────────────
  // CHECK: has user marked this block as started?
  // ─────────────────────────────────────────────
  static Future<bool> isTimeBlockStarted(String missionId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('started_$missionId');
  }

  // ─────────────────────────────────────────────
  // GET STATUS of a time block right now
  // ─────────────────────────────────────────────
  static Future<TimeBlockStatus> getTimeBlockStatus({
    required String missionId,
    required DateTime startTime,
  }) async {
    final now = DateTime.now();
    final minutesSinceStart = now.difference(startTime).inMinutes;
    final isStarted = await isTimeBlockStarted(missionId);
    final isLocked = await PenaltyService.isAppLocked();

    if (isLocked) return TimeBlockStatus.locked;
    if (isStarted) return TimeBlockStatus.inProgress;
    if (minutesSinceStart < 0 && minutesSinceStart >= -5) {
      return TimeBlockStatus.aboutToStart;
    }
    if (minutesSinceStart >= 0 && minutesSinceStart < 30) {
      return TimeBlockStatus.ignoring;
    }
    return TimeBlockStatus.notStarted;
  }
}

// ─────────────────────────────────────────────────────────────
// TIME BLOCK STATUS ENUM
// ─────────────────────────────────────────────────────────────
enum TimeBlockStatus {
  notStarted, // Block hasn't started yet (>5 min away)
  aboutToStart, // Less than 5 min until start
  ignoring, // Block started but user hasn't tapped "I'm doing it"
  inProgress, // User tapped "I'm doing it!"
  locked, // Penalty applied — app is locked
}
