import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'login.dart';

class FavouriteScreen extends StatefulWidget {
  const FavouriteScreen({super.key});

  @override
  State<FavouriteScreen> createState() => _FavouriteScreenState();
}

class _FavouriteScreenState extends State<FavouriteScreen> {
  final _favouriteItemController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late String userId;

  void logout() async {
    await _auth.signOut();
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, 'login');
  }

  Future<void> _addFavourite() async {  
    if (_favouriteItemController.text.trim().isEmpty) return;

    try {
      await _firestore.collection('users').doc(userId).update({
        'favourites': FieldValue.arrayUnion([_favouriteItemController.text.trim()]),
      });
      _favouriteItemController.clear();
    } catch (e) {
      if (e.toString().contains('Some requested document was not found')) {
        await _firestore.collection('users').doc(userId).set({
          'favourites': [_favouriteItemController.text.trim()],
        });
        _favouriteItemController.clear();
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _removeFavourite(String item) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'favourites': FieldValue.arrayRemove([item]),
      });
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData) {
          final user = snapshot.data!;
          userId = user.uid;

          return Scaffold(
            appBar: AppBar(
              title: const Text('Daftar Favorit'),
              centerTitle: true,
              actions: [
                IconButton(icon: const Icon(Icons.logout), onPressed: logout),
              ],
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _favouriteItemController,
                          decoration: const InputDecoration(
                            labelText: 'Tambah ke Favorit',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.add, size: 32),
                        onPressed: _addFavourite,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Daftar Favorit Saya',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  // Stream untuk menampilkan daftar favorit
                  StreamBuilder<DocumentSnapshot>(
                    stream: _firestore.collection('users').doc(userId).snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return const Center(child: Text('Belum ada item favorit'));
                      }
                      
                      final data = snapshot.data!.data() as Map<String, dynamic>;
                      final favourites = List<String>.from(data['favourites'] ?? []);
                      
                      if (favourites.isEmpty) {
                        return const Center(child: Text('Belum ada item favorit'));
                      }
                      
                      return Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2, // 2 items per row
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.8, // Adjust this for item proportions
                          ),
                          itemCount: favourites.length,
                          itemBuilder: (context, index) {
                            final item = favourites[index];
                            return Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Stack(
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      // Image placeholder (replace with actual image)
                                      Container(
                                        width: double.infinity,
                                        height: 140,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFFFFF),
                                          image: const DecorationImage(
                                            image: NetworkImage('https://flutter.github.io/assets-for-api-docs/assets/widgets/owl-2.jpg'),
                                            fit: BoxFit.cover,
                                          ),
                                          border: Border.all(
                                            width: 8,
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          item,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Unfavorite button
                                  Positioned(
                                    bottom: 8,
                                    right: 8,
                                    child: Material(
                                      color: Colors.white,
                                      shape: const CircleBorder(),
                                      child: IconButton(
                                        icon: const Icon(Icons.favorite, color: Colors.red),
                                        onPressed: () => _removeFavourite(item),
                                        iconSize: 20,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}