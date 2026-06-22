import 'package:shared_preferences/shared_preferences.dart';
import 'block_list_service.dart';

// SharedPreferences keys
const String _kPenalties = 'penalties';
const String _kLockUntil = 'lockUntil';
const String _kStreakKey = 'streak';

class PenaltyService {
  // ─────────────────────────────────────────────
  // APPLY PENALTY
  // Called when user ignores a time block for 30 min
  // 1. Increments penalty count
  // 2. Locks own app for 15 minutes
  // 3. Resets mission streak (no points lost)
  // 4. Blocks distracting apps via zo_app_blocker
  // ─────────────────────────────────────────────
  static Future<void> applyPenalty(String missionId) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Record penalty count
    final penalties = prefs.getInt(_kPenalties) ?? 0;
    await prefs.setInt(_kPenalties, penalties + 1);

    // 2. Lock own app for 15 minutes
    final lockUntil = DateTime.now().add(const Duration(minutes: 15));
    await prefs.setString(_kLockUntil, lockUntil.toIso8601String());

    // 3. Reset streak
    await prefs.setInt(_kStreakKey, 0);

    // 4. Block distracting apps during penalty window
    await BlockListService.blockDistractions();

    debugLog('⛔ PENALTY: App locked until $lockUntil. Streak reset.');
  }

  // ─────────────────────────────────────────────
  // IS APP LOCKED?
  // Also auto-unblocks distracting apps if lock expired
  // ─────────────────────────────────────────────
  static Future<bool> isAppLocked() async {
    final prefs = await SharedPreferences.getInstance();
    final lockUntilStr = prefs.getString(_kLockUntil);

    if (lockUntilStr == null) return false;

    final lockUntil = DateTime.parse(lockUntilStr);
    final isLocked = DateTime.now().isBefore(lockUntil);

    if (!isLocked) {
      // Lock expired — clean up and unblock apps
      await prefs.remove(_kLockUntil);
      await BlockListService.unblockDistractions();
    }

    return isLocked;
  }

  // ─────────────────────────────────────────────
  // GET REMAINING LOCK TIME in seconds
  // Returns -1 if not locked
  // ─────────────────────────────────────────────
  static Future<int> getRemainingLockSeconds() async {
    final prefs = await SharedPreferences.getInstance();
    final lockUntilStr = prefs.getString(_kLockUntil);

    if (lockUntilStr == null) return -1;

    final lockUntil = DateTime.parse(lockUntilStr);
    final remaining = lockUntil.difference(DateTime.now()).inSeconds;

    if (remaining <= 0) {
      await prefs.remove(_kLockUntil);
      await BlockListService.unblockDistractions();
      return -1;
    }

    return remaining;
  }

  // ─────────────────────────────────────────────
  // GET LOCK EXPIRY TIME
  // Returns null if not locked
  // ─────────────────────────────────────────────
  static Future<DateTime?> getLockUntil() async {
    final prefs = await SharedPreferences.getInstance();
    final lockUntilStr = prefs.getString(_kLockUntil);
    if (lockUntilStr == null) return null;
    return DateTime.parse(lockUntilStr);
  }

  // ─────────────────────────────────────────────
  // GET TOTAL PENALTY COUNT
  // ─────────────────────────────────────────────
  static Future<int> getTotalPenalties() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kPenalties) ?? 0;
  }

  // ─────────────────────────────────────────────
  // MANUAL UNLOCK
  // For future use: e.g. completing a challenge
  // unlocks early without resetting streak again
  // ─────────────────────────────────────────────
  static Future<void> unlockNow() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLockUntil);
    await BlockListService.unblockDistractions();
  }

  // ─────────────────────────────────────────────
  // FULL RESET — clears penalties and lock
  // Used in profile screen reset / debug
  // ─────────────────────────────────────────────
  static Future<void> resetPenalties() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kPenalties, 0);
    await prefs.remove(_kLockUntil);
    await BlockListService.unblockAll();
  }

  // ─────────────────────────────────────────────
  // INTERNAL: debug log helper
  // ─────────────────────────────────────────────
  static void debugLog(String message) {
    // ignore: avoid_print
    print(message);
  }
}
