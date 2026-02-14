import 'package:shared_preferences/shared_preferences.dart';

class StorageService {

  // ================= SAVE =================

  Future<void> savePlayTime(
      String puuid, DateTime date, int totalSeconds) async {

    final prefs = await SharedPreferences.getInstance();

    final key = _generateKey(puuid, date);

    await prefs.setInt(key, totalSeconds);
  }

  // ================= GET SINGLE DAY =================

  Future<int?> getPlayTime(
      String puuid, DateTime date) async {

    final prefs = await SharedPreferences.getInstance();

    final key = _generateKey(puuid, date);

    return prefs.getInt(key);
  }

  // ================= GET ALL DAYS =================

  Future<Map<DateTime, int>> getAllSavedDays(
      String puuid) async {

    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    Map<DateTime, int> result = {};

    for (final key in keys) {

      if (!key.startsWith("play_time_${puuid}_")) continue;

      final dateStr =
          key.replaceFirst("play_time_${puuid}_", "");

      DateTime? parsedDate;

      parsedDate = DateTime.tryParse(dateStr);

      if (parsedDate == null) {
        final parts = dateStr.split("-");
        if (parts.length == 3) {
          final year = int.tryParse(parts[0]);
          final month = int.tryParse(parts[1]);
          final day = int.tryParse(parts[2]);

          if (year != null && month != null && day != null) {
            parsedDate = DateTime.utc(year, month, day);
          }
        }
      }

      if (parsedDate == null) continue;

      final seconds = prefs.getInt(key);

      if (seconds != null) {
        final normalized =
            DateTime(parsedDate.year, parsedDate.month, parsedDate.day);

        result[normalized] = seconds;
      }
    }

    return result;
  }

  // ================= KEY GENERATOR =================

  String _generateKey(String puuid, DateTime date) {

    final utc = DateTime.utc(date.year, date.month, date.day);

    final formatted =
        utc.toIso8601String().substring(0, 10);

    return "play_time_${puuid}_$formatted";
  }
}
