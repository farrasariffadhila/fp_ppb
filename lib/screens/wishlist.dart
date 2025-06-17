import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fp_ppb/Services/services.dart';
import 'package:fp_ppb/Model/model.dart';
import 'login.dart';
import 'detail.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final APIservices _apiServices = APIservices();
  late String userId;

  void logout() async {
    await _auth.signOut();
    if (!context.mounted) return;
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => const LoginScreen()));
  }

  Future<void> _removeFromWishlist(int movieId) async {
    try {
      final docRef = _firestore.collection('users').doc(userId);
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        final wishlist = List<Map<String, dynamic>>.from(data['wishlist'] ?? []);
        
        final itemToRemove = wishlist.firstWhere(
          (item) => item['movieId'] == movieId,
          orElse: () => {},
        );

        if (itemToRemove.isNotEmpty) {
          await docRef.update({
            'wishlist': FieldValue.arrayRemove([itemToRemove])
          });
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Removed from wishlist')),
          );
        }
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _showEditNoteDialog(int movieId, String currentNote) async {
    final noteController = TextEditingController(text: currentNote);
    
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Update Note', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: noteController,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: "Update your note here...",
              hintStyle: TextStyle(color: Colors.white54),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
            ),
            maxLines: 3,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Update'),
              onPressed: () async {
                final newNote = noteController.text.trim();
                final docRef = _firestore.collection('users').doc(userId);

                try {
                  final doc = await docRef.get();
                  if (doc.exists) {
                    final data = doc.data()!;
                    final wishlist = List<Map<String, dynamic>>.from(data['wishlist'] ?? []);
                    
                    final movieIndex = wishlist.indexWhere((item) => item['movieId'] == movieId);

                    if (movieIndex != -1) {
                      wishlist[movieIndex]['note'] = newNote;
                      await docRef.set({'wishlist': wishlist}, SetOptions(merge: true));
                    }
                  }
                } catch (e) {
                   if (!context.mounted) return;
                   ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating note: ${e.toString()}')),
                  );
                }

                if (!context.mounted) return;
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _navigateToDetailScreen(BuildContext context, Movie movie) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailScreen(movieId: movie.id),
      ),
    ).then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _auth.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (authSnapshot.hasData) {
          final user = authSnapshot.data!;
          userId = user.uid;

          return Scaffold(
            backgroundColor: Colors.grey[900],
            appBar: AppBar(
              title: const Text('My Wishlist', style: TextStyle(color: Colors.white)),
              centerTitle: true,
              backgroundColor: Colors.grey[900],
              elevation: 0,
              actions: [
                IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: logout),
              ],
            ),
            body: StreamBuilder<DocumentSnapshot>(
              stream: _firestore.collection('users').doc(userId).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(
                    child: Text('No wishlist items', style: TextStyle(color: Colors.white)),
                  );
                }
                
                final data = snapshot.data!.data() as Map<String, dynamic>;
                final wishlistItems = List<Map<String, dynamic>>.from(data['wishlist'] ?? []);
                
                if (wishlistItems.isEmpty) {
                  return const Center(
                    child: Text('Your wishlist is empty', style: TextStyle(color: Colors.white)),
                  );
                }

                final wishlistIds = wishlistItems.map((item) => item['movieId'] as int).toSet().toList();
                
                return FutureBuilder<List<Movie>>(
                  future: _apiServices.getMoviesByIds(wishlistIds),
                  builder: (context, movieSnapshot) {
                    if (movieSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    if (movieSnapshot.hasError) {
                      return Center(child: Text('Error loading movies: ${movieSnapshot.error}'));
                    }
                    
                    final movies = movieSnapshot.data ?? [];
                    if (movies.isEmpty && wishlistIds.isNotEmpty) {
                        return const Center(child: Text("Could not load movie details.", style: TextStyle(color: Colors.white)));
                    }

                    final fullWishlist = wishlistItems.map((item) {
                      final movie = movies.firstWhere(
                        (m) => m.id == item['movieId'],
                        orElse: () => Movie(id: 0, title: 'Not Found', posterPath: null, backDropPath: '', overview: ''),
                      );
                      return {
                        'movie': movie,
                        'note': item['note'] ?? ''
                      };
                    }).where((element) => (element['movie'] as Movie).id != 0).toList();

                    return GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.5,
                      ),
                      itemCount: fullWishlist.length,
                      itemBuilder: (context, index) {
                        final item = fullWishlist[index];
                        final movie = item['movie'] as Movie;
                        final note = item['note'] as String;

                        return GestureDetector(
                          onTap: () => _navigateToDetailScreen(context, movie),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        image: movie.posterPath != null ? DecorationImage(
                                          image: NetworkImage('https://image.tmdb.org/t/p/w342${movie.posterPath}'),
                                          fit: BoxFit.cover,
                                        ) : null,
                                        color: Colors.grey[800],
                                      ),
                                      child: movie.posterPath == null ? const Center(child: Icon(Icons.movie, color: Colors.white24, size: 40)) : null,
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: CircleAvatar(
                                        backgroundColor: Colors.black.withOpacity(0.7),
                                        radius: 16,
                                        child: IconButton(
                                          padding: EdgeInsets.zero,
                                          icon: const Icon(Icons.close, color: Colors.white, size: 16),
                                          onPressed: () => _removeFromWishlist(movie.id),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0, left: 4, right: 4),
                                child: Text(
                                  movie.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (note.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0, left: 4, right: 4),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.notes, color: Colors.white54, size: 14),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          note,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontStyle: FontStyle.italic,
                                            fontSize: 12,
                                          ),
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      // --- PENAMBAHAN ICON EDIT ---
                                      SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: IconButton(
                                          padding: EdgeInsets.zero,
                                          icon: const Icon(Icons.edit, color: Colors.white54, size: 14),
                                          onPressed: () => _showEditNoteDialog(movie.id, note),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          );
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
