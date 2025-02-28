import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  // Singleton pattern
  static final FirebaseService _instance = FirebaseService._internal();
  
  factory FirebaseService() {
    return _instance;
  }
  
  FirebaseService._internal();
  
  // Firebase instances
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;
  
  // Initialize Firebase
  static Future<void> initializeFirebase() async {
    await Firebase.initializeApp();
  }
  
  // Collection references
  CollectionReference<Map<String, dynamic>> get usersCollection => 
      firestore.collection('users');
  
  CollectionReference<Map<String, dynamic>> get plantsCollection => 
      firestore.collection('plants');
  
  CollectionReference<Map<String, dynamic>> get articlesCollection => 
      firestore.collection('articles');
  
  CollectionReference<Map<String, dynamic>> get chatHistoryCollection => 
      firestore.collection('chat_history');
}