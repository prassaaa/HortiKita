import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'dart:async';
import '../../../services/auth_service.dart';
import '../home/home_screen.dart';
import 'login_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> 
    with TickerProviderStateMixin {
  final Logger _logger = Logger();
  final AuthService _authService = AuthService();
  Timer? _timer;
  bool _isLoading = false;
  bool _canResendEmail = false;
  int _resendCountdown = 60;
  Timer? _countdownTimer;
  
  // Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startEmailVerificationTimer();
    _startResendCountdown();
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    _countdownTimer?.cancel();
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }
  
  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _fadeController.forward();
    _pulseController.repeat(reverse: true);
  }
  
  void _startEmailVerificationTimer() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      await _checkEmailVerification();
    });
  }
  
  void _startResendCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          _canResendEmail = true;
          timer.cancel();
        }
      });
    });
  }
  
  Future<void> _checkEmailVerification() async {
    try {
      await _authService.reloadUser();
      if (_authService.isEmailVerified) {
        _timer?.cancel();
        _logger.i('Email verified successfully');
        
        // Navigate to home screen
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            _createPageRoute(const HomeScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      _logger.e('Error checking email verification: $e');
    }
  }
  
  Future<void> _resendVerificationEmail() async {
    if (!_canResendEmail || _isLoading) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _authService.sendEmailVerification();
      setState(() {
        _canResendEmail = false;
        _resendCountdown = 60;
      });
      _startResendCountdown();
      
      if (mounted) {
        _showSuccessSnackBar('Email verifikasi telah dikirim ulang');
      }
    } catch (e) {
      _logger.e('Error resending verification email: $e');
      if (mounted) {
        _showErrorSnackBar('Gagal mengirim ulang email: ${e.toString()}');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          _createPageRoute(const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      _logger.e('Error signing out: $e');
    }
  }

  // Theme Colors - Matching design system
  static const Color primaryColor = Color(0xFF2D5A27);
  static const Color primaryLight = Color(0xFF4CAF50);
  static const Color primarySurface = Color(0xFFF1F8E9);
  static const Color surfaceColor = Color(0xFFFAFAFA);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF1B1B1B);
  static const Color textSecondary = Color(0xFF6B6B6B);

  PageRoute _createPageRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);
        return SlideTransition(position: offsetAnimation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: primaryLight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isTablet = size.width > 600;
    
    return Scaffold(
      backgroundColor: surfaceColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? size.width * 0.25 : 24.0,
                vertical: 32.0,
              ),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 48),
                      _buildVerificationCard(),
                      const SizedBox(height: 32),
                      _buildBackToLoginLink(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Email Icon with pulse animation matching design system
        ScaleTransition(
          scale: _pulseAnimation,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: cardColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: primarySurface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.email_outlined,
                  size: 40,
                  color: primaryColor,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        
        // Title
        Text(
          'Verifikasi Email',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Periksa email Anda untuk melanjutkan',
          style: TextStyle(
            fontSize: 16,
            color: textSecondary,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Email info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primarySurface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.email,
                  color: primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Email verifikasi dikirim ke:',
                        style: TextStyle(
                          fontSize: 14,
                          color: textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _authService.currentUser?.email ?? '',
                        style: TextStyle(
                          fontSize: 16,
                          color: textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Instructions
          Text(
            'Silakan buka email Anda dan klik link verifikasi untuk melanjutkan ke aplikasi.',
            style: TextStyle(
              fontSize: 15,
              color: textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 32),
          
          // Check Email Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _checkEmailVerification,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Saya Sudah Verifikasi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Resend Email Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _canResendEmail && !_isLoading 
                  ? _resendVerificationEmail 
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: _canResendEmail && !_isLoading 
                    ? primaryColor 
                    : textSecondary,
                elevation: 0,
                shadowColor: Colors.transparent,
                side: BorderSide(
                  color: _canResendEmail && !_isLoading 
                      ? primaryColor 
                      : textSecondary.withValues(alpha: 0.3),
                  width: 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      ),
                    )
                  : Text(
                      _canResendEmail
                          ? 'Kirim Ulang Email'
                          : 'Kirim Ulang dalam ${_resendCountdown}s',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Info box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue.shade600,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tidak melihat email? Periksa folder spam atau sampah Anda.',
                    style: TextStyle(
                      color: Colors.blue.shade800,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackToLoginLink() {
    return TextButton(
      onPressed: _signOut,
      style: TextButton.styleFrom(
        foregroundColor: textSecondary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.arrow_back,
            size: 18,
            color: textSecondary,
          ),
          const SizedBox(width: 8),
          Text(
            'Kembali ke Login',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
