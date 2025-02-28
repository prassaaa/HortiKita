import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  UserModel? _userModel;
  bool _isLoading = false;
  String _error = '';

  // Getters
  UserModel? get userModel => _userModel;
  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => currentUser != null;
  bool get isLoading => _isLoading;
  String get error => _error;

  // Constructor
  AuthProvider() {
    _init();
  }

  // Initialize - listen for auth changes
  Future<void> _init() async {
    _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        await _fetchUserData();
      } else {
        _userModel = null;
      }
      notifyListeners();
    });
  }

  // Fetch user data from Firestore
  Future<void> _fetchUserData() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      if (currentUser == null) {
        _userModel = null;
        return;
      }
      
      final doc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      
      if (doc.exists) {
        _userModel = UserModel.fromFirestore(doc);
      } else {
        // Create user document if it doesn't exist
        final now = DateTime.now();
        final newUser = UserModel(
          uid: currentUser!.uid,
          email: currentUser!.email ?? '',
          name: currentUser!.displayName ?? '',
          photoUrl: currentUser!.photoURL,
          createdAt: now,
          updatedAt: now,
        );
        
        // Save to Firestore
        await _firestore
            .collection('users')
            .doc(currentUser!.uid)
            .set(newUser.toMap());
            
        _userModel = newUser;
      }
    } catch (e) {
      print('Error fetching user data: $e');
      _error = e.toString();
      _userModel = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sign Up
  Future<void> signUp(String name, String email, String password) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      // Create user with email and password
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update display name
      await userCredential.user?.updateDisplayName(name);
      
      // Create user document in Firestore
      final now = DateTime.now();
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'name': name,
        'email': email,
        'photoUrl': null,
        'createdAt': now,
        'updatedAt': now,
      });
      
      // Refresh user data after some delay to ensure Firebase has propagated the changes
      await Future.delayed(const Duration(milliseconds: 500));
      await _fetchUserData();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Sign In
  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Data will be fetched by the auth state listener
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      await _auth.signOut();
      _userModel = null;
    } catch (e) {
      _error = e.toString();
      print('Error signing out: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update Profile
  Future<void> updateProfile({String? name, String? photoUrl}) async {
    if (currentUser == null) return;
    
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null && name.isNotEmpty) {
        updateData['name'] = name;
        await currentUser!.updateDisplayName(name);
      }

      if (photoUrl != null) {
        updateData['photoUrl'] = photoUrl;
        await currentUser!.updatePhotoURL(photoUrl);
      }

      await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .update(updateData);

      await _fetchUserData();
    } catch (e) {
      _error = e.toString();
      print('Error updating profile: $e');
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Reset Password
  Future<void> resetPassword(String email) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}