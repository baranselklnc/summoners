import 'package:flutter/material.dart';
import 'package:summoners/services/riot_service.dart';
import 'package:summoners/services/storage_service.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends StatefulWidget {
  final String userPuuid;
  const CalendarScreen({super.key, required this.userPuuid});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  String _resultText = "Bir tarih seçin";
  bool _isLoading = false;

  String _globalAverage = "-";
  String _monthlyTotal = "-";
  String _last7DaysAverage = "-";

  final RiotService _service = RiotService();
  final StorageService _storageService = StorageService();

  Map<DateTime, int> _savedEvents = {};

  Map<String, dynamic>? _liveGameData;
  bool _isCheckingLive = false;
  String _statusMessage = "Kontrol ediliyor...";
  Color _statusColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    _loadAllMemories();
    _checkLiveGame();
  }

  // ================= LIVE GAME =================

  Future<void> _checkLiveGame() async {
    setState(() {
      _isCheckingLive = true;
      _statusColor = Colors.amber;
    });

    final data = await _service.getLiveGameData(widget.userPuuid);

    setState(() {
      _isCheckingLive = false;
      _liveGameData = data;

      if (data != null) {
        _statusMessage = "OYUNDA";
        _statusColor = Colors.greenAccent;
      } else {
        _statusMessage = "ÇEVRİMDIŞI";
        _statusColor = Colors.redAccent;
      }
    });
  }

  // ================= CACHE LOAD =================

  Future<void> _loadAllMemories() async {
    final data = await _storageService.getAllSavedDays(widget.userPuuid);

    setState(() {
      _savedEvents = data;
    });

    _calculateStats();
  }

  // ================= STATISTICS =================

  void _calculateStats() {
    if (_savedEvents.isEmpty) {
      setState(() {
        _globalAverage = "0 dk";
        _monthlyTotal = "0 dk";
        _last7DaysAverage = "0 dk";
      });
      return;
    }

    int totalSecondsAllTime = 0;

    _savedEvents.forEach((_, seconds) {
      totalSecondsAllTime += seconds;
    });

    int avgSeconds = totalSecondsAllTime ~/ _savedEvents.length;

    // BU AY
    int totalSecondsMonth = 0;

    _savedEvents.forEach((date, seconds) {
      if (date.year == _focusedDay.year &&
          date.month == _focusedDay.month) {
        totalSecondsMonth += seconds;
      }
    });

    // SON 7 GÜN ORTALAMA
    int totalSecondsWeek = 0;
    int daysCount = 0;

    DateTime now = DateTime.now();
    DateTime sevenDaysAgo = now.subtract(const Duration(days: 7));

    _savedEvents.forEach((date, seconds) {
      if (date.isAfter(sevenDaysAgo) &&
          date.isBefore(now.add(const Duration(days: 1)))) {
        totalSecondsWeek += seconds;
        daysCount++;
      }
    });

    int avgWeekSeconds =
        daysCount == 0 ? 0 : totalSecondsWeek ~/ daysCount;

    setState(() {
      _globalAverage = "${_formatSeconds(avgSeconds)} / gün";
      _monthlyTotal = _formatSeconds(totalSecondsMonth);
      _last7DaysAverage = "${_formatSeconds(avgWeekSeconds)} / gün";
    });
  }

  // ================= FORMAT =================

  String _formatSeconds(int seconds) {
    if (seconds == 0) return "0 dk";

    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;

    if (hours == 0) return "$minutes dk";
    return "$hours sa $minutes dk";
  }

  // ================= FETCH DAY =================

  Future<void> _fetchDataForDay(DateTime date) async {
    setState(() {
      _isLoading = true;
      _resultText = "Kontrol ediliyor...";
    });

    final now = DateTime.now();
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;

    if (!isToday) {
      final cachedSeconds =
          await _storageService.getPlayTime(widget.userPuuid, date);

      if (cachedSeconds != null) {
        setState(() {
          _isLoading = false;
          _resultText =
              "${_formatSeconds(cachedSeconds)} (Kayıtlı)";
        });
        return;
      }
    }

    // Riot çağrısı artık INT saniye döndürmeli
    final totalSeconds =
        await _service.getPlayTimeForDate(
      widget.userPuuid,
      date,
    );

    if (totalSeconds >= 0) {
      await _storageService.savePlayTime(
        widget.userPuuid,
        date,
        totalSeconds,
      );

      await _loadAllMemories();

      setState(() {
        _resultText = _formatSeconds(totalSeconds);
      });
    } else {
      setState(() {
        _resultText = "Veri alınamadı";
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF091428),
      appBar: AppBar(
        title: const Text(
          "Performans Analizi",
          style: TextStyle(color: Color(0xFFC8AA6E)),
        ),
        backgroundColor: const Color(0xFF0A1428),
        iconTheme:
            const IconThemeData(color: Color(0xFFC8AA6E)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [

            // LIVE STATUS
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _statusColor.withOpacity(0.1),
                border: Border.all(color: _statusColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _isCheckingLive
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _liveGameData != null
                              ? "Oyunda: ${getQueueName(_liveGameData!['gameQueueConfigId'])}"
                              : "Çevrimdışı",
                          style: TextStyle(
                            color: _statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: _checkLiveGame,
                          icon: const Icon(Icons.refresh),
                        )
                      ],
                    ),
            ),

            // STATS
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _buildStatCard(
                      "GENEL ORTALAMA",
                      _globalAverage,
                      Colors.amber),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                            "BU AY",
                            _monthlyTotal,
                            Colors.blueAccent),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildStatCard(
                            "SON 7 GÜN",
                            _last7DaysAverage,
                            Colors.greenAccent),
                      ),
                    ],
                  )
                ],
              ),
            ),

            // CALENDAR
            TableCalendar(
              firstDay: DateTime.utc(2021, 1, 1),
              lastDay: DateTime.now(),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) =>
                  isSameDay(_selectedDay, day),
              onDaySelected: (selected, focused) {
                setState(() {
                  _selectedDay = selected;
                  _focusedDay = focused;
                });
                _fetchDataForDay(selected);
              },
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  final entry = _savedEvents.entries
                      .where((e) =>
                          isSameDay(e.key, date))
                      .toList();

                  if (entry.isNotEmpty) {
                    return Positioned(
                      bottom: 1,
                      child: Text(
                        _formatSeconds(entry.first.value),
                        style: const TextStyle(
                          fontSize: 9,
                          color: Colors.greenAccent,
                        ),
                      ),
                    );
                  }
                  return null;
                },
              ),
            ),

            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              margin:
                  const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E282D),
                border: Border.all(
                    color: const Color(0xFFC8AA6E)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : Text(
                      _resultText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, Color color) {
    return Container(
      padding:
          const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2328),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Column(
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey)),
          const SizedBox(height: 5),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ================= QUEUE NAME =================

String getQueueName(int queueId) {
  switch (queueId) {
    case 420:
      return "Dereceli Tek/Çift";
    case 440:
      return "Dereceli Esnek";
    case 400:
      return "Normal Seçim";
    case 430:
      return "Normal Kapalı";
    case 490:
      return "Hızlı Oyun";
    case 450:
      return "ARAM";
    case 700:
      return "Clash";
    case 1900:
      return "URF";
    default:
      return "Özel Oyun";
  }
}
