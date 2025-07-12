import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/user_model.dart';
import 'firebase_service.dart';
import 'package:logger/logger.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseService().auth;
  final FirebaseFirestore _firestore = FirebaseService().firestore;
  final Logger _logger = Logger();
  
  // Get current user
  User? get currentUser => _auth.currentUser;
  
  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // Sign up with email and password
  Future<UserCredential> signUpWithEmailAndPassword(
    String name,
    String email,
    String password,
  ) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Send email verification
      await result.user!.sendEmailVerification();
      _logger.i('Email verification sent to: $email');
      
      // Create user profile
      await _createUserProfile(result.user!.uid, name, email);
      
      // Update display name
      await result.user!.updateDisplayName(name);
      
      return result;
    } catch (e) {
      rethrow;
    }
  }
  
  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
  
  // Create user profile in Firestore
  Future<void> _createUserProfile(String uid, String name, String email) async {
    final now = DateTime.now();
    
    await _firestore.collection('users').doc(uid).set({
      'name': name,
      'email': email,
      'photoUrl': null,
      'createdAt': now,
      'updatedAt': now,
    });
  }
  
  // Get user model
  Future<UserModel?> getUserModel() async {
    if (currentUser == null) return null;
    
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      
      return null;
    } catch (e) {
      _logger.e('Error getting user model: $e');
      return null;
    }
  }
  
  // Send email verification
  Future<void> sendEmailVerification() async {
    if (currentUser == null) {
      throw Exception('No user is currently logged in');
    }
    
    if (currentUser!.emailVerified) {
      throw Exception('Email is already verified');
    }
    
    try {
      await currentUser!.sendEmailVerification();
      _logger.i('Email verification sent to: ${currentUser!.email}');
    } catch (e) {
      _logger.e('Error sending email verification: $e');
      rethrow;
    }
  }
  
  // Check if email is verified
  bool get isEmailVerified => currentUser?.emailVerified ?? false;
  
  // Reload user to get latest verification status
  Future<void> reloadUser() async {
    if (currentUser == null) return;
    
    try {
      await currentUser!.reload();
      _logger.d('User reloaded, emailVerified: ${currentUser!.emailVerified}');
    } catch (e) {
      _logger.e('Error reloading user: $e');
      rethrow;
    }
  }
}