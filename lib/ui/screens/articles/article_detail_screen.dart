import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:logger/logger.dart';
import '../../../data/providers/article_provider.dart';
import '../../../data/models/article_model.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ArticleDetailScreen extends StatefulWidget {
  final String articleId;

  const ArticleDetailScreen({
    super.key,
    required this.articleId,
  });

  @override
  ArticleDetailScreenState createState() => ArticleDetailScreenState();
}

class ArticleDetailScreenState extends State<ArticleDetailScreen> with TickerProviderStateMixin {
  final Logger _logger = Logger();
  Article? _article;
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isBookmarked = false;
  
  // Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeDateFormatting();
    _loadArticle();
  }
  
  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
  }
  
  Future<void> _initializeDateFormatting() async {
    try {
      await initializeDateFormatting('id_ID', null);
    } catch (e) {
      // Fallback jika locale Indonesia tidak tersedia
      _logger.w('Date formatting initialization failed: $e');
    }
  }
  
  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  // Theme Colors - Modern Design System
  static const Color primaryColor = Color(0xFF2D5A27);
  static const Color primaryLight = Color(0xFF4CAF50);
  static const Color primarySurface = Color(0xFFF1F8E9);
  static const Color surfaceColor = Color(0xFFFAFAFA);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF1B1B1B);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color dividerColor = Color(0xFFE0E0E0);

  Future<void> _loadArticle() async {
    final articleProvider = Provider.of<ArticleProvider>(context, listen: false);
    
    try {
      final article = await articleProvider.fetchArticleById(widget.articleId);
      if (mounted) {
        setState(() {
          _article = article;
          _isLoading = false;
        });
        
        // Start animations after loading - use addPostFrameCallback to avoid setState during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _fadeController.forward();
            _slideController.forward();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _toggleBookmark() {
    setState(() {
      _isBookmarked = !_isBookmarked;
    });
    
    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(_isBookmarked ? 'Artikel disimpan' : 'Artikel dihapus dari simpanan'),
          ],
        ),
        backgroundColor: _isBookmarked ? primaryLight : textSecondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareArticle() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.share, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Text('Fitur berbagi akan segera tersedia'),
          ],
        ),
        backgroundColor: primaryLight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _formatDate(DateTime date) {
    try {
      // Coba format dengan locale Indonesia
      return DateFormat('dd MMMM yyyy', 'id_ID').format(date);
    } catch (e) {
      // Fallback ke format default jika locale tidak tersedia
      return DateFormat('dd MMMM yyyy').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }
    
    if (_errorMessage.isNotEmpty) {
      return _buildErrorState();
    }
    
    if (_article == null) {
      return _buildNotFoundState();
    }
    
    return Scaffold(
      backgroundColor: surfaceColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildArticleContent(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActions(),
    );
  }

  Widget _buildLoadingState() {
    return Scaffold(
      backgroundColor: surfaceColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
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
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    color: primaryLight,
                    strokeWidth: 3,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Memuat artikel...',
              style: TextStyle(
                fontSize: 16,
                color: textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Scaffold(
      backgroundColor: surfaceColor,
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    'Detail Artikel',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            
            // Error Content
            Expanded(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  margin: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.shade400,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Oops! Terjadi Kesalahan',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage,
                        style: TextStyle(
                          fontSize: 14,
                          color: textSecondary,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isLoading = true;
                              _errorMessage = '';
                            });
                            _loadArticle();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                          ),
                          child: Text(
                            'Coba Lagi',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFoundState() {
    return Scaffold(
      backgroundColor: surfaceColor,
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    'Detail Artikel',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            
            // Not Found Content
            Expanded(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  margin: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.article_outlined,
                        size: 64,
                        color: textSecondary.withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Artikel Tidak Ditemukan',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Artikel yang Anda cari mungkin telah dihapus atau tidak tersedia.',
                        style: TextStyle(
                          fontSize: 14,
                          color: textSecondary,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryColor,
                            side: BorderSide(color: primaryColor, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            'Kembali ke Artikel',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: cardColor,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: cardColor.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: cardColor.withValues(alpha: 0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(Icons.share, color: textPrimary),
            onPressed: _shareArticle,
          ),
        ),
        Container(
          margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: cardColor.withValues(alpha: 0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: _isBookmarked ? primaryLight : textPrimary,
            ),
            onPressed: _toggleBookmark,
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: _article!.imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: surfaceColor,
                child: Center(
                  child: CircularProgressIndicator(color: primaryLight),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: surfaceColor,
                child: Center(
                  child: Icon(
                    Icons.image_not_supported,
                    size: 48,
                    color: textSecondary,
                  ),
                ),
              ),
            ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticleContent() {
    return Container(
      color: surfaceColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Article Header
          Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  _article!.title,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                    height: 1.3,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Author info
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: primarySurface,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          _article!.authorName.isNotEmpty
                              ? _article!.authorName[0].toUpperCase()
                              : 'A',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _article!.authorName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatDate(_article!.publishedAt),
                            style: TextStyle(
                              fontSize: 14,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: primarySurface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _article!.category,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Reading time
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_article!.readTime} menit baca',
                      style: TextStyle(
                        fontSize: 14,
                        color: textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                
                // Tags
                if (_article!.tags.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _article!.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: dividerColor),
                        ),
                        child: Text(
                          '#$tag',
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          
          // Article Content
          Container(
            margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: MarkdownBody(
              data: _article!.content,
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(
                  fontSize: 16,
                  height: 1.7,
                  color: textPrimary,
                  fontWeight: FontWeight.w400,
                ),
                strong: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  height: 1.7,
                  color: textPrimary,
                ),
                em: TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 16,
                  height: 1.7,
                  color: textPrimary,
                ),
                h1: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                  height: 1.3,
                  letterSpacing: -0.3,
                ),
                h2: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                  height: 1.3,
                  letterSpacing: -0.3,
                ),
                h3: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                  height: 1.3,
                  letterSpacing: -0.2,
                ),
                listBullet: TextStyle(
                  fontSize: 16,
                  height: 1.7,
                  color: textPrimary,
                ),
                blockquote: TextStyle(
                  fontSize: 16,
                  height: 1.7,
                  color: textSecondary,
                  fontStyle: FontStyle.italic,
                ),
                code: TextStyle(
                  fontSize: 14,
                  color: primaryColor,
                  backgroundColor: primarySurface,
                ),
              ),
              selectable: true,
            ),
          ),
          
          const SizedBox(height: 100), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildFloatingActions() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton(
          heroTag: "bookmark",
          onPressed: _toggleBookmark,
          backgroundColor: _isBookmarked ? primaryLight : cardColor,
          foregroundColor: _isBookmarked ? Colors.white : textPrimary,
          elevation: 4,
          child: Icon(
            _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
          ),
        ),
        const SizedBox(height: 16),
        FloatingActionButton(
          heroTag: "share",
          onPressed: _shareArticle,
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 4,
          child: const Icon(Icons.share),
        ),
      ],
    );
  }
}