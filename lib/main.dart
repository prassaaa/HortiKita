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
  
  // Setup logger filter berdasarkan mode aplikasi
  Logger.level = kReleaseMode ? Level.warning : Level.debug;
  
  logger.d('Application starting in ${kReleaseMode ? "RELEASE" : "DEBUG"} mode');
  
  // Di mode development, periksa dan buat akun admin jika belum ada
  if (!kReleaseMode) {
    logger.d('Running in development mode, checking admin account');
    await _ensureAdminExists();
  }
  
  // Debug: Cek status login saat aplikasi mulai
  final auth = FirebaseAuth.instance;
  if (auth.currentUser != null) {
    logger.d('User already logged in: ${auth.currentUser!.email}');
    await _checkUserRole(auth.currentUser!.uid);
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

// Fungsi untuk memastikan ada akun admin
Future<void> _ensureAdminExists() async {
  try {
    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;
    
    // Periksa apakah ada admin
    final snapshot = await firestore
        .collection('users')
        .where('role', isEqualTo: 'admin')
        .limit(1)
        .get();
    
    if (snapshot.docs.isEmpty) {
      logger.d('No admin account found, creating one');
      
      // Tidak ada admin, buat akun admin
      final adminEmail = 'admin@hortikita.app';
      final adminPassword = 'admin123';
      
      try {
        // Periksa apakah email sudah digunakan
        final userCred = await auth.createUserWithEmailAndPassword(
          email: adminEmail,
          password: adminPassword,
        );
        
        // Buat data user admin
        await firestore.collection('users').doc(userCred.user!.uid).set({
          'name': 'Administrator',
          'email': adminEmail,
          'role': 'admin',
          'photoUrl': null,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        logger.i('Admin account created successfully');
        
        // Sign out setelah membuat
        await auth.signOut();
      } catch (e) {
        if (e is FirebaseAuthException && e.code == 'email-already-in-use') {
          logger.d('Admin email already exists, trying to sign in');
          
          // Email sudah digunakan, cek apakah sudah admin
          try {
            // Sign in untuk mendapatkan UID
            final userCred = await auth.signInWithEmailAndPassword(
              email: adminEmail, 
              password: adminPassword,
            );
            
            // Update role menjadi admin
            await firestore.collection('users').doc(userCred.user!.uid).update({
              'role': 'admin',
              'updatedAt': FieldValue.serverTimestamp(),
            });
            
            logger.i('Existing account updated to admin role');
            
            // Sign out setelah update
            await auth.signOut();
          } catch (signInError) {
            logger.e('Error signing in to existing account: $signInError');
          }
        } else {
          logger.e('Error creating admin account: $e');
        }
      }
    } else {
      logger.i('Admin account already exists');
    }
  } catch (e) {
    logger.e('Error checking admin account: $e');
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