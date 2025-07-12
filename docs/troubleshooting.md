# 🛠️ Troubleshooting Guide

This guide helps you resolve common issues when setting up and running HortiKita.

## 📋 Table of Contents

- [Environment Setup Issues](#environment-setup-issues)
- [Firebase Configuration](#firebase-configuration)
- [API Key Problems](#api-key-problems)
- [Build Issues](#build-issues)
- [Runtime Errors](#runtime-errors)
- [Performance Issues](#performance-issues)
- [Network Problems](#network-problems)

---

## 🔧 Environment Setup Issues

### Flutter SDK Problems

#### Issue: `Flutter command not found`
```bash
# Solution 1: Add Flutter to PATH
export PATH="$PATH:/path/to/flutter/bin"

# Solution 2: Check Flutter installation
which flutter
flutter --version

# Solution 3: Reinstall Flutter
# Download from: https://flutter.dev/docs/get-started/install
```

#### Issue: `Doctor issues with Android SDK`
```bash
# Check flutter doctor
flutter doctor

# Common fixes:
flutter doctor --android-licenses  # Accept Android licenses
flutter config --android-sdk /path/to/android/sdk
```

#### Issue: `iOS development issues (macOS only)`
```bash
# Install Xcode command line tools
xcode-select --install

# Install CocoaPods
sudo gem install cocoapods

# Update pods
cd ios && pod install
```

### Dependencies Issues

#### Issue: `Pub get failed`
```bash
# Clear pub cache
flutter pub cache clean
flutter pub cache repair

# Delete pubspec.lock and retry
rm pubspec.lock
flutter pub get

# Check internet connection and proxy settings
```

---

## 🔥 Firebase Configuration

### Setup Issues

#### Issue: `Firebase not initialized`
```dart
// Error: [core/no-app] No Firebase App '[DEFAULT]' has been created

// Solution: Ensure Firebase.initializeApp() is called
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // ← Add this line
  runApp(MyApp());
}
```

#### Issue: `google-services.json not found`
```bash
# Android: Place file in android/app/google-services.json
# iOS: Place file in ios/Runner/GoogleService-Info.plist

# Verify file placement:
ls android/app/google-services.json
ls ios/Runner/GoogleService-Info.plist
```

### Authentication Issues

#### Issue: `Email verification not working`
```dart
// Check if user is properly signed in
final user = FirebaseAuth.instance.currentUser;
if (user != null && !user.emailVerified) {
  await user.sendEmailVerification();
}

// Check email in spam folder
// Verify Firebase Auth is enabled in console
```

#### Issue: `Permission denied on Firestore`
```javascript
// Update Firestore rules in Firebase Console
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

---

## 🔑 API Key Problems

### Gemini API Issues

#### Issue: `GEMINI_API_KEY not found`
```bash
# Solution 1: Check .env file exists
ls -la .env

# Solution 2: Copy from template
cp .env.example .env

# Solution 3: Verify .env content
cat .env
# Should contain: GEMINI_API_KEY=your_actual_key_here
```

#### Issue: `Invalid API key format`
```bash
# Gemini API keys should:
# - Start with "AIza"
# - Be approximately 39 characters long
# - Only contain alphanumeric characters and special chars

# Get new key from: https://makersuite.google.com/app/apikey
```

#### Issue: `API quota exceeded`
```bash
# Check API usage in Google Cloud Console
# Solutions:
# 1. Wait for quota reset
# 2. Upgrade to paid plan
# 3. Optimize API calls in code
```

### Environment Variable Issues

#### Issue: `Environment variables not loading`
```dart
// Debug environment loading
import 'package:flutter_dotenv/flutter_dotenv.dart';

void debugEnvironment() {
  print('Env loaded: ${dotenv.isEveryDefined(['GEMINI_API_KEY'])}');
  print('Available keys: ${dotenv.env.keys}');
}
```

---

## 🏗️ Build Issues

### Android Build Problems

#### Issue: `Gradle build failed`
```bash
# Solution 1: Clean build
flutter clean
flutter pub get
flutter build apk

# Solution 2: Update Gradle wrapper
cd android
./gradlew wrapper --gradle-version=7.6.1
```

#### Issue: `Multidex issue`
```gradle
// android/app/build.gradle
android {
    defaultConfig {
        multiDexEnabled true
    }
}

dependencies {
    implementation 'androidx.multidex:multidex:2.0.1'
}
```

#### Issue: `Minimum SDK version`
```gradle
// android/app/build.gradle
android {
    defaultConfig {
        minSdkVersion 21  // Ensure this matches pubspec.yaml
    }
}
```

### iOS Build Problems

#### Issue: `CocoaPods issues`
```bash
# Navigate to ios directory
cd ios

# Clean and reinstall pods
rm -rf Pods Podfile.lock
pod install --repo-update

# Update CocoaPods
sudo gem install cocoapods
pod setup
```

#### Issue: `Xcode signing issues`
```bash
# Open in Xcode
open ios/Runner.xcworkspace

# Set development team in:
# Runner → Signing & Capabilities → Team
```

---

## ⚡ Runtime Errors

### Common Flutter Errors

#### Issue: `RenderFlex overflow`
```dart
// Solution: Wrap with Flexible or Expanded
Flexible(
  child: Text('Long text that might overflow'),
)

// Or use SingleChildScrollView
SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  child: Row(children: [...]),
)
```

#### Issue: `setState called after dispose`
```dart
// Solution: Check if mounted before setState
if (mounted) {
  setState(() {
    // Update state
  });
}
```

### Network Errors

#### Issue: `SocketException: Failed host lookup`
```dart
// Check internet connectivity
import 'package:connectivity_plus/connectivity_plus.dart';

final connectivity = await Connectivity().checkConnectivity();
if (connectivity == ConnectivityResult.none) {
  // Handle no internet
}
```

#### Issue: `Certificate verification failed`
```bash
# For development only - DO NOT use in production
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

// In main()
HttpOverrides.global = MyHttpOverrides();
```

---

## 🚀 Performance Issues

### Memory Problems

#### Issue: `App running out of memory`
```dart
// Solution 1: Dispose controllers properly
@override
void dispose() {
  _controller.dispose();
  _scrollController.dispose();
  super.dispose();
}

// Solution 2: Use AutomaticKeepAliveClientMixin sparingly
// Solution 3: Implement lazy loading for large lists
```

#### Issue: `Images consuming too much memory`
```dart
// Use cached_network_image with size limits
CachedNetworkImage(
  imageUrl: imageUrl,
  memCacheWidth: 300,  // Limit memory cache size
  memCacheHeight: 300,
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.error),
)
```

### UI Performance

#### Issue: `Jank/stuttering animations`
```dart
// Use const constructors
const MyWidget({super.key});

// Avoid expensive operations in build()
class MyWidget extends StatelessWidget {
  // Pre-calculate expensive values
  static const expensiveValue = calculateExpensiveValue();
  
  @override
  Widget build(BuildContext context) {
    return Text('$expensiveValue');
  }
}
```

---

## 🌐 Network Problems

### API Communication Issues

#### Issue: `HTTP 403 Forbidden`
```dart
// Check API key permissions
// Verify request headers
final response = await http.post(
  Uri.parse(apiUrl),
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $apiKey',  // If required
  },
  body: jsonEncode(data),
);
```

#### Issue: `Timeout errors`
```dart
// Increase timeout duration
final client = http.Client();
try {
  final response = await client
      .get(Uri.parse(url))
      .timeout(Duration(seconds: 30));
} catch (e) {
  // Handle timeout
} finally {
  client.close();
}
```

### Firebase Connection Issues

#### Issue: `Firestore offline`
```dart
// Enable offline persistence
FirebaseFirestore.instance.enablePersistence();

// Handle connection state
FirebaseFirestore.instance
    .enableNetwork()
    .then((_) => print('Network enabled'))
    .catchError((error) => print('Failed to enable network: $error'));
```

---

## 🔍 Debugging Tips

### Logging and Debugging

#### Enable detailed logging
```dart
// In main.dart
import 'package:logger/logger.dart';

final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 3,
    errorMethodCount: 8,
    lineLength: 120,
    colors: true,
    printEmojis: true,
    printTime: true,
  ),
);

// Use throughout app
logger.d('Debug message');
logger.i('Info message');
logger.w('Warning message');
logger.e('Error message');
```

#### Flutter Inspector
```bash
# Enable widget inspector
flutter run --debug

# Open DevTools in browser
# Look for "Flutter Inspector" tab
```

### Performance Profiling

#### CPU Profiling
```bash
# Run with profiling
flutter run --profile

# Open DevTools for performance analysis
```

#### Memory Profiling
```bash
# Check memory usage
flutter run --debug
# Use DevTools → Memory tab
```

---

## 📞 Getting Help

### When to Seek Help

If you've tried the solutions above and still have issues:

1. **Search existing issues**: [GitHub Issues](https://github.com/prassaaa/HortiKita/issues)
2. **Create new issue**: Include detailed error messages and steps to reproduce
3. **Join discussions**: [GitHub Discussions](https://github.com/prassaaa/HortiKita/discussions)
4. **Check documentation**: [Project Wiki](https://github.com/prassaaa/HortiKita/wiki)

### Information to Include

When reporting issues, please include:

- **Flutter version**: `flutter --version`
- **Operating system**: Windows/macOS/Linux version
- **Device information**: Physical device or emulator
- **Error messages**: Complete error logs
- **Steps to reproduce**: Detailed reproduction steps
- **Expected vs actual**: What should happen vs what actually happens

### Community Support

- **Stack Overflow**: Tag questions with `flutter` and `hortikita`
- **Flutter Community**: [Flutter Discord](https://discord.gg/flutter)
- **Reddit**: r/FlutterDev for general Flutter questions

---

<p align="center">
  <strong>Still need help?</strong><br>
  <a href="mailto:support@hortikita.app">📧 Contact Support</a> •
  <a href="https://github.com/prassaaa/HortiKita/issues">🐛 Report Bug</a> •
  <a href="https://github.com/prassaaa/HortiKita/discussions">💬 Ask Community</a>
</p>
