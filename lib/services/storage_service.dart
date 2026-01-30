import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  
  Future<void> savePlayTime(String puuid, DateTime date, String timeResult) async {
    final prefs = await SharedPreferences.getInstance();
    

    String key = _generateKey(puuid, date);
    
    await prefs.setString(key, timeResult);
    print("Hafızaya Kaydedildi: $key -> $timeResult");
  }

  Future<String?> getPlayTime(String puuid, DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    String key = _generateKey(puuid, date);
    
    // Hafızada var mı?
    if (prefs.containsKey(key)) {
      print("Hafızadan Okundu: $key");
      return prefs.getString(key);
    }
    return null; 
  }

  String _generateKey(String puuid, DateTime date) {
    String dateStr = "${date.year}-${date.month}-${date.day}";
    return "play_time_${puuid}_$dateStr";
  }

  Future<Map<DateTime, String>> getAllSavedDays(String puuid) async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();
    
    Map<DateTime, String> savedMap = {};

    for (String key in allKeys) {
      if (key.startsWith("play_time_${puuid}_")) {
        String datePart = key.split('_').last; 
        List<String> ymd = datePart.split('-');
        
        DateTime date = DateTime(
          int.parse(ymd[0]), 
          int.parse(ymd[1]), 
          int.parse(ymd[2])
        );

        String? value = prefs.getString(key);
        if (value != null) {
          savedMap[date] = value;
        }
      }
    }
    return savedMap;
  }
}