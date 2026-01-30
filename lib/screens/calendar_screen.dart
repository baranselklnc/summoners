import 'package:flutter/material.dart';
import 'package:summoners/services/riot_service.dart';
import 'package:summoners/services/storage_service.dart';
import 'package:table_calendar/table_calendar.dart';
// Paket ismin farklıysa buraları kontrol et

class CalendarScreen extends StatefulWidget {
  final String userPuuid;
  const CalendarScreen({super.key, required this.userPuuid});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  // --- DEĞİŞKENLER ---
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  String _resultText = "Bir tarih seçin";
  bool _isLoading = false;

  // İstatistik Metinleri
  String _globalAverage = "-";
  String _monthlyTotal = "-";
  String _last7DaysAverage = "-"; // İsim değişti: Average oldu

  final RiotService _service = RiotService();
  final StorageService _storageService = StorageService();
  
  Map<DateTime, String> _savedEvents = {};

  @override
  void initState() {
    super.initState();
    _loadAllMemories();
  }

  Future<void> _loadAllMemories() async {
    var data = await _storageService.getAllSavedDays(widget.userPuuid);
    setState(() {
      _savedEvents = data;
    });
    _calculateStats();
  }

  void _calculateStats() {
    if (_savedEvents.isEmpty) return;

    // 1. GENEL ORTALAMA
    int totalMinutesAllTime = 0;
    _savedEvents.forEach((_, value) => totalMinutesAllTime += _parseMinutes(value));
    int avgMinutes = totalMinutesAllTime ~/ _savedEvents.length;
    
    // 2. BU AY TOPLAM
    int totalMinutesMonth = 0;
    _savedEvents.forEach((date, value) {
      if (date.year == _focusedDay.year && date.month == _focusedDay.month) {
        totalMinutesMonth += _parseMinutes(value);
      }
    });

    // 3. SON 7 GÜN ORTALAMA (DEĞİŞEN KISIM)
    int totalMinutesWeek = 0;
    int daysCountInWeek = 0;
    
    DateTime now = DateTime.now();
    DateTime sevenDaysAgo = now.subtract(const Duration(days: 7));
    
    _savedEvents.forEach((date, value) {
      // Tarih son 7 gün içindeyse
      if (date.isAfter(sevenDaysAgo) && date.isBefore(now.add(const Duration(days: 1)))) {
        totalMinutesWeek += _parseMinutes(value);
        daysCountInWeek++; 
      }
    });

    int avgWeekMinutes = daysCountInWeek == 0 ? 0 : totalMinutesWeek ~/ daysCountInWeek;

    setState(() {
      _globalAverage = "${_formatMinToString(avgMinutes)} / gün";
      _monthlyTotal = _formatMinToString(totalMinutesMonth);
      _last7DaysAverage = "${_formatMinToString(avgWeekMinutes)} / gün"; 
    });
  }

  int _parseMinutes(String value) {
    int minutes = 0;
    if (value.contains("Saat")) {
      var parts = value.split(" Saat ");
      int h = int.tryParse(parts[0]) ?? 0;
      int m = int.tryParse(parts[1].replaceAll(" Dakika", "").trim()) ?? 0;
      minutes = (h * 60) + m;
    } else {
      minutes = int.tryParse(value.replaceAll(" Dakika", "").trim()) ?? 0;
    }
    return minutes;
  }

  String _formatMinToString(int totalMinutes) {
    if (totalMinutes == 0) return "0 dk";
    int h = totalMinutes ~/ 60;
    int m = totalMinutes % 60;
    if (h == 0) return "$m dk";
    return "$h sa $m dk";
  }

 Future<void> _fetchDataForDay(DateTime date) async {
    setState(() {
      _isLoading = true;
      _resultText = "Kontrol ediliyor...";
    });

    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;

    if (!isToday) {
      String? cachedData = await _storageService.getPlayTime(widget.userPuuid, date);

      if (cachedData != null) {
        setState(() {
          _isLoading = false;
          _resultText = "$cachedData (Kayıtlı)";
        });
        return; 
      }
    }

    setState(() => _resultText = isToday ? "Güncelleniyor..." : "Riot'a soruluyor...");

    String apiResult = await _service.getPlayTimeForDate(widget.userPuuid, date);

    if (!apiResult.contains("Hata") && !apiResult.contains("Veri alınamadı")) {
      await _storageService.savePlayTime(widget.userPuuid, date, apiResult);
      await _loadAllMemories(); 
    }

    setState(() {
      _isLoading = false;
      _resultText = apiResult;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF091428),
      appBar: AppBar(
        title: const Text("Performans Analizi", style: TextStyle(color: Color(0xFFC8AA6E))),
        backgroundColor: const Color(0xFF0A1428),
        iconTheme: const IconThemeData(color: Color(0xFFC8AA6E)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  _buildStatCard("GENEL ORTALAMA", _globalAverage, Colors.amber),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _buildStatCard("BU AY TOPLAM", _monthlyTotal, Colors.blueAccent)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildStatCard("SON 7 GÜN ORT.", _last7DaysAverage, Colors.greenAccent)),
                    ],
                  )
                ],
              ),
            ),

            TableCalendar(
              firstDay: DateTime.utc(2021, 1, 1),
              lastDay: DateTime.now(),
              focusedDay: _focusedDay,
              
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                });
                _calculateStats();
              },

              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(color: Colors.white, fontSize: 18),
                leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
                rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
              ),
              calendarStyle: const CalendarStyle(
                defaultTextStyle: TextStyle(color: Colors.white),
                weekendTextStyle: TextStyle(color: Colors.redAccent),
                todayDecoration: BoxDecoration(color: Colors.blueGrey, shape: BoxShape.circle),
                selectedDecoration: BoxDecoration(color: Color(0xFFC8AA6E), shape: BoxShape.circle),
              ),

              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
                _fetchDataForDay(selectedDay);
              },

              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  final keys = _savedEvents.keys.where((k) => isSameDay(k, date));
                  if (keys.isNotEmpty) {
                    String value = _savedEvents[keys.first] ?? "";
                    int min = _parseMinutes(value);
                    String shortText = _formatMinToString(min);

                    return Positioned(
                      bottom: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade800,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.greenAccent.withOpacity(0.5))
                        ),
                        child: Text(
                          shortText,
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
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
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E282D),
                border: Border.all(color: const Color(0xFFC8AA6E), width: 1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(
                    _selectedDay != null 
                    ? "${_selectedDay!.day}.${_selectedDay!.month}.${_selectedDay!.year}"
                    : "Tarih Seçilmedi",
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 5),
                  _isLoading 
                  ? const CircularProgressIndicator(color: Color(0xFFC8AA6E))
                  : Text(
                      _resultText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white, 
                        fontSize: 22,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2328),
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
           BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 5)
        ]
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(color: Colors.grey.shade400, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(
            value, 
            style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)
          ),
        ],
      ),
    );
  }
}