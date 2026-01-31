import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class RiotService {
  
  final String _regionRouting = 'europe'; 
  final String _specRouting='tr1';

  Map<String, String> get _headers => {
    "X-Riot-Token": dotenv.env['RIOT_API_KEY'] ?? "",
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
      final matchIds = await _getMatchIdsByDate(puuid, date);
      
      if (matchIds.isEmpty) return "0 Dakika (Maç Yok)";

      final totalSeconds = await _calculateTotalDuration(matchIds);
      return _formatDuration(totalSeconds);

    } catch (e) {
      return "HATA: $e"; 
    }
  }

  // --- YARDIMCI METOTLAR ---

  Future<List<String>> _getMatchIdsByDate(String puuid, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final startTime = startOfDay.millisecondsSinceEpoch ~/ 1000;
    final endTime = endOfDay.millisecondsSinceEpoch ~/ 1000;

    final url = Uri.parse(
      'https://$_regionRouting.api.riotgames.com/lol/match/v5/matches/by-puuid/$puuid/ids?startTime=$startTime&endTime=$endTime&start=0&count=100'
    );

    final response = await http.get(url, headers: _headers);


    if (response.statusCode == 200) {
      return List<String>.from(json.decode(response.body));
    } else {

      throw "Çok fazla tıklama yaptınız Riot bunu beğenmedi.Biraz bekleyin ardından tıklamaya devam edin.  (${response.statusCode})"; 
    }
  }

  /// Maç detaylarını çeker
  Future<int> _calculateTotalDuration(List<String> matchIds) async {
    final futures = matchIds.map((id) => _getSingleMatchDuration(id));
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
        print("Maç Detay Hatası ($matchId): ${response.statusCode}");
        return 0; 
      }
    } catch (e) {
      return 0;
    }
  }
  
  //Kullanıcının canlı olma durumu 
  // Future<String> _isOnline(String puuid) async{
  //   final url=Uri.parse('https://$_specRouting.api.riotgames.com/lol/spectator/v5/active-games/by-summoner/$puuid');
  //   try{
  //     final response=await http.get(url,headers: _headers);
  //     if(response.statusCode==200){
  //       final data=json.decode(response.body);
  //       print(data);
  //       return data;
  //     }
  //     else{
  //       return "${response.statusCode}";
  //     }
  //   }
  //   catch(e){
  //     return "çalışmadı";
  //   }
  // }

  // riot_service.dart içine bu metodu güncelle/ekle:

  Future<Map<String, dynamic>?> getLiveGameData(String puuid) async {
    // Tarayıcıda test ettiğin ve çalışan sunucu bu:
    const platform = 'tr1'; 
    
    final url = Uri.parse(
      'https://$platform.api.riotgames.com/lol/spectator/v5/active-games/by-summoner/$puuid'
    );

    try {
      final response = await http.get(url, headers: _headers);
      
      if (response.statusCode == 200) {
        // MAÇ VAR! Veriyi olduğu gibi döndürüyoruz.
        return json.decode(response.body);
      } else {
        // 404 ise veya hata varsa null döneriz.
        return null; 
      }
    } catch (e) {
      print("Bağlantı Hatası: $e");
      return null;
    }
  }

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    if (hours == 0) return "$minutes Dakika";
    return "$hours Saat $minutes Dakika";
  }

}