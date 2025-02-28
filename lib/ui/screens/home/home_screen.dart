import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../plants/plants_screen.dart';
import '../chatbot/chatbot_screen.dart';
import '../articles/articles_screen.dart'; // Tambahkan import untuk ArticlesScreen

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hortikultura App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting section
            Text(
              'Halo, ${authProvider.userModel?.name ?? 'Pengguna'}!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Selamat datang di aplikasi Hortikultura',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            
            // Features section
            const Text(
              'Fitur Utama',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Feature cards
            Row(
              children: [
                Expanded(
                  child: _buildFeatureCard(
                    context,
                    'Katalog Tanaman',
                    'Informasi berbagai tanaman hortikultura',
                    Icons.eco,
                    Colors.green,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PlantsScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildFeatureCard(
                    context,
                    'Chatbot',
                    'Tanya jawab seputar hortikultura',
                    Icons.chat,
                    Colors.blue,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ChatbotScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16), // Tambahkan jarak antara baris kartu
            Row(
              children: [
                Expanded(
                  child: _buildFeatureCard(
                    context,
                    'Artikel',
                    'Tips dan informasi hortikultura',
                    Icons.article,
                    Colors.orange,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ArticlesScreen()),
                      );
                    },
                  ),
                ),
                // Anda bisa menambahkan fitur lain di sini jika perlu
                const Expanded(child: SizedBox()),
              ],
            ),
            
            // Section for articles (will be added later)
            const SizedBox(height: 32),
            const Text(
              'Artikel Terbaru',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: Text(
                  'Fitur artikel akan segera hadir',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 40,
                color: color,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}