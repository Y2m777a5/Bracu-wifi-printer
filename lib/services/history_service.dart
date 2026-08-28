import 'package:shared_preferences/shared_preferences.dart';
import '../models/print_job.dart';

class HistoryService {
  static const String _keyHistory = 'print_history';

  static Future<List<PrintJob>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? historyJson = prefs.getStringList(_keyHistory);
    if (historyJson == null) return [];

    return historyJson.map((job) => PrintJob.fromJson(job)).toList().reversed.toList();
  }

  static Future<void> addJob(PrintJob job) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> historyJson = prefs.getStringList(_keyHistory) ?? [];
    
    // Limit history to last 50 entries
    if (historyJson.length >= 50) {
      historyJson.removeAt(0);
    }
    
    historyJson.add(job.toJson());
    await prefs.setStringList(_keyHistory, historyJson);
  }

  static Future<PrintJob?> getLastSuccessfulJob() async {
    final history = await getHistory();
    try {
      // getHistory() returns reversed list (newest first)
      return history.firstWhere((job) => job.status.toLowerCase() == 'success');
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyHistory);
  }
}
