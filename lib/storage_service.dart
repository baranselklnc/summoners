import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  
  /// Veriyi Kaydet: (Örn: "2024-01-29" -> "3 Saat 12 Dakika")
  Future<void> savePlayTime(String puuid, DateTime date, String timeResult) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Her kullanıcı ve her gün için benzersiz bir anahtar oluşturuyoruz.
    // Anahtar Örneği: "play_time_PUUID123_2024-01-29"
    String key = _generateKey(puuid, date);
    
    await prefs.setString(key, timeResult);
    print("Hafızaya Kaydedildi: $key -> $timeResult");
  }

  /// Veriyi Oku: Varsa string döner, yoksa null döner
  Future<String?> getPlayTime(String puuid, DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    String key = _generateKey(puuid, date);
    
    // Hafızada var mı?
    if (prefs.containsKey(key)) {
      print("Hafızadan Okundu: $key");
      return prefs.getString(key);
    }
    return null; // Yoksa null döner
  }

  // Anahtar oluşturucu (Yardımcı metod)
  String _generateKey(String puuid, DateTime date) {
    // Sadece Yıl-Ay-Gün bilgisini alıyoruz
    String dateStr = "${date.year}-${date.month}-${date.day}";
    return "play_time_${puuid}_$dateStr";
  }

  Future<Map<DateTime, String>> getAllSavedDays(String puuid) async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys(); // Tüm anahtarları al
    
    Map<DateTime, String> savedMap = {};

    for (String key in allKeys) {
      // Sadece bu kullanıcıya ait "play_time" verilerini bul
      if (key.startsWith("play_time_${puuid}_")) {
        // Key formatımız: play_time_PUUID_2024-1-29
        // Sondaki tarihi kesip alıyoruz
        String datePart = key.split('_').last; 
        List<String> ymd = datePart.split('-'); // Yıl, Ay, Gün
        
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