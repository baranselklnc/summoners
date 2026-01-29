import 'package:flutter/material.dart';
// DİKKAT: Oluşturduğun ekran dosyasının adı neyse onu import etmelisin.
// Örneğin dosya adın 'lol_screen.dart' ise:
import 'lol_screen.dart'; 

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Uygulama telefonda simge durumuna küçülünce görünen isim
      title: 'LoL Time Tracker',
      
      // Sağ üstteki "Debug" bandını kaldırır (Daha profesyonel görünür)
      debugShowCheckedModeBanner: false,

      // --- TEMA AYARLARI ---
      // Uygulamanın genel temasını koyu (Dark) yapıyoruz ki 
      // LoL tasarımına uygun olsun.
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF091428), // LoL Laciverti
        useMaterial3: true,
      ),

      // Uygulama açıldığında hangi ekran gösterilecek?
      // Buraya UI dosyasındaki Class adını yazmalısın.
      // Önceki örnekte 'HomeScreen' demiştik, sen değiştirdiysen onu yaz.
      home: const LoginScreen(), 
    );
  }
}