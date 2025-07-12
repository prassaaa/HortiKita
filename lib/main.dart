import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'data/providers/chat_provider.dart';
import 'data/providers/plant_provider.dart';
import 'data/providers/article_provider.dart';
import 'data/providers/analytics_provider.dart';
import 'data/providers/user_engagement_provider.dart';
import 'services/analytics_service.dart';
import 'services/user_tracking_service.dart';
import 'services/environment_service.dart';
import 'ui/screens/splash/splash_screen.dart';
import 'ui/themes/app_theme.dart';

// Inisialisasi logger global
final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 2,
    errorMethodCount: 8,
    lineLength: 120,
    colors: true,
    printEmojis: true,
    printTime: true,
  ),
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables securely
  await EnvironmentService.initialize();
  
  await Firebase.initializeApp();
  
  // Initialize services
  AnalyticsService();
  UserTrackingService();
  
  // Setup logger filter berdasarkan mode aplikasi
  Logger.level = kReleaseMode ? Level.warning : Level.debug;
  
  logger.d('Application starting in ${kReleaseMode ? "RELEASE" : "DEBUG"} mode');
  
  // Log environment status in development
  if (!kReleaseMode) {
    EnvironmentService.instance.logEnvironmentStatus();
  }
  
  // Di mode development, periksa dan buat akun admin jika belum ada
  if (!kReleaseMode) {
    logger.d('Running in development mode');
    // Admin creation disabled to avoid permission issues
    // You can create admin manually through register screen
  }
  
  // Debug: Cek status login saat aplikasi mulai
  final auth = FirebaseAuth.instance;
  if (auth.currentUser != null) {
    logger.d('User already logged in: ${auth.currentUser!.email}');
    logger.d('Email verified: ${auth.currentUser!.emailVerified}');
    
    final userRole = await _checkUserRole(auth.currentUser!.uid);
    
    // Start tracking session if user is admin OR email is verified
    if (userRole == 'admin' || auth.currentUser!.emailVerified) {
      await UserTrackingService().startSession();
      if (userRole == 'admin') {
        logger.d('User tracking session started for admin user (no email verification required)');
      } else {
        logger.d('User tracking session started for verified user');
      }
    } else {
      logger.d('Regular user email not verified, tracking session not started');
    }
  } else {
    logger.d('No user logged in on app start');
  }
  
  runApp(const MyApp());
}

// Fungsi untuk memeriksa role user
Future<String?> _checkUserRole(String userId) async {
  try {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    
    if (doc.exists) {
      final data = doc.data();
      final role = data != null ? data['role'] as String? : null;
      logger.d('User data: $data');
      logger.d('Is admin: ${role == 'admin'}');
      return role;
    } else {
      logger.d('User document does not exist');
      return null;
    }
  } catch (e) {
    logger.e('Error checking user role: $e');
    return null;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      final geminiApiKey = EnvironmentService.instance.geminiApiKey;
      
      return MultiProvider(
        providers: [
          // Hapus AuthProvider karena error
          // Kita akan menggunakan Firebase Auth langsung
          ChangeNotifierProvider(create: (_) => ChatProvider(geminiApiKey)),
          ChangeNotifierProvider(create: (_) => PlantProvider()),
          ChangeNotifierProvider(create: (_) => ArticleProvider()),
          ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
          ChangeNotifierProvider(create: (_) => UserEngagementProvider()),
        ],
        child: MaterialApp(
          title: 'Hortikultura App',
          theme: AppTheme.light,
          debugShowCheckedModeBanner: false,
          home: const SplashScreen(),
        ),
      );
    } catch (e) {
      logger.e('Failed to initialize app: $e');
      
      // Return error screen instead of crashing
      return MaterialApp(
        title: 'Hortikultura App',
        theme: AppTheme.light,
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Configuration Error',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Please check your .env configuration.\n\nError: $e',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}