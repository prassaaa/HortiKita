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
  await Firebase.initializeApp();
  
  // Initialize services
  AnalyticsService();
  UserTrackingService();
  
  // Setup logger filter berdasarkan mode aplikasi
  Logger.level = kReleaseMode ? Level.warning : Level.debug;
  
  logger.d('Application starting in ${kReleaseMode ? "RELEASE" : "DEBUG"} mode');
  
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
    
    await _checkUserRole(auth.currentUser!.uid);
    
    // Only start tracking session if email is verified
    if (auth.currentUser!.emailVerified) {
      await UserTrackingService().startSession();
      logger.d('User tracking session started for verified user');
    } else {
      logger.d('Email not verified, tracking session not started');
    }
  } else {
    logger.d('No user logged in on app start');
  }
  
  runApp(const MyApp());
}

// Fungsi untuk memeriksa role user
Future<void> _checkUserRole(String userId) async {
  try {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    
    if (doc.exists) {
      final data = doc.data();
      logger.d('User data: $data');
      logger.d('Is admin: ${data != null && data['role'] == 'admin'}');
    } else {
      logger.d('User document does not exist');
    }
  } catch (e) {
    logger.e('Error checking user role: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Hapus AuthProvider karena error
        // Kita akan menggunakan Firebase Auth langsung
        ChangeNotifierProvider(create: (_) => ChatProvider("AIzaSyAI7gekjCmoGZksJBkSE-jf2Mm3lhdsYxc")),
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
  }
}