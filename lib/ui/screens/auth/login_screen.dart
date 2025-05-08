import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'register_screen.dart';
import 'package:flutter/foundation.dart';
import '../home/home_screen.dart';
import '../admin/admin_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _logger = Logger();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Login dengan Firebase Auth langsung
        _logger.d('Attempting login with: ${_emailController.text.trim()}');
        
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        _logger.d('Login successful, checking user role');
        
        // Periksa role user di Firestore
        final user = _auth.currentUser;
        if (user != null) {
          // Tambahkan delay untuk memastikan auth state terupdate
          await Future.delayed(const Duration(milliseconds: 500));
          
          final doc = await _firestore
              .collection('users')
              .doc(user.uid)
              .get();
              
          if (!mounted) return;
              
          if (doc.exists) {
            final data = doc.data() as Map<String, dynamic>;
            final role = data['role'] as String?;
            final isAdmin = role == 'admin';
            
            _logger.d('User: ${user.email}, role: $role, isAdmin: $isAdmin');
            
            if (isAdmin) {
              _logger.d('User is admin, navigating to AdminDashboardScreen');
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
              );
              return;
            }
          }
          
          // Jika bukan admin atau dokumen tidak ada, navigasi ke HomeScreen
          _logger.d('User is not admin, navigating to HomeScreen');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage;
        if (e.code == 'user-not-found') {
          errorMessage = 'Email tidak ditemukan';
        } else if (e.code == 'wrong-password') {
          errorMessage = 'Password salah';
        } else if (e.code == 'invalid-credential') {
          errorMessage = 'Email atau password tidak valid';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'Format email tidak valid';
        } else if (e.code == 'too-many-requests') {
          errorMessage = 'Terlalu banyak percobaan. Coba lagi nanti';
        } else {
          errorMessage = 'Error: ${e.message}';
        }
        
        _logger.e('Firebase auth error: $errorMessage');
        
        if (!mounted) return;
        _showErrorDialog(errorMessage);
      } catch (e) {
        _logger.e('Unexpected error during login: $e');
        if (!mounted) return;
        _showErrorDialog('Terjadi kesalahan: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error Login'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK', style: TextStyle(color: Color(0xFF4CAF50))),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Definisi warna tema yang sama dengan HomeScreen
    const Color primaryGreen = Color(0xFF4CAF50);
    const Color lightGreen = Color(0xFFE8F5E9);
    const Color white = Colors.white;

    return Scaffold(
      backgroundColor: white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: lightGreen,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withAlpha((0.1 * 255).toInt()),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 40,
                        backgroundColor: primaryGreen,
                        child: Icon(
                          Icons.eco,
                          size: 48,
                          color: white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Selamat Datang',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Masuk untuk mengakses aplikasi Hortikultura',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF558B2F),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Form Section
                SizedBox(
                  width: double.infinity,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Email Field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: const Icon(Icons.email, color: primaryGreen),
                            filled: true,
                            fillColor: lightGreen,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Silakan masukkan email';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                .hasMatch(value)) {
                              return 'Masukkan email yang valid';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock, color: primaryGreen),
                            filled: true,
                            fillColor: lightGreen,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                color: primaryGreen,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Silakan masukkan password';
                            }
                            if (value.length < 6) {
                              return 'Password minimal 6 karakter';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),

                        // Forgot Password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _showForgotPasswordDialog,
                            child: const Text(
                              'Lupa Password?',
                              style: TextStyle(color: primaryGreen),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                              disabledBackgroundColor: primaryGreen.withAlpha(128),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              shadowColor: Colors.grey.withAlpha((0.3 * 255).toInt()),
                              elevation: 2,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Masuk',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Register Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Belum punya akun?',
                      style: TextStyle(color: Colors.grey),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RegisterScreen()),
                        );
                      },
                      child: const Text(
                        'Daftar',
                        style: TextStyle(
                          color: primaryGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Dev Mode Section
                if (!kReleaseMode) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const Text(
                    'Dev Mode Only',
                    style: TextStyle(color: Colors.grey),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      // Login sebagai admin
                      _emailController.text = 'admin@hortikultura.app';
                      _passwordController.text = 'admin123';
                      _login();
                    },
                    child: const Text('Login sebagai Admin'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () async {
                      final user = _auth.currentUser;
                      if (user == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Belum ada user yang login')),
                        );
                        return;
                      }
                      
                      try {
                        setState(() {
                          _isLoading = true;
                        });
                        
                        // Ubah role secara langsung di Firestore
                        await _firestore
                            .collection('users')
                            .doc(user.uid)
                            .update({'role': 'admin'});
                            
                        setState(() {
                          _isLoading = false;
                        });
                        
                        // Notifikasi berhasil
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Role berhasil diubah menjadi admin'),
                            backgroundColor: primaryGreen,
                          ),
                        );
                        
                        // Navigasi ke AdminDashboardScreen
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                        );
                      } catch (e) {
                        setState(() {
                          _isLoading = false;
                        });
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    },
                    child: const Text('Force Set as Admin'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () async {
                      final user = _auth.currentUser;
                      if (user == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Belum ada user yang login')),
                        );
                        return;
                      }
                      
                      try {
                        // Cek data user
                        final doc = await _firestore
                            .collection('users')
                            .doc(user.uid)
                            .get();
                            
                        if (doc.exists) {
                          final data = doc.data() as Map<String, dynamic>;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('User data: $data'),
                              duration: const Duration(seconds: 5),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('User document not found'),
                            ),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    },
                    child: const Text('Check User Data'),
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final TextEditingController resetEmailController = TextEditingController();
    const Color primaryGreen = Color(0xFF4CAF50);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Reset Password',
          style: TextStyle(color: Color(0xFF2E7D32)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Masukkan email Anda untuk menerima link reset password',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: resetEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                filled: true,
                fillColor: const Color(0xFFE8F5E9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal', style: TextStyle(color: primaryGreen)),
          ),
          TextButton(
            onPressed: () async {
              final email = resetEmailController.text.trim();
              if (email.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Silakan masukkan email')),
                );
                return;
              }

              // Simpan referensi ke BuildContext sebelum async
              final navigatorContext = dialogContext;

              try {
                await _auth.sendPasswordResetEmail(email: email);
                
                // Periksa apakah dialog context masih ada
                if (!mounted) return;
                
                // Pop dialog menggunakan navigator dari dialogContext yang disimpan
                // ignore: use_build_context_synchronously
                Navigator.pop(navigatorContext);
                
                // Gunakan context state untuk Scaffold messenger
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Link reset password telah dikirim ke email Anda'),
                    backgroundColor: primaryGreen,
                  ),
                );
              } catch (e) {
                _logger.e('Error saat reset password: $e');
                
                // Periksa apakah dialog context masih ada
                if (!mounted) return;
                
                // Pop dialog menggunakan navigator dari dialogContext yang disimpan
                // ignore: use_build_context_synchronously
                Navigator.pop(navigatorContext);
                
                // Gunakan context state untuk Scaffold messenger
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Kirim', style: TextStyle(color: primaryGreen)),
          ),
        ],
      ),
    );
  }
}