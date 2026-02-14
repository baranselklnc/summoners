import 'dart:convert';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class RiotService {
  final String _regionRouting = 'europe';   // match-v5
  final String _platformRouting = 'tr1';    // account + spectator

  Map<String, String> get _headers => {
        "X-Riot-Token": dotenv.env['RIOT_API_KEY'] ?? "",
        "Content-Type": "application/json",
      };

  // =========================================================
  // 1️⃣ PUUID GETİR
  // =========================================================
  Future<String?> getPuuid(String gameName, String tagLine) async {
    final url = Uri.parse(
        'https://$_regionRouting.api.riotgames.com/riot/account/v1/accounts/by-riot-id/$gameName/$tagLine');

    final res = await _safeGet(url);
    if (res == null) return null;

    final data = json.decode(res.body);
    return data['puuid'];
  }

  // =========================================================
  // 2️⃣ GÜNLÜK TOPLAM OYNAMA SÜRESİ (KESİN DOĞRU)
  // =========================================================
  Future<int> getPlayTimeForDate(
      String puuid, DateTime date) async {

    final matchIds = await _getLastMatches(puuid);

    int totalSeconds = 0;

    for (final id in matchIds) {
      final matchData = await _getMatchFullData(id);
      if (matchData == null) continue;

      final info = matchData['info'];

      final gameStart =
          DateTime.fromMillisecondsSinceEpoch(
              info['gameStartTimestamp']);

      if (gameStart.year == date.year &&
          gameStart.month == date.month &&
          gameStart.day == date.day) {

        final duration = info['gameDuration'] as int;
        totalSeconds += duration;
      }
    }

    return totalSeconds;
  }

  // =========================================================
  // 3️⃣ SON 20 MAÇ
  // =========================================================
  Future<List<String>> _getLastMatches(String puuid) async {

    final url = Uri.parse(
        'https://$_regionRouting.api.riotgames.com/lol/match/v5/matches/by-puuid/$puuid/ids?start=0&count=20');

    final res = await _safeGet(url);
    if (res == null) return [];

    return List<String>.from(json.decode(res.body));
  }

  // =========================================================
  // 4️⃣ MATCH FULL DATA
  // =========================================================
  Future<Map<String, dynamic>?> _getMatchFullData(
      String matchId) async {

    final url = Uri.parse(
        'https://$_regionRouting.api.riotgames.com/lol/match/v5/matches/$matchId');

    final res = await _safeGet(url);
    if (res == null) return null;

    return json.decode(res.body);
  }

  // =========================================================
  // 5️⃣ LIVE GAME
  // =========================================================
  Future<Map<String, dynamic>?> getLiveGameData(
      String puuid) async {

    final url = Uri.parse(
        'https://$_platformRouting.api.riotgames.com/lol/spectator/v5/active-games/by-summoner/$puuid');

    final res = await _safeGet(url);
    if (res == null) return null;

    return json.decode(res.body);
  }

  // =========================================================
  // 6️⃣ SAFE GET + RATE LIMIT
  // =========================================================
  Future<http.Response?> _safeGet(Uri url,
      {int retry = 0}) async {

    try {
      final res = await http.get(url, headers: _headers);

      if (res.statusCode == 200) return res;

      if (res.statusCode == 429 && retry < 5) {
        await Future.delayed(const Duration(seconds: 2));
        return _safeGet(url, retry: retry + 1);
      }

      return null;

    } catch (_) {
      return null;
    }
  }
}
