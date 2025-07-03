import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:logger/logger.dart';
import '../../../data/providers/article_provider.dart';
import '../../../data/providers/user_engagement_provider.dart';
import '../../../data/models/article_model.dart';
import '../../../services/analytics_service.dart';
import '../../widgets/engagement/content_rating_widget.dart';
import '../../widgets/engagement/content_engagement_widget.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ArticleDetailScreen extends StatefulWidget {
  final Article? article;  // Accept Article object directly
  final String? articleId; // Keep for backward compatibility

  const ArticleDetailScreen({
    super.key,
    this.article,
    this.articleId,
  }) : assert(article != null || articleId != null, 'Either article or articleId must be provided');

  @override
  ArticleDetailScreenState createState() => ArticleDetailScreenState();
}

class ArticleDetailScreenState extends State<ArticleDetailScreen> with TickerProviderStateMixin {
  final Logger _logger = Logger();
  final AnalyticsService _analytics = AnalyticsService();
  Article? _article;
  bool _isLoading = true;
  String _errorMessage = '';
  
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
    _trackView();
    _loadUserEngagement();
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
  
  void _initializeDateFormatting() async {
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
  
  void _trackView() {
    final articleId = widget.article?.id ?? widget.articleId;
    if (articleId != null) {
      // Track content view
      _analytics.trackContentView(articleId, 'article');
      
      // Track in engagement provider
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final engagementProvider = Provider.of<UserEngagementProvider>(
          context, 
          listen: false
        );
        engagementProvider.trackContentView(articleId, 'article');
      });
    }
  }
  
  void _loadUserEngagement() {
    final articleId = widget.article?.id ?? widget.articleId;
    if (articleId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final engagementProvider = Provider.of<UserEngagementProvider>(
          context, 
          listen: false
        );
        engagementProvider.loadContentEngagement(articleId);
        engagementProvider.loadUserRating(articleId);
      });
    }
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
    if (widget.article != null) {
      // Article already provided
      setState(() {
        _article = widget.article;
        _isLoading = false;
      });
      
      // Start animations
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _fadeController.forward();
          _slideController.forward();
        }
      });
      return;
    }
    
    // Load article by ID
    if (widget.articleId == null) {
      setState(() {
        _errorMessage = 'No article ID provided';
        _isLoading = false;
      });
      return;
    }
    
    final articleProvider = Provider.of<ArticleProvider>(context, listen: false);
    
    try {
      final article = await articleProvider.fetchArticleById(widget.articleId!);
      if (mounted) {
        setState(() {
          _article = article;
          _isLoading = false;
        });
        
        // Start animations after loading
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

  void _toggleBookmark() async {
    if (_article == null) return;
    
    final engagementProvider = Provider.of<UserEngagementProvider>(
      context, 
      listen: false
    );
    
    try {
      final isFavorited = await engagementProvider.toggleArticleFavorite(_article!.id);
      
      // Track analytics
      _analytics.trackContentFavorite(_article!.id, 'article', isFavorited);
      
      // Show feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  isFavorited ? Icons.bookmark : Icons.bookmark_border,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(isFavorited ? 'Artikel disimpan' : 'Artikel dihapus dari simpanan'),
              ],
            ),
            backgroundColor: isFavorited ? primaryLight : textSecondary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('Gagal menyimpan artikel'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  void _shareArticle() async {
    if (_article == null) return;
    
    final engagementProvider = Provider.of<UserEngagementProvider>(
      context, 
      listen: false
    );
    
    try {
      // Track share action
      await engagementProvider.trackContentShare(_article!.id, 'article', 'internal');
      _analytics.trackContentShare(_article!.id, 'article', 'internal');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.share, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('Artikel berhasil dibagikan!'),
              ],
            ),
            backgroundColor: primaryLight,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('Gagal membagikan artikel'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
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
      return _buildErrorState();
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
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const Center(
        child: CircularProgressIndicator(
          color: primaryLight,
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Gagal memuat artikel',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage.isNotEmpty ? _errorMessage : 'Artikel tidak ditemukan',
              style: TextStyle(
                color: textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = '';
                });
                _loadArticle();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 320,
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
      flexibleSpace: FlexibleSpaceBar(
        background: _article!.imageUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: _article!.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: primarySurface,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: primaryLight,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: primarySurface,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.article,
                        size: 64,
                        color: textSecondary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Gambar tidak tersedia',
                        style: TextStyle(
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Container(
                color: primarySurface,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.article,
                      size: 64,
                      color: textSecondary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _article!.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
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
                    height: 1.2,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Metadata
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: primarySurface,
                        borderRadius: BorderRadius.circular(12),
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
                    const Spacer(),
                    Text(
                      _formatDate(_article!.publishedAt),
                      style: TextStyle(
                        fontSize: 14,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Content Body
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
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
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                  height: 1.3,
                  letterSpacing: -0.3,
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
          
          // Engagement Metrics Section
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                Row(
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      color: primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Statistik & Ulasan',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ContentEngagementWidget(
                  contentId: _article!.id,
                  contentType: 'article',
                ),
                const SizedBox(height: 16),
                ContentRatingWidget(
                  contentId: _article!.id,
                  contentType: 'article',
                  onRated: () {
                    // Refresh engagement data after rating
                    final engagementProvider = Provider.of<UserEngagementProvider>(
                      context,
                      listen: false,
                    );
                    engagementProvider.loadContentEngagement(_article!.id);
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 100), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildFloatingActions() {
    return Consumer<UserEngagementProvider>(
      builder: (context, engagementProvider, child) {
        final isBookmarked = _article != null 
            ? engagementProvider.isArticleFavorited(_article!.id)
            : false;
        
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              heroTag: "bookmark",
              onPressed: _toggleBookmark,
              backgroundColor: isBookmarked ? primaryLight : cardColor,
              foregroundColor: isBookmarked ? Colors.white : textPrimary,
              elevation: 4,
              child: Icon(
                isBookmarked ? Icons.bookmark : Icons.bookmark_border,
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
      },
    );
  }
}
