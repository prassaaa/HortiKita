import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/login_screen.dart';
import '../home/home_screen.dart';
import '../admin/admin_dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  @override
  void initState() {
    super.initState();
    // Di initState, kita tidak dapat menggunakan context untuk Provider
    // Jadi gunakan _checkUserStatus yang berbeda
    _checkUserStatusDirectly();
  }

  // Pendekatan langsung tanpa Provider
  Future<void> _checkUserStatusDirectly() async {
    // Simulasi delay splash screen
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    try {
      // Periksa login status langsung dari Firebase
      final currentUser = _auth.currentUser;
      
      if (currentUser != null) {
        print('User logged in: ${currentUser.email}');
        
        // Periksa role langsung dari Firestore
        try {
          final doc = await _firestore
              .collection('users')
              .doc(currentUser.uid)
              .get();
              
          if (doc.exists) {
            final data = doc.data() as Map<String, dynamic>;
            final role = data['role'] as String?;
            final isAdmin = role == 'admin';
            
            print('User: ${currentUser.email}, role: $role, isAdmin: $isAdmin');
            
            if (!mounted) return;
            
            if (isAdmin) {
              print('User is admin, navigating to AdminDashboardScreen');
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
              );
              return;
            }
          }
        } catch (e) {
          print('Error checking user role: $e');
        }
        
        // Default to HomeScreen if not admin or if error occurs
        if (!mounted) return;
        print('Navigating to HomeScreen');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        print('No user logged in, navigating to LoginScreen');
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (e) {
      print('Error in _checkUserStatusDirectly: $e');
      // Default to LoginScreen if error
      if (!mounted) return;
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