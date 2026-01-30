import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class RiotService {
  
  final String _regionRouting = 'europe'; 

  Map<String, String> get _headers => {
    "X-Riot-Token": dotenv.env['RIOT_API_KEY'] ?? "", // .env dosyasından alınan API anahtarı

    "Content-Type": "application/json",
  };

  /// 1. PUUID BULMA
  Future<String?> getPuuid(String gameName, String tagLine) async {
    String encodedName = Uri.encodeComponent(gameName);
    String encodedTag = Uri.encodeComponent(tagLine);

    final url = Uri.parse(
      'https://$_regionRouting.api.riotgames.com/riot/account/v1/accounts/by-riot-id/$encodedName/$encodedTag'
    );

    try {
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['puuid'];
      } else {
        print("PUUID Hatası: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      print("Bağlantı Hatası: $e");
      return null;
    }
  }

  /// 2. GÜNLÜK SÜRE (Hata Yönetimi Eklenmiş Hali)
  Future<String> getPlayTimeForDate(String puuid, DateTime date) async {
    try {
      // Adım 1: Maçları çekmeye çalış
      final matchIds = await _getMatchIdsByDate(puuid, date);
      
      if (matchIds.isEmpty) return "0 Dakika (Maç Yok)";

      // Adım 2: Süreleri topla
      final totalSeconds = await _calculateTotalDuration(matchIds);
      return _formatDuration(totalSeconds);

    } catch (e) {
      // ARTIK HATAYI GİZLEMİYORUZ, EKRANA BASIYORUZ!
      return "HATA: $e"; 
    }
  }

  // --- YARDIMCI METOTLAR ---

  /// Maç ID'lerini Çeker (Asıl suçlu burasıydı)
  Future<List<String>> _getMatchIdsByDate(String puuid, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final startTime = startOfDay.millisecondsSinceEpoch ~/ 1000;
    final endTime = endOfDay.millisecondsSinceEpoch ~/ 1000;

    final url = Uri.parse(
      'https://$_regionRouting.api.riotgames.com/lol/match/v5/matches/by-puuid/$puuid/ids?startTime=$startTime&endTime=$endTime&start=0&count=100'
    );

    final response = await http.get(url, headers: _headers);

    // ESKİ KOD: if (200) return list; else return []; <-- SUÇLU BUYDU!
    // YENİ KOD:
    if (response.statusCode == 200) {
      return List<String>.from(json.decode(response.body));
    } else {
      // Hata kodunu fırlat ki yukarıda yakalayıp ekrana basabilelim
      // Örn: "429" (Çok Hızlı), "403" (Key Bitti), "500" (Riot Çöktü)
      throw "API Hatası (${response.statusCode})"; 
    }
  }

  /// Maç detaylarını çeker
  Future<int> _calculateTotalDuration(List<String> matchIds) async {
    final futures = matchIds.map((id) => _getSingleMatchDuration(id));
    // Eğer detay çekerken hata olursa yine de diğerlerini topla
    final durations = await Future.wait(futures);
    return durations.fold<int>(0, (sum, current) => sum + current);
  }

  /// Tek maç detayı
  Future<int> _getSingleMatchDuration(String matchId) async {
    final url = Uri.parse(
      'https://$_regionRouting.api.riotgames.com/lol/match/v5/matches/$matchId'
    );
    try {
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['info']['gameDuration'] as int;
      } else {
        // Detay çekerken hata alırsak (Örn: 429), konsola yaz ama programı kırma
        print("Maç Detay Hatası ($matchId): ${response.statusCode}");
        return 0; 
      }
    } catch (e) {
      return 0;
    }
  }

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    if (hours == 0) return "$minutes Dakika";
    return "$hours Saat $minutes Dakika";
  }
}