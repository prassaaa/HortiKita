import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();
  
  UserModel? _userModel;
  bool _isLoading = false;
  String _error = '';

  // Getters
  UserModel? get userModel => _userModel;
  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => currentUser != null;
  bool get isEmailVerified => currentUser?.emailVerified ?? false;
  bool get isLoading => _isLoading;
  String get error => _error;

  // Metode untuk memeriksa apakah user adalah admin
  bool get isAdmin {
    final role = _userModel?.role;
    _logger.d('Checking isAdmin: role=$role, result=${role == 'admin'}');
    return role == 'admin';
  }

  // Constructor
  AuthProvider() {
    _init();
  }

  // Initialize - listen for auth changes
  Future<void> _init() async {
    _logger.d('Initializing AuthProvider');
    _auth.authStateChanges().listen((User? user) async {
      _logger.d('Auth state changed. User: ${user?.email}');
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
        _logger.d('Current user is null, userModel reset to null');
        return;
      }
      
      _logger.d('Fetching user data for: ${currentUser!.email}');
      final doc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      
      if (doc.exists) {
        _userModel = UserModel.fromFirestore(doc);
        _logger.d('User data fetched: ${_userModel?.email}, role: ${_userModel?.role}, isAdmin: $isAdmin');
      } else {
        _logger.d('User document does not exist, creating new one');
        // Create user document if it doesn't exist
        final now = DateTime.now();
        final newUser = UserModel(
          uid: currentUser!.uid,
          email: currentUser!.email ?? '',
          name: currentUser!.displayName ?? '',
          photoUrl: currentUser!.photoURL,
          role: 'user', // Default role
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
      _logger.e('Error fetching user data: $e');
      _error = e.toString();
      _userModel = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Public method to reload user data
  Future<void> reloadUserData() async {
    _logger.d('Manual reload of user data requested');
    return await _fetchUserData();
  }

  // Direct method to check admin status from Firestore
  Future<bool> checkIsAdmin() async {
    if (_auth.currentUser == null) {
      _logger.d('checkIsAdmin: No user logged in');
      return false;
    }
    
    try {
      _logger.d('checkIsAdmin: Checking directly from Firestore');
      final doc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();
          
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final role = data['role'] as String?;
        final isAdmin = role == 'admin';
        _logger.d('checkIsAdmin: User role=$role, isAdmin=$isAdmin');
        return isAdmin;
      }
      _logger.d('checkIsAdmin: User document does not exist');
      return false;
    } catch (e) {
      _logger.e('Error in checkIsAdmin: $e');
      return false;
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
      
      // Send email verification
      await userCredential.user?.sendEmailVerification();
      _logger.i('Email verification sent to: $email');
      
      // Update display name
      await userCredential.user?.updateDisplayName(name);
      
      // Create user document in Firestore
      final now = DateTime.now();
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'name': name,
        'email': email,
        'photoUrl': null,
        'role': 'user', // Set default role
        'createdAt': now,
        'updatedAt': now,
      });
      
      // DON'T auto fetch user data - let verification screen handle it
      _logger.d('User registered successfully, verification email sent');
    } catch (e) {
      _logger.e('Error during sign up: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sign In
  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      _logger.d('Attempting to sign in: $email');
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Data will be fetched by the auth state listener, but let's also fetch it manually just in case
      _logger.d('Sign in successful, manually fetching user data');
      await Future.delayed(const Duration(milliseconds: 500)); // Small delay to ensure auth state is updated
      await _fetchUserData();
      _logger.d('After login and manual fetch: isAdmin=$isAdmin');
    } catch (e) {
      _logger.e('Error during sign in: $e');
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
      _logger.e('Error signing out: $e');
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
      _logger.e('Error updating profile: $e');
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
      _logger.e('Error resetting password: $e');
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create Admin User - No email verification required
  Future<void> createAdminUser(String email, String password, String name) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      // Buat user dengan email dan password
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update display name
      await userCredential.user?.updateDisplayName(name);
      
      // Buat dokumen user di Firestore dengan role admin
      final now = DateTime.now();
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'name': name,
        'email': email,
        'photoUrl': null,
        'role': 'admin', // Set role sebagai admin
        'createdAt': now,
        'updatedAt': now,
      });
      
      _logger.i('Admin user created successfully - email verification not required');
      await _fetchUserData();
    } catch (e) {
      _logger.e('Error during admin creation: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Set a user as admin
  Future<void> setUserAsAdmin(String userId) async {
    try {
      _logger.d('Setting user $userId as admin');
      await _firestore.collection('users').doc(userId).update({
        'role': 'admin',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // If this is the current user, refresh the data
      if (currentUser?.uid == userId) {
        await _fetchUserData();
      }
    } catch (e) {
      _logger.e('Error setting user as admin: $e');
      throw Exception('Failed to set user as admin: $e');
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
    
    _isLoading = true;
    _error = '';
    notifyListeners();
    
    try {
      await currentUser!.sendEmailVerification();
      _logger.i('Email verification sent to: ${currentUser!.email}');
    } catch (e) {
      _logger.e('Error sending email verification: $e');
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Reload user to get latest verification status
  Future<void> reloadUser() async {
    if (currentUser == null) return;
    
    try {
      await currentUser!.reload();
      _logger.d('User reloaded, emailVerified: ${currentUser!.emailVerified}');
      notifyListeners();
    } catch (e) {
      _logger.e('Error reloading user: $e');
      rethrow;
    }
  }
  
  // Check if user needs email verification (admin users don't need it)
  bool get needsEmailVerification {
    if (currentUser == null) return false;
    if (currentUser!.emailVerified) return false;
    
    // Admin users don't need email verification
    if (isAdmin) {
      _logger.d('Admin user detected, email verification not required');
      return false;
    }
    
    // Regular users need email verification
    return true;
  }
}