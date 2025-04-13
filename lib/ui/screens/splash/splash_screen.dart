import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  Future<void> _checkUserStatus() async {
    // Simulasi delay splash screen
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Definisi warna tema yang sama dengan layar lainnya
    const Color primaryGreen = Color(0xFF4CAF50);
    const Color lightGreen = Color(0xFFE8F5E9);
    const Color white = Colors.white;

    return Scaffold(
      backgroundColor: white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo dengan desain modern
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: lightGreen,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withAlpha((0.20 * 255).toInt()),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.eco,
                  size: 90,
                  color: primaryGreen,
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Judul aplikasi
            const Text(
              'Hortikultura App',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32), // Warna teks utama yang konsisten
              ),
            ),
            const SizedBox(height: 12),
            
            // Subjudul
            const Text(
              'Optimalkan Pekarangan Rumahmu',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF558B2F), // Warna teks sekunder yang konsisten
              ),
            ),
            const SizedBox(height: 40),
            
            // Indikator loading
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
                strokeWidth: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}