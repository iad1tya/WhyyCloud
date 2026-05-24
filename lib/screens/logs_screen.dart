import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:get/get.dart';

import '../theme/app_colors.dart';
import '../services/log_service.dart';

class LogsScreen extends StatelessWidget {
  const LogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final logService = Get.find<LogService>();

    return Scaffold(
      backgroundColor: context.bg,
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
              left: 4,
              right: 4,
            ),
            decoration: BoxDecoration(
              color: context.bg,
              border: Border(
                bottom: BorderSide(color: context.border, width: 0.5),
              ),
            ),
            child: SizedBox(
              height: 52,
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_rounded, color: context.text),
                    onPressed: () => Get.back(),
                  ),
                  Text(
                    'App Logs',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: context.text,
                    ),
                  ),
                  const Spacer(),

                  IconButton(
                    icon: Icon(
                      Icons.copy_rounded,
                      size: 20,
                      color: context.textM,
                    ),
                    tooltip: 'Copy all logs',
                    onPressed: () {
                      final text = logService.exportAll();
                      Clipboard.setData(ClipboardData(text: text));
                    },
                  ),

                  IconButton(
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: context.textD,
                    ),
                    tooltip: 'Clear logs',
                    onPressed: () {
                      Get.dialog<bool?>(
                        AlertDialog(
                          backgroundColor: context.bgPanel,
                          title: Text(
                            'Clear Logs?',
                            style: TextStyle(color: context.text),
                          ),
                          content: Text(
                            'This will remove all current logs. Continue?',
                            style: TextStyle(color: context.textM),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Get.back(result: false),
                              child: Text(
                                'Cancel',
                                style: TextStyle(color: context.textD),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => Get.back(result: true),
                              child: const Text('Clear'),
                            ),
                          ],
                        ),
                      ).then((confirmed) {
                        if (confirmed == true) {
                          logService.clear();
                        }
                      });
                    },
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),

          _FilterBar(),

          Expanded(
            child: Obx(() {
              final filter = _FilterBar._activeFilter.value;
              final allLogs = logService.logs.toList().reversed.toList();
              final filtered = filter == 'ALL'
                  ? allLogs
                  : allLogs.where((e) => e.level == filter).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.article_outlined,
                        size: 48,
                        color: context.textD,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No logs yet.',
                        style: TextStyle(color: context.textD, fontSize: 14),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final entry = filtered[index];
                  return GestureDetector(
                    onLongPress: () {
                      Clipboard.setData(ClipboardData(text: entry.formatted));
                    },
                    child: _LogTile(entry: entry),
                  );
                },
              );
            }),
          ),

          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).padding.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: context.bgPanel,
              border: Border(
                top: BorderSide(color: context.border, width: 0.5),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _saveLogsToFile(logService).then((path) {
                    if (path != null) {
                    } else {
                      final text = logService.exportAll();
                      Clipboard.setData(ClipboardData(text: text));
                    }
                  });
                },
                label: const Text('Copy Logs to Share'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  side: const BorderSide(color: Colors.white),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  static final _activeFilter = 'ALL'.obs;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Obx(
        () => ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _chip(context, 'All', 'ALL'),
            _chip(context, 'Info', 'INFO'),
            _chip(context, 'Warnings', 'WARN'),
            _chip(context, 'Errors', 'ERROR'),
          ],
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, String label, String value) {
    final selected = _activeFilter.value == value;
    final color = value == 'ERROR'
        ? AppColors.red
        : value == 'WARN'
        ? AppColors.orange
        : value == 'INFO'
        ? AppColors.green
        : Colors.white;

    return Padding(
      padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? Colors.black87 : context.textM,
          ),
        ),
        selected: selected,
        onSelected: (_) => _activeFilter.value = value,
        selectedColor: Colors.white,
        backgroundColor: context.bgPanel,
        side: BorderSide(color: selected ? Colors.white : context.border),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  final LogEntry entry;
  const _LogTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final Color levelColor;
    final IconData levelIcon;
    switch (entry.level) {
      case 'ERROR':
        levelColor = AppColors.red;
        levelIcon = Icons.error_outline_rounded;
        break;
      case 'WARN':
        levelColor = AppColors.orange;
        levelIcon = Icons.warning_amber_rounded;
        break;
      default:
        levelColor = AppColors.green;
        levelIcon = Icons.info_outline_rounded;
    }

    final time =
        '${entry.timestamp.hour.toString().padLeft(2, '0')}:'
        '${entry.timestamp.minute.toString().padLeft(2, '0')}:'
        '${entry.timestamp.second.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: levelColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: levelColor.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(levelIcon, size: 14, color: levelColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 10,
                        color: context.textD,
                        fontFamily: 'monospace',
                      ),
                    ),
                    if (entry.source != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: levelColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          entry.source!,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: levelColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  entry.message,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.text,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<String?> _saveLogsToFile(LogService logService) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      '${dir.path}/whyycloud_logs_${DateTime.now().millisecondsSinceEpoch}.txt',
    );
    await file.writeAsString(logService.exportAll());
    return file.path;
  } catch (e) {
    debugPrint('Failed to save logs: $e');
    return null;
  }
}
