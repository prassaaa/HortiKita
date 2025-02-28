class AppConstants {
  // API Endpoints
  static const String geminiApiEndpoint = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';
  
  // Firebase Collections
  static const String usersCollection = 'users';
  static const String plantsCollection = 'plants';
  static const String articlesCollection = 'articles';
  static const String chatHistoryCollection = 'chat_history';
  
  // Plant Categories
  static const List<String> plantCategories = [
    'Sayuran',
    'Buah',
    'Tanaman Hias',
    'Rempah',
    'Lainnya'
  ];
  
  // Article Categories
  static const List<String> articleCategories = [
    'Sayuran',
    'Buah',
    'Tanaman Hias',
    'Rempah',
    'Tips & Trik',
    'Perawatan',
    'Lainnya'
  ];
}