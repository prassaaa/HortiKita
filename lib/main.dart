import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';
import 'data/providers/auth_provider.dart';
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
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
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