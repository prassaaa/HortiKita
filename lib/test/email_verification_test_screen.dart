import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';

class EmailVerificationTestScreen extends StatefulWidget {
  const EmailVerificationTestScreen({super.key});

  @override
  State<EmailVerificationTestScreen> createState() => _EmailVerificationTestScreenState();
}

class _EmailVerificationTestScreenState extends State<EmailVerificationTestScreen> {
  final Logger _logger = Logger();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Verification Test'),
        backgroundColor: const Color(0xFF2D5A27),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User Information',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Email: ${user?.email ?? 'Not logged in'}'),
                    Text('UID: ${user?.uid ?? 'N/A'}'),
                    Text('Display Name: ${user?.displayName ?? 'N/A'}'),
                    Text('Email Verified: ${user?.emailVerified ?? false}'),
                    Text('Creation Time: ${user?.metadata.creationTime?.toString() ?? 'N/A'}'),
                    Text('Last Sign In: ${user?.metadata.lastSignInTime?.toString() ?? 'N/A'}'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            if (user != null && !user.emailVerified) ...[
              ElevatedButton(
                onPressed: () async {
                  try {
                    await user.sendEmailVerification();
                    _logger.i('Email verification sent');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Email verification sent!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    _logger.e('Error sending verification: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Send Email Verification'),
              ),
              
              const SizedBox(height: 8),
            ],
            
            ElevatedButton(
              onPressed: () async {
                try {
                  await user?.reload();
                  setState(() {});
                  _logger.d('User reloaded, emailVerified: ${user?.emailVerified}');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('User reloaded. Email verified: ${user?.emailVerified}'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                } catch (e) {
                  _logger.e('Error reloading user: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Reload User Status'),
            ),
            
            const SizedBox(height: 8),
            
            ElevatedButton(
              onPressed: () async {
                try {
                  await _auth.signOut();
                  Navigator.of(context).pop();
                  _logger.d('User signed out');
                } catch (e) {
                  _logger.e('Error signing out: $e');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Sign Out'),
            ),
            
            const SizedBox(height: 24),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Instructions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. Register dengan email baru\n'
                      '2. Cek apakah redirect ke EmailVerificationScreen\n'
                      '3. Buka email dan klik link verifikasi\n'
                      '4. Kembali ke app dan tap "Saya Sudah Verifikasi"\n'
                      '5. Harus redirect ke HomeScreen\n'
                      '6. Login dengan akun yang sama harus langsung ke HomeScreen',
                      style: TextStyle(height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
