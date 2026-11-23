import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'hive_service.dart';

/// Offline replacement for crash reporting: nothing leaves the phone.
///
/// On start, asks Android why the app last died. If it was a crash, shows the
/// reason once, so the user can screenshot it for debugging.
class CrashNotice {
  static const _channel = MethodChannel('com.aichat.ai_chat/model_import');
  static const _seenKey = 'last_exit_seen_timestamp';

  static Future<void> showIfCrashed() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final raw = await _channel.invokeMethod<dynamic>('lastExitInfo');
      if (raw is! Map) return;
      final info = Map<String, dynamic>.from(raw);
      final reason = '${info['reason'] ?? ''}';
      final ts = (info['timestamp'] as num?)?.toInt() ?? 0;

      final hive = Get.find<HiveService>();
      final seen = hive.getSetting<int>(_seenKey) ?? 0;
      if (ts <= seen) return;
      await hive.setSetting(_seenKey, ts);

      const crashReasons = {
        'crash',
        'native_crash',
        'anr',
        'low_memory',
        'signaled',
        'excessive_resource',
      };
      if (!crashReasons.contains(reason)) return;

      final when = DateTime.fromMillisecondsSinceEpoch(ts);
      final rssMb = ((info['rss'] as num?)?.toInt() ?? 0) ~/ 1024;
      final text = StringBuffer()
        ..writeln('Reason: $reason')
        ..writeln('Time: $when')
        ..writeln('Memory (RSS): $rssMb MB')
        ..writeln('Status: ${info['status']}')
        ..writeln('Description: ${info['description']}')
        ..writeln()
        ..writeln('${info['trace'] ?? ''}');
      print('[CrashNotice] Last exit: $text');

      await Get.dialog(
        AlertDialog(
          title: const Text('The app closed unexpectedly last time'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: SelectableText(
                text.toString(),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Clipboard.setData(ClipboardData(text: text.toString())),
              child: const Text('Copy'),
            ),
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('[CrashNotice] unavailable: $e');
    }
  }
}
