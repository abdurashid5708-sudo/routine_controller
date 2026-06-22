import 'package:flutter/material.dart';
import 'package:zo_app_blocker/zo_app_blocker.dart';

// ─────────────────────────────────────────────────────────────
// BLOCK SCREEN CALLBACK — must be a TOP-LEVEL function
// zo_app_blocker runs this in a separate isolate when a blocked
// app is detected, even if the main app is fully closed
// ─────────────────────────────────────────────────────────────
@pragma('vm:entry-point')
void onBlockScreenRequested() {
  ZoBlockScreenRunner.run(
    // BlockScreenContext is passed directly by the runner — no of(context)
    builder: (blockCtx) => _BlockScreen(blockCtx: blockCtx),
  );
}

// ─────────────────────────────────────────────────────────────
// BLOCK LIST SERVICE
// ─────────────────────────────────────────────────────────────
class BlockListService {
  // ─────────────────────────────────────────────
  // APPS TO BLOCK during active time blocks
  // ─────────────────────────────────────────────
  static const List<String> blockedApps = [
    'com.instagram.android',
    'com.facebook.katana',
    'com.zhiliaoapp.musically', // TikTok
    'com.google.android.youtube',
    'com.iMe.android',
    'org.telegram.messenger',
  ];

  // ─────────────────────────────────────────────
  // INIT — call once in main() before runApp()
  // ─────────────────────────────────────────────
  static Future<void> init() async {
    await ZoAppBlocker.instance.initialize(
      blockScreenCallback: onBlockScreenRequested, // top-level function
    );

    await ZoAppBlocker.instance.setNotificationConfig(
      notificationBannerTitle: 'Focus Mode Active 🔒',
      notificationBannerDescription:
          'Distracting apps are blocked during your time block.',
    );
  }

  // ─────────────────────────────────────────────
  // BLOCK — call when a time block starts
  // ─────────────────────────────────────────────
  static Future<void> blockDistractions() async {
    try {
      final hasPerms = await hasRequiredPermissions();
      if (!hasPerms) return; // permissions handled in onboarding flow

      await ZoAppBlocker.instance.blockApps(blockedApps);
    } catch (e) {
      // Fail silently — core penalty system still works without app blocking
      debugPrint('BlockListService.blockDistractions error: $e');
    }
  }

  // ─────────────────────────────────────────────
  // UNBLOCK — call when time block ends or mission is marked done
  // ─────────────────────────────────────────────
  static Future<void> unblockDistractions() async {
    try {
      await ZoAppBlocker.instance.unblockApps(blockedApps);
    } catch (e) {
      debugPrint('BlockListService.unblockDistractions error: $e');
    }
  }

  // ─────────────────────────────────────────────
  // UNBLOCK ALL — safety reset (penalty expires / manual reset)
  // ─────────────────────────────────────────────
  static Future<void> unblockAll() async {
    try {
      await ZoAppBlocker.instance.unblockAll();
    } catch (e) {
      debugPrint('BlockListService.unblockAll error: $e');
    }
  }

  // ─────────────────────────────────────────────
  // CHECK PERMISSIONS
  // ─────────────────────────────────────────────
  static Future<bool> hasRequiredPermissions() async {
    try {
      final usageStatus = await ZoAppBlocker.instance
          .checkUsageStatsPermission();
      final overlayStatus = await ZoAppBlocker.instance
          .checkOverlayPermission();
      return usageStatus == 'granted' && overlayStatus == 'granted';
    } catch (e) {
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // REQUEST PERMISSIONS — opens Android settings
  // ─────────────────────────────────────────────
  static Future<void> requestUsageStatsPermission() async {
    await ZoAppBlocker.instance.requestUsageStatsPermission();
  }

  static Future<void> requestOverlayPermission() async {
    await ZoAppBlocker.instance.requestOverlayPermission();
  }
}

// ─────────────────────────────────────────────────────────────
// BLOCK SCREEN WIDGET
// Shown as overlay when user tries to open a blocked app
// Receives BlockScreenContext directly from ZoBlockScreenRunner
// ─────────────────────────────────────────────────────────────
class _BlockScreen extends StatelessWidget {
  final BlockScreenContext blockCtx;

  const _BlockScreen({required this.blockCtx});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App icon if available
                if (blockCtx.appIcon != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.memory(
                      blockCtx.appIcon!,
                      width: 72,
                      height: 72,
                    ),
                  ),
                  const SizedBox(height: 24),
                ] else ...[
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
                  const SizedBox(height: 32),
                ],

                const Text(
                  'FOCUS MODE',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 12),

                Text(
                  blockCtx.appName != null
                      ? '${blockCtx.appName} is blocked'
                      : 'This app is blocked',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                const Text(
                  'You have an active time block running.\nFinish your work first.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 15,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Dismiss button — uses onDismiss callback from BlockScreenContext
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: blockCtx.onDismiss, // correct API
                    child: const Text(
                      'Go Back to Work',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
