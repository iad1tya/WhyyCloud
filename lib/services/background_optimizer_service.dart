import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:disable_battery_optimization/disable_battery_optimization.dart';

/// Checks and prompts the user to disable battery optimization on Android.
/// This is critical on Samsung and other aggressive OEMs that kill background apps.
class BackgroundOptimizerService {
  static const _promptedKey = 'battery_opt_prompted';

  /// Check and prompt the user if battery optimization is still enabled.
  /// Shows a dialog explaining why it's needed, then opens system settings.
  /// Only prompts on Android, and only once per install (unless optimization
  /// is still enabled).
  static Future<void> checkAndPrompt(BuildContext context) async {
    if (!Platform.isAndroid) return;

    try {
      final box = Hive.box('settings');

      // Check if battery optimization is already disabled for our app
      final isDisabled =
          await DisableBatteryOptimization.isBatteryOptimizationDisabled;

      if (isDisabled == true) return; // Already good

      // Check if we've already prompted the user
      final alreadyPrompted =
          box.get(_promptedKey, defaultValue: false) as bool;
      if (alreadyPrompted) return; // Don't nag

      // Mark as prompted
      await box.put(_promptedKey, true);

      if (!context.mounted) return;

      // Show explanation dialog — redesigned with white accent instead of orange
      final shouldOpen = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          final theme = Theme.of(ctx);
          return AlertDialog(
            backgroundColor: theme.scaffoldBackgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Background Permission',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.titleLarge?.color,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This app needs to run in the background to:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 12),
                const _BulletPoint(
                  'Continue model downloads when the screen is off',
                ),
                const SizedBox(height: 6),
                const _BulletPoint(
                  'Keep AI inference running without interruption',
                ),
                const SizedBox(height: 6),
                const _BulletPoint('Serve the local API to other apps'),
                const SizedBox(height: 16),
                Text(
                  'Please disable battery optimization for this app on the next screen.',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  'Later',
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Open Settings',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ],
          );
        },
      );

      if (shouldOpen == true) {
        await DisableBatteryOptimization.showDisableBatteryOptimizationSettings();
      }
    } catch (e) {
      debugPrint('BackgroundOptimizerService error: $e');
    }
  }

  /// Re-prompt the user (e.g. from settings). Always shows regardless of
  /// previous prompts.
  static Future<void> openBatterySettings() async {
    if (!Platform.isAndroid) return;
    try {
      await DisableBatteryOptimization.showDisableBatteryOptimizationSettings();
    } catch (e) {
      debugPrint('BackgroundOptimizerService.openBatterySettings error: $e');
    }
  }

  /// Check if battery optimization is currently disabled.
  static Future<bool> isOptimizationDisabled() async {
    if (!Platform.isAndroid) return true;
    try {
      return await DisableBatteryOptimization.isBatteryOptimizationDisabled ??
          false;
    } catch (_) {
      return false;
    }
  }
}

class _BulletPoint extends StatelessWidget {
  final String text;
  const _BulletPoint(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 6, right: 8),
          child: Icon(
            Icons.check_circle_outline,
            size: 16,
            color: Colors.green,
          ),
        ),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
      ],
    );
  }
}
