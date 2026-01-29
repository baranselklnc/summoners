import 'package:flutter/material.dart';
// Paket ismin farklıysa buraları kontrol et
import 'package:summoners/calendar_screen.dart';
import 'package:summoners/services/service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;

  // --- SENİN VERDİĞİN LİSTE ---
  final List<Map<String, String>> _favoritePlayers = [
    {"name": "Eastcoastter", "tag": "TR1"},
    {"name": "Crowley", "tag": "BJK"},
    {"name": "OTK", "tag": "4444"},
    {"name": "IBlue PlayerI", "tag": "TR1"},
    {"name": "Athelas", "tag": "111"},
    {"name": "Temu yasuosu", "tag": "yas"},
  ];

  Future<void> _analyze() async {
    // Klavye açıksa kapat
    FocusScope.of(context).unfocus();

    if (_nameController.text.isEmpty || _tagController.text.isEmpty) {
      setState(() => _errorMessage = "Lütfen isim ve tag girin.");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final service = RiotService();
    
    // PUUID bulma işlemi
    String? puuid = await service.getPuuid(
      _nameController.text.trim(), 
      _tagController.text.trim()
    );

    setState(() => _isLoading = false);

    if (puuid != null) {
      // Başarılıysa Takvim Ekranına git
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CalendarScreen(userPuuid: puuid),
        ),
      );
    } else {
      setState(() => _errorMessage = "Kullanıcı bulunamadı veya API hatası.");
    }
  }

  // Listeden birine tıklayınca çalışır
  void _onFavoriteTap(String name, String tag) {
    _nameController.text = name;
    _tagController.text = tag;
    _analyze(); // Direkt aramayı başlat!
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF091428),
      appBar: AppBar(
        title: const Text("LoL Time Tracker", style: TextStyle(color: Color(0xFFC8AA6E))),
        backgroundColor: const Color(0xFF0A1428),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // --- ÜST KISIM: MANUEL ARAMA ---
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF0A1428),
              border: Border(bottom: BorderSide(color: Color(0xFFC8AA6E), width: 1)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDeco("Oyun Adı", Icons.person),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: _tagController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDeco("Tag", Icons.tag),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent)),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _analyze,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC8AA6E),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                      : const Text("ARA", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),

          // --- ALT KISIM: HIZLI LİSTE ---
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "HIZLI SEÇİM", 
                style: TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 1.5)
              ),
            ),
          ),

          Expanded(
            child: ListView.builder(
              itemCount: _favoritePlayers.length,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              itemBuilder: (context, index) {
                final player = _favoritePlayers[index];
                return Card(
                  color: const Color(0xFF1E2328),
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                    borderRadius: BorderRadius.circular(8)
                  ),
                  child: ListTile(
                    onTap: () => _onFavoriteTap(player['name']!, player['tag']!),
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF091428),
                      child: Icon(Icons.videogame_asset, color: Color(0xFFC8AA6E)),
                    ),
                    title: Text(
                      player['name']!,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "#${player['tag']}",
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, color: Color(0xFFC8AA6E), size: 16),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey),
      labelStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: const Color(0xFF1E2328),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFC8AA6E)),
      ),
    );
  }
}