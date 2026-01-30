import 'dart:convert'; // JSON işlemleri için gerekli
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Hafıza için
// Paket ismin farklıysa buraları kontrol et
import 'package:summoners/screens/calendar_screen.dart';
import 'package:summoners/services/riot_service.dart';

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

  // Artık liste sabit değil, boş başlıyor ve hafızadan doluyor
  List<Map<String, dynamic>> _favoritePlayers = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites(); // Uygulama açılınca hafızayı oku
  }

  // --- HAFIZA İŞLEMLERİ ---

  // 1. Listeyi Hafızadan Yükle
  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final String? storedList = prefs.getString('user_favorites');

    if (storedList != null) {
      // JSON formatındaki stringi listeye çevir
      setState(() {
        _favoritePlayers = List<Map<String, dynamic>>.from(json.decode(storedList));
      });
    } else {
      // Eğer hiç kayıt yoksa varsayılan olarak seni ekleyelim :)
      setState(() {
        _favoritePlayers = [
          {"name": "Eastcoastter", "tag": "TR1"},
        ];
      });
    }
  }

  // 2. Listeyi Hafızaya Kaydet
  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    // Listeyi JSON stringine çevirip sakla
    await prefs.setString('user_favorites', json.encode(_favoritePlayers));
  }

  // 3. Yeni Kişi Ekle
  void _addNewPlayer(String name, String tag) {
    setState(() {
      _favoritePlayers.add({"name": name, "tag": tag});
    });
    _saveFavorites(); // Kaydet
  }

  // 4. Kişi Sil
  void _removePlayer(int index) {
    setState(() {
      _favoritePlayers.removeAt(index);
    });
    _saveFavorites(); // Kaydet
  }

  // --- ARAMA MOTORU ---
  Future<void> _analyze() async {
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
    
    String? puuid = await service.getPuuid(
      _nameController.text.trim(), 
      _tagController.text.trim()
    );

    setState(() => _isLoading = false);

    if (puuid != null) {
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

  void _onFavoriteTap(String name, String tag) {
    _nameController.text = name;
    _tagController.text = tag;
    _analyze(); 
  }

  // --- EKLEME PENCERESİ (POP-UP) ---
  void _showAddDialog() {
    String newName = "";
    String newTag = "";

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E2328),
          title: const Text("Arkadaş Ekle", style: TextStyle(color: Color(0xFFC8AA6E))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                onChanged: (val) => newName = val,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Oyuncu Adı",
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFC8AA6E))),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                onChanged: (val) => newTag = val,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Tag (Örn: TR1)",
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFC8AA6E))),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("İptal", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC8AA6E)),
              onPressed: () {
                if (newName.isNotEmpty && newTag.isNotEmpty) {
                  _addNewPlayer(newName, newTag);
                  Navigator.pop(context);
                }
              },
              child: const Text("Ekle", style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF091428),
      appBar: AppBar(
        title: const Text("Summoner's Clock", style: TextStyle(color: Color(0xFFC8AA6E))),
        backgroundColor: const Color(0xFF0A1428),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // --- ÜST KISIM: ARAMA ---
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
                        decoration: _inputDeco("Oyuncu Adı", Icons.person),
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

          // --- BAŞLIK VE EKLE BUTONU ---
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "ARKADAŞ LİSTESİ", 
                  style: TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 1.5)
                ),
                InkWell(
                  onTap: _showAddDialog,
                  child: const Row(
                    children: [
                      Icon(Icons.add_circle, color: Color(0xFFC8AA6E), size: 16),
                      SizedBox(width: 5),
                      Text("Ekle", style: TextStyle(color: Color(0xFFC8AA6E), fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              ],
            ),
          ),

          // --- DİNAMİK LİSTE ---
          Expanded(
            child: _favoritePlayers.isEmpty 
            ? const Center(child: Text("Henüz kimseyi eklemediniz.", style: TextStyle(color: Colors.white30)))
            : ListView.builder(
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
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                      onPressed: () => _removePlayer(index),
                    ),
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