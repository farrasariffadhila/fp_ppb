import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'login.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final _wishlistItemController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late String userId;

  void logout() async {
    await _auth.signOut();
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, 'login');
  }

  Future<void> _addWishlist() async {  
    if (_wishlistItemController.text.trim().isEmpty) return;

    try {
      await _firestore.collection('users').doc(userId).update({
        'wishlist': FieldValue.arrayUnion([_wishlistItemController.text.trim()]),
      });
      _wishlistItemController.clear();
    } catch (e) {
      if (e.toString().contains('Some requested document was not found')) {
        await _firestore.collection('users').doc(userId).set({
          'wishlist': [_wishlistItemController.text.trim()],
        }, SetOptions(merge: true));
        _wishlistItemController.clear();
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _removeWishlist(String item) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'wishlist': FieldValue.arrayRemove([item]),
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
              title: const Text('Daftar Wishlist'),
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
                          controller: _wishlistItemController,
                          decoration: InputDecoration(
                            labelText: 'Tambah ke Wishlist',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.add, size: 32),
                          onPressed: _addWishlist,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const SizedBox(width: 8),
                      const Text(
                        'Daftar Wishlist Saya',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Stream untuk menampilkan daftar wishlist
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
                        return const Expanded(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(height: 16),
                                Text('Belum ada item wishlist', 
                                     style: TextStyle(fontSize: 16, color: Colors.grey)),
                              ],
                            ),
                          ),
                        );
                      }
                      
                      final data = snapshot.data!.data() as Map<String, dynamic>;
                      final wishlist = List<String>.from(data['wishlist'] ?? []);
                      
                      if (wishlist.isEmpty) {
                        return const Expanded(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(height: 16),
                                Text('Belum ada item wishlist', 
                                     style: TextStyle(fontSize: 16, color: Colors.grey)),
                              ],
                            ),
                          ),
                        );
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
                          itemCount: wishlist.length,
                          itemBuilder: (context, index) {
                            final item = wishlist[index];
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
                                      // Image placeholder with different image for wishlist
                                      Container(
                                        width: double.infinity,
                                        height: 140,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFFFFF),
                                          image: const DecorationImage(
                                            image: NetworkImage('https://flutter.github.io/assets-for-api-docs/assets/widgets/owl.jpg'),
                                            fit: BoxFit.cover,
                                          ),
                                          border: Border.all(
                                            width: 8,
                                            color: Colors.purple.shade100,
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
                                  // Remove from wishlist button
                                  Positioned(
                                    bottom: 8,
                                    right: 8,
                                    child: Material(
                                      color: Colors.white,
                                      shape: const CircleBorder(),
                                      
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