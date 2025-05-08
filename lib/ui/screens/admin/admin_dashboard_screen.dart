import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../auth/login_screen.dart';
import 'manage_plants_screen.dart';
import 'manage_articles_screen.dart';
import 'manage_users_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _userName = "Admin";
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();
            
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          if (mounted) {
            setState(() {
              _userName = data['name'] ?? "Admin";
            });
          }
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Definisi warna tema
    const Color primaryGreen = Color(0xFF4CAF50);
    const Color lightGreen = Color(0xFFE8F5E9);
    const Color white = Colors.white;

    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(
            color: primaryGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: primaryGreen),
            onPressed: _signOut,
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: lightGreen,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selamat Datang, $_userName',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Kelola konten aplikasi Hortikultura Anda di sini',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF558B2F),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Title
                  const Text(
                    'Menu Admin',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Admin Menu Grid
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      childAspectRatio: 1.0,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      padding: const EdgeInsets.all(8),
                      children: [
                        _buildAdminMenuCard(
                          context,
                          'Kelola Tanaman',
                          Icons.eco,
                          primaryGreen,
                          lightGreen,
                          () {
                            // Navigasi ke layar kelola tanaman
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ManagePlantsScreen()),
                            );
                          },
                        ),
                        _buildAdminMenuCard(
                          context,
                          'Kelola Artikel',
                          Icons.article_outlined,
                          primaryGreen,
                          lightGreen,
                          () {
                            // Navigasi ke layar kelola artikel
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ManageArticlesScreen()),
                            );
                          },
                        ),
                        _buildAdminMenuCard(
                          context,
                          'Kelola Pengguna',
                          Icons.people,
                          primaryGreen,
                          lightGreen,
                          () {
                            // Navigasi ke layar kelola pengguna
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ManageUsersScreen()),
                            );
                          },
                        ),
                        _buildAdminMenuCard(
                          context,
                          'Statistik',
                          Icons.bar_chart,
                          primaryGreen,
                          lightGreen,
                          () {
                            // Implementasi statistik nanti
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Fitur ini akan segera hadir'),
                                backgroundColor: primaryGreen,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  // Debug info in development mode
                  if (!kReleaseMode) ...[
                    const Divider(),
                    const Text('Debug Info', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          final user = _auth.currentUser;
                          if (user != null) {
                            final doc = await _firestore
                                .collection('users')
                                .doc(user.uid)
                                .get();
                                
                            if (doc.exists) {
                              final data = doc.data();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('User data: $data'),
                                    duration: const Duration(seconds: 10),
                                  ),
                                );
                              }
                            }
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                      child: const Text('Check User Data'),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildAdminMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    Color primary,
    Color background,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: background, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: background,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 32,
                color: primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}