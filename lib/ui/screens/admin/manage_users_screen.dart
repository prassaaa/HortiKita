import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../data/models/user_model.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  ManageUsersScreenState createState() => ManageUsersScreenState();
}

class ManageUsersScreenState extends State<ManageUsersScreen> {
  bool _isLoading = true;
  List<UserModel> _users = [];
  String _errorMessage = '';
  
  @override
  void initState() {
    super.initState();
    _loadUsers();
  }
  
  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();
      
      final users = snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
      
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }
  
  Future<void> _updateUserRole(UserModel user, String newRole) async {
    // Cek jika role baru sama dengan role saat ini
    if (user.role == newRole) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pengguna ${user.name} sudah memiliki role ${newRole == 'admin' ? 'Admin' : 'Pengguna'}'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'role': newRole,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Refresh users list
      _loadUsers();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Role pengguna ${user.name} berhasil diperbarui menjadi ${newRole == 'admin' ? 'Admin' : 'Pengguna'}'),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
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
    }
  }
  
  // Fungsi untuk menghapus user
  Future<void> _deleteUser(UserModel user) async {
    try {
      // Hapus dokumen user
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .delete();
      
      // Refresh daftar users
      _loadUsers();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pengguna ${user.name} berhasil dihapus'),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
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
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kelola Pengguna',
          style: TextStyle(
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
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error: $_errorMessage',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadUsers,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                        ),
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : _users.isEmpty
                  ? const Center(
                      child: Text(
                        'Tidak ada data pengguna tersedia',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF558B2F),
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadUsers,
                      color: const Color(0xFF4CAF50),
                      child: ListView.builder(
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          return _buildUserListItem(context, user);
                        },
                      ),
                    ),
            );
          }
  
  Widget _buildUserListItem(BuildContext context, UserModel user) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final isAdmin = user.role == 'admin';
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: isAdmin 
              ? const Color(0xFFF44336) // Merah untuk admin
              : const Color(0xFF4CAF50), // Hijau untuk pengguna biasa
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          user.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isAdmin ? Colors.red[100] : Colors.blue[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isAdmin ? 'Admin' : 'Pengguna',
                    style: TextStyle(
                      fontSize: 12,
                      color: isAdmin ? Colors.red[900] : Colors.blue[900],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Terdaftar: ${dateFormat.format(user.createdAt)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Menu popup untuk aksi
            PopupMenuButton<String>(
              tooltip: 'Opsi Pengguna',
              onSelected: (value) {
                if (value == 'make_admin') {
                  _updateUserRole(user, 'admin');
                } else if (value == 'make_user') {
                  _updateUserRole(user, 'user');
                } else if (value == 'delete_user') {
                  _showDeleteConfirmation(context, user);
                }
              },
              itemBuilder: (context) {
                // Buat daftar menu berdasarkan status pengguna
                final menuItems = <PopupMenuItem<String>>[];
                
                // Tampilkan 'Jadikan Admin' hanya jika bukan admin
                if (!isAdmin) {
                  menuItems.add(const PopupMenuItem<String>(
                    value: 'make_admin',
                    child: Row(
                      children: [
                        Icon(Icons.admin_panel_settings, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Jadikan Admin'),
                      ],
                    ),
                  ));
                }
                
                // Tampilkan 'Jadikan Pengguna' hanya jika sudah admin
                if (isAdmin) {
                  menuItems.add(const PopupMenuItem<String>(
                    value: 'make_user',
                    child: Row(
                      children: [
                        Icon(Icons.person, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Jadikan Pengguna'),
                      ],
                    ),
                  ));
                }
                
                // Tambahkan opsi hapus untuk semua pengguna
                menuItems.add(const PopupMenuItem<String>(
                  value: 'delete_user',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Hapus Pengguna'),
                    ],
                  ),
                ));
                
                return menuItems;
              },
              icon: const Icon(Icons.more_vert, color: Color(0xFF4CAF50)),
            ),
          ],
        ),
      ),
    );
  }
  
  // Dialog konfirmasi penghapusan pengguna
  void _showDeleteConfirmation(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus Pengguna'),
        content: Text(
          'Apakah Anda yakin ingin menghapus pengguna "${user.name}" (${user.email})? '
          'Tindakan ini tidak dapat dibatalkan.'
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteUser(user);
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