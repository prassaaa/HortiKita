import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import '../auth/login_screen.dart';
import '../home/home_screen.dart';
import '../admin/admin_dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Inisialisasi animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    
    // Buat animasi fade in
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );
    
    // Buat animasi slide
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    
    // Mulai animasi
    _animationController.forward();
    
    // Cek status user setelah animasi selesai
    Future.delayed(const Duration(milliseconds: 5000), () {
      _checkUserStatusDirectly();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Pendekatan langsung tanpa Provider
  Future<void> _checkUserStatusDirectly() async {
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
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => const AdminDashboardScreen(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    const begin = Offset(1.0, 0.0);
                    const end = Offset.zero;
                    const curve = Curves.easeInOut;
                    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                    var offsetAnimation = animation.drive(tween);
                    return SlideTransition(position: offsetAnimation, child: child);
                  },
                  transitionDuration: const Duration(milliseconds: 500),
                ),
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
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOut;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              var offsetAnimation = animation.drive(tween);
              return SlideTransition(position: offsetAnimation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      } else {
        print('No user logged in, navigating to LoginScreen');
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOut;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              var offsetAnimation = animation.drive(tween);
              return SlideTransition(position: offsetAnimation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    } catch (e) {
      print('Error in _checkUserStatusDirectly: $e');
      // Default to LoginScreen if error
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);
            return SlideTransition(position: offsetAnimation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Definisi warna tema
    const Color primaryGreen = Color(0xFF4CAF50);
    const Color lightGreen = Color(0xFFE8F5E9);
    const Color white = Colors.white;
    
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              lightGreen.withOpacity(0.8),
              white,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Lottie Animation
              FadeTransition(
                opacity: _fadeInAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SizedBox(
                    width: size.width * 0.6,
                    height: size.width * 0.6,
                    child: Lottie.asset(
                      'assets/animations/plant_grow.json',
                      repeat: true,
                      animate: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Animated Title
              FadeTransition(
                opacity: _fadeInAnimation,
                child: AnimatedTextKit(
                  animatedTexts: [
                    FadeAnimatedText(
                      'HortiKita',
                      textStyle: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                      duration: const Duration(milliseconds: 1500),
                    ),
                  ],
                  isRepeatingAnimation: false,
                ),
              ),
              const SizedBox(height: 12),
              
              // Animated Subtitle with Typing Effect
              FadeTransition(
                opacity: _fadeInAnimation,
                child: AnimatedTextKit(
                  animatedTexts: [
                    TypewriterAnimatedText(
                      'Optimalkan Pekarangan Rumahmu',
                      textStyle: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF558B2F),
                      ),
                      speed: const Duration(milliseconds: 80),
                    ),
                  ],
                  isRepeatingAnimation: false,
                ),
              ),
              const SizedBox(height: 40),
              
              // Loading Indicator - Hapus const dari constructor
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(seconds: 2),
                builder: (context, value, child) {
                  return SizedBox(
                    width: 100,
                    child: LinearProgressIndicator(
                      value: value,
                      backgroundColor: lightGreen,
                      valueColor: const AlwaysStoppedAnimation<Color>(primaryGreen),
                      minHeight: 5,
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}