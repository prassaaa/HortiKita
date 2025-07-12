import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

class AdminEmailBypassTestScreen extends StatefulWidget {
  const AdminEmailBypassTestScreen({super.key});

  @override
  State<AdminEmailBypassTestScreen> createState() => _AdminEmailBypassTestScreenState();
}

class _AdminEmailBypassTestScreenState extends State<AdminEmailBypassTestScreen> {
  final Logger _logger = Logger();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  
  bool _isLoading = false;
  String _message = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createAdminUser() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty || _nameController.text.isEmpty) {
      setState(() {
        _message = 'Please fill all fields';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = 'Creating admin user...';
    });

    try {
      // Create admin user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Update display name
      await userCredential.user?.updateDisplayName(_nameController.text.trim());

      // Create user document with admin role
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'photoUrl': null,
        'role': 'admin', // Set as admin
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _message = 'Admin user created successfully!\n'
                  'Email: ${_emailController.text}\n'
                  'Role: admin\n'
                  'Email Verified: ${userCredential.user?.emailVerified ?? false}\n'
                  'Note: Admin users can access dashboard without email verification';
      });

      _logger.i('Admin user created: ${_emailController.text}');
      
    } catch (e) {
      setState(() {
        _message = 'Error creating admin user: $e';
      });
      _logger.e('Error creating admin user: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkCurrentUserStatus() async {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() {
        _message = 'No user logged in';
      });
      return;
    }

    try {
      await user.reload();
      final doc = await _firestore.collection('users').doc(user.uid).get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final role = data['role'] as String?;
        
        setState(() {
          _message = 'Current User Status:\n'
                    'Email: ${user.email}\n'
                    'Email Verified: ${user.emailVerified}\n'
                    'Role: ${role ?? 'user'}\n'
                    'UID: ${user.uid}\n\n'
                    'Access Rules:\n'
                    '- Admin users: Dashboard access regardless of email verification\n'
                    '- Regular users: Must verify email before dashboard access';
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Error checking user status: $e';
      });
    }
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      setState(() {
        _message = 'Signed out successfully';
      });
    } catch (e) {
      setState(() {
        _message = 'Error signing out: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Email Bypass Test'),
        backgroundColor: const Color(0xFF2D5A27),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Test Admin Email Verification Bypass',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Admin Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Admin Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _createAdminUser,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D5A27),
                foregroundColor: Colors.white,
              ),
              child: _isLoading 
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : const Text('Create Admin User'),
            ),
            
            const SizedBox(height: 12),
            
            ElevatedButton(
              onPressed: _checkCurrentUserStatus,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Check Current User Status'),
            ),
            
            const SizedBox(height: 12),
            
            ElevatedButton(
              onPressed: _signOut,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Sign Out'),
            ),
            
            const SizedBox(height: 24),
            
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _message.isEmpty ? 'Test results will appear here...' : _message,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
