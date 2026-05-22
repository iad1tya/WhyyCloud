import 'package:get/get.dart';

class LogEntry {
  final DateTime timestamp;
  final String level; // INFO, WARN, ERROR
  final String message;
  final String? source;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.source,
  });

  String get formatted {
    final t = '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}';
    final src = source != null ? ' ($source)' : '';
    return '[$t] [$level]$src $message';
  }
}

class LogService extends GetxService {
  static const int maxLogs = 1000;
  final logs = <LogEntry>[].obs;

  LogService init() {
    info('App started', source: 'System');
    return this;
  }

  void info(String message, {String? source}) =>
      _add('INFO', message, source);

  void warn(String message, {String? source}) =>
      _add('WARN', message, source);

  void error(String message, {String? source}) =>
      _add('ERROR', message, source);

  void _add(String level, String message, String? source) {
    logs.add(LogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      source: source,
    ));
    // Keep within limit
    while (logs.length > maxLogs) {
      logs.removeAt(0);
    }
  }

  /// Export all logs as a single string for sharing.
  String exportAll() {
    final buf = StringBuffer();
    buf.writeln('=== Portable AI Logs ===');
    buf.writeln('Exported: ${DateTime.now().toIso8601String()}');
    buf.writeln('Total entries: ${logs.length}');
    buf.writeln('');
    for (final entry in logs) {
      buf.writeln(entry.formatted);
    }
    return buf.toString();
  }

  void clear() => logs.clear();
}
