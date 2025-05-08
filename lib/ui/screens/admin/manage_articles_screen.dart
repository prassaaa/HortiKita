import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../data/providers/article_provider.dart';
import '../../../data/models/article_model.dart';
import 'edit_article_screen.dart';

class ManageArticlesScreen extends StatefulWidget {
  const ManageArticlesScreen({super.key});

  @override
  ManageArticlesScreenState createState() => ManageArticlesScreenState();
}

class ManageArticlesScreenState extends State<ManageArticlesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ArticleProvider>(context, listen: false).fetchAllArticles();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kelola Artikel',
          style: TextStyle(
            color: Color(0xFF4CAF50),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF4CAF50)),
      ),
      body: Consumer<ArticleProvider>(
        builder: (context, articleProvider, child) {
          if (articleProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
              ),
            );
          }

          if (articleProvider.error.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${articleProvider.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      articleProvider.fetchAllArticles();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                    ),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          if (articleProvider.articles.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Tidak ada artikel tersedia',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF558B2F),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Navigasi ke halaman tambah artikel
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditArticleScreen(isEditing: false),
                        ),
                      ).then((result) {
                        if (result == true) {
                          // Refresh data jika artikel berhasil ditambahkan
                          articleProvider.fetchAllArticles();
                        }
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                    ),
                    child: const Text('Tambah Artikel Baru'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: articleProvider.articles.length,
            itemBuilder: (context, index) {
              final article = articleProvider.articles[index];
              return _buildArticleListItem(context, article);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const EditArticleScreen(isEditing: false),
            ),
          );
          
          // Refresh data jika berhasil menambahkan artikel
          if (result == true) {
            if (!mounted) return;
            Provider.of<ArticleProvider>(context, listen: false).fetchAllArticles();
          }
        },
        backgroundColor: const Color(0xFF4CAF50),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildArticleListItem(BuildContext context, Article article) {
    final dateFormat = DateFormat('dd MMM yyyy');
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: article.imageUrl.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  article.imageUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 60,
                      height: 60,
                      color: const Color(0xFFE8F5E9),
                      child: const Icon(
                        Icons.image,
                        color: Color(0xFF4CAF50),
                      ),
                    );
                  },
                ),
              )
            : Container(
                width: 60,
                height: 60,
                color: const Color(0xFFE8F5E9),
                child: const Icon(
                  Icons.article,
                  color: Color(0xFF4CAF50),
                ),
              ),
        title: Text(
          article.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kategori: ${article.category}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Tanggal: ${dateFormat.format(article.publishedAt)}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(
                Icons.edit,
                color: Color(0xFF4CAF50),
              ),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditArticleScreen(
                      isEditing: true,
                      article: article,
                    ),
                  ),
                );
                
                // Refresh data jika ada perubahan
                if (result == true) {
                  if (!mounted) return;
                  Provider.of<ArticleProvider>(context, listen: false).fetchAllArticles();
                }
              },
            ),
            IconButton(
              icon: const Icon(
                Icons.delete,
                color: Colors.red,
              ),
              onPressed: () {
                _showDeleteConfirmation(context, article);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Article article) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus artikel "${article.title}"?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              try {
                // Tutup dialog
                Navigator.pop(context);
                
                // Tampilkan loading
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Menghapus artikel...'),
                    duration: Duration(seconds: 1),
                  ),
                );
                
                // Hapus artikel
                await Provider.of<ArticleProvider>(context, listen: false)
                  .deleteArticle(article.id);
                  
                // Tampilkan notifikasi sukses
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Artikel berhasil dihapus'),
                    backgroundColor: Color(0xFF4CAF50),
                  ),
                );
              } catch (e) {
                // Tampilkan error
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text(
              'Hapus',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}