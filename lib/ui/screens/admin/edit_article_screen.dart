import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/models/article_model.dart';
import '../../../app/constants/app_constants.dart';

class EditArticleScreen extends StatefulWidget {
  final bool isEditing;
  final Article? article;

  const EditArticleScreen({
    super.key,
    required this.isEditing,
    this.article,
  });

  @override
  EditArticleScreenState createState() => EditArticleScreenState();
}

class EditArticleScreenState extends State<EditArticleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _imageUrlController = TextEditingController();
  String _selectedCategory = AppConstants.articleCategories.first;
  final _tagsController = TextEditingController();
  final _readTimeController = TextEditingController();
  
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    
    if (widget.isEditing && widget.article != null) {
      // Populate fields with existing data
      final article = widget.article!;
      _titleController.text = article.title;
      _contentController.text = article.content;
      _imageUrlController.text = article.imageUrl;
      _selectedCategory = article.category;
      _tagsController.text = article.tags.join(', ');
      _readTimeController.text = article.readTime.toString();
    } else {
      // Default untuk artikel baru
      _readTimeController.text = '5'; // Default 5 menit
    }
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _imageUrlController.dispose();
    _tagsController.dispose();
    _readTimeController.dispose();
    super.dispose();
  }
  
  List<String> _parseTags(String tagsString) {
    if (tagsString.isEmpty) {
      return [];
    }
    
    return tagsString
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();
  }
  
  Future<void> _saveArticle() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        final firestore = FirebaseFirestore.instance;
        final currentUser = FirebaseAuth.instance.currentUser;
        final now = DateTime.now();
        
        final tags = _parseTags(_tagsController.text);
        
        final articleData = {
          'title': _titleController.text,
          'content': _contentController.text,
          'imageUrl': _imageUrlController.text,
          'category': _selectedCategory,
          'tags': tags,
          'readTime': int.tryParse(_readTimeController.text) ?? 5,
          'updatedAt': now,
        };
        
        if (widget.isEditing && widget.article != null) {
          // Update existing article
          await firestore.collection('articles').doc(widget.article!.id).update(articleData);
        } else {
          // Create new article
          final authorId = currentUser?.uid ?? 'admin';
          final authorName = currentUser?.displayName ?? 'Admin';
          
          articleData['authorId'] = authorId;
          articleData['authorName'] = authorName;
          articleData['publishedAt'] = now;
          articleData['createdAt'] = now;
          
          await firestore.collection('articles').add(articleData);
        }
        
        if (mounted) {
          Navigator.pop(context, true); // Return success
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final title = widget.isEditing ? 'Edit Artikel' : 'Tambah Artikel';
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF4CAF50),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF4CAF50)),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
              ),
            )
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title field
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Judul Artikel',
                        hintText: 'Masukkan judul artikel',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFE8F5E9),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Judul tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Image URL field
                    TextFormField(
                      controller: _imageUrlController,
                      decoration: InputDecoration(
                        labelText: 'URL Gambar',
                        hintText: 'Masukkan URL gambar artikel',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFE8F5E9),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'URL Gambar tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Category dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Kategori',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFE8F5E9),
                      ),
                      items: AppConstants.articleCategories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Tags field
                    TextFormField(
                      controller: _tagsController,
                      decoration: InputDecoration(
                        labelText: 'Tags',
                        hintText: 'Masukkan tags (pisahkan dengan koma)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFE8F5E9),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Read time field
                    TextFormField(
                      controller: _readTimeController,
                      decoration: InputDecoration(
                        labelText: 'Waktu Baca (menit)',
                        hintText: 'Masukkan waktu baca dalam menit',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFE8F5E9),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Waktu baca tidak boleh kosong';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Masukkan angka yang valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Content field with markdown support
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Konten Artikel (Mendukung Markdown)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '# Judul, ## Sub Judul, **Bold**, *Italic*, - List, [Link](url)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _contentController,
                          decoration: InputDecoration(
                            hintText: 'Tulis konten artikel...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFE8F5E9),
                          ),
                          maxLines: 15,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Konten artikel tidak boleh kosong';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveArticle,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          widget.isEditing ? 'Simpan Perubahan' : 'Tambah Artikel',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}