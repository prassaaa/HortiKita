import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
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

class SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  final Logger _logger = Logger();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  
  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _progressAnimation;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startSplashSequence();
  }
  
  void _initializeAnimations() {
    // Fade Animation Controller
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    // Slide Animation Controller
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Scale Animation Controller
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    // Create Animations
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
  }
  
  void _startSplashSequence() async {
    // Start animations with staggered timing
    _fadeController.forward();
    
    await Future.delayed(const Duration(milliseconds: 300));
    _slideController.forward();
    
    await Future.delayed(const Duration(milliseconds: 200));
    _scaleController.forward();
    
    // Wait for splash to complete then check user status
    await Future.delayed(const Duration(seconds: 3));
    _checkUserStatusDirectly();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  // Theme Colors - Modern Design System
  static const Color primaryColor = Color(0xFF2D5A27);
  static const Color primaryLight = Color(0xFF4CAF50);
  static const Color primarySurface = Color(0xFFF1F8E9);
  static const Color surfaceColor = Color(0xFFFAFAFA);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF1B1B1B);
  static const Color textSecondary = Color(0xFF6B6B6B);

  Future<void> _checkUserStatusDirectly() async {
    if (!mounted) return;
    
    try {
      final currentUser = _auth.currentUser;
      
      if (currentUser != null) {
        _logger.d('User logged in: ${currentUser.email}');
        
        try {
          final doc = await _firestore
              .collection('users')
              .doc(currentUser.uid)
              .get();
              
          if (doc.exists) {
            final data = doc.data() as Map<String, dynamic>;
            final role = data['role'] as String?;
            final isAdmin = role == 'admin';
            
            _logger.d('User: ${currentUser.email}, role: $role, isAdmin: $isAdmin');
            
            if (!mounted) return;
            
            if (isAdmin) {
              _logger.d('User is admin, navigating to AdminDashboardScreen');
              _navigateWithTransition(const AdminDashboardScreen());
              return;
            }
          }
        } catch (e) {
          _logger.d('Error checking user role: $e');
        }
        
        if (!mounted) return;
        _logger.d('Navigating to HomeScreen');
        _navigateWithTransition(const HomeScreen());
      } else {
        _logger.d('No user logged in, navigating to LoginScreen');
        if (!mounted) return;
        _navigateWithTransition(const LoginScreen());
      }
    } catch (e) {
      _logger.d('Error in _checkUserStatusDirectly: $e');
      if (!mounted) return;
      _navigateWithTransition(const LoginScreen());
    }
  }
  
  void _navigateWithTransition(Widget destination) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          return SlideTransition(position: offsetAnimation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isTablet = size.width > 600;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primarySurface.withValues(alpha: 0.3),
              surfaceColor,
              cardColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                
                // Logo Animation Section
                _buildLogoSection(size, isTablet),
                
                const SizedBox(height: 48),
                
                // Title and Subtitle Section
                _buildTextSection(),
                
                const Spacer(flex: 2),
                
                // Progress Section
                _buildProgressSection(),
                
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection(Size size, bool isTablet) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: isTablet ? 200 : size.width * 0.5,
            height: isTablet ? 200 : size.width * 0.5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primaryLight.withValues(alpha: 0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Lottie.asset(
                  'assets/animations/plant_grow.json',
                  repeat: true,
                  animate: true,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextSection() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          children: [
            // App Title
            ScaleTransition(
              scale: _scaleAnimation,
              child: AnimatedTextKit(
                animatedTexts: [
                  FadeAnimatedText(
                    'HortiKita',
                    textStyle: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: primaryColor,
                      letterSpacing: -1.0,
                      shadows: [
                        Shadow(
                          color: primaryLight.withValues(alpha: 0.3),
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    duration: const Duration(milliseconds: 1500),
                  ),
                ],
                isRepeatingAnimation: false,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Subtitle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: AnimatedTextKit(
                animatedTexts: [
                  TypewriterAnimatedText(
                    'Optimalkan Pekarangan Rumahmu',
                    textStyle: TextStyle(
                      fontSize: 18,
                      color: textSecondary,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                    speed: const Duration(milliseconds: 60),
                  ),
                ],
                isRepeatingAnimation: false,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Description
            FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                'Platform Digital untuk Petani Modern',
                style: TextStyle(
                  fontSize: 14,
                  color: textSecondary.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          // Loading Text
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              final loadingTexts = [
                'Mempersiapkan aplikasi...',
                'Memuat data tanaman...',
                'Menyiapkan fitur...',
                'Hampir selesai...',
              ];
              
              final currentIndex = (_progressAnimation.value * (loadingTexts.length - 1)).floor();
              final text = currentIndex < loadingTexts.length ? loadingTexts[currentIndex] : loadingTexts.last;
              
              return Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // Modern Progress Bar
          Container(
            width: 200,
            height: 6,
            decoration: BoxDecoration(
              color: primarySurface,
              borderRadius: BorderRadius.circular(3),
            ),
            child: AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: LinearProgressIndicator(
                    value: _progressAnimation.value,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(primaryLight),
                    minHeight: 6,
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Progress Percentage
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              final percentage = (_progressAnimation.value * 100).toInt();
              return Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: 12,
                  color: primaryLight,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}