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

  Future<void> _removeFromWishlist(int movieId, String category) async {
    try {
      final movieToRemove = {'movieId': movieId, 'category': category};
      await _firestore.collection('users').doc(userId).update({
        'wishlist': FieldValue.arrayRemove([movieToRemove])
      });
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removed from wishlist')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _navigateToDetailScreen(BuildContext context, Movie movie) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailScreen(movieId: movie.id),
      ),
    ).then((_) {
      setState(() {});
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

                    final Map<String, List<Movie>> groupedMovies = {};
                    for (var item in wishlistItems) {
                      final category = item['category'] as String;
                      final movie = movies.firstWhere(
                        (m) => m.id == item['movieId'],
                        orElse: () => Movie(id: 0, title: 'Not Found', posterPath: null, backDropPath: '', overview: ''),
                      );
                      if (movie.id != 0) {
                        if (groupedMovies[category] == null) {
                          groupedMovies[category] = [];
                        }
                        groupedMovies[category]!.add(movie);
                      }
                    }

                    final categories = groupedMovies.keys.toList();

                    return ListView.builder(
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final moviesInCategory = groupedMovies[category]!;
                        return Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            initiallyExpanded: true,
                            title: Text(
                              category,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold),
                            ),
                            children: [
                              SizedBox(
                                height: 250,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  itemCount: moviesInCategory.length,
                                  itemBuilder: (context, movieIndex) {
                                    final movie = moviesInCategory[movieIndex];
                                    return GestureDetector(
                                      onTap: () => _navigateToDetailScreen(context, movie),
                                      child: Container(
                                        width: 140,
                                        margin: const EdgeInsets.only(right: 12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Stack(
                                                children: [
                                                  ClipRRect(
                                                    borderRadius: BorderRadius.circular(12),
                                                    child: movie.posterPath != null
                                                        ? Image.network(
                                                            'https://image.tmdb.org/t/p/w342${movie.posterPath}',
                                                            fit: BoxFit.cover,
                                                            width: 140,
                                                            errorBuilder: (context, error, stackTrace) {
                                                              return Container(color: Colors.grey[800], child: const Center(child: Icon(Icons.broken_image, color: Colors.white24)));
                                                            },
                                                          )
                                                        : Container(color: Colors.grey[800], child: const Center(child: Icon(Icons.movie, color: Colors.white24))),
                                                  ),
                                                  Positioned(
                                                    top: 4,
                                                    right: 4,
                                                    child: CircleAvatar(
                                                      backgroundColor: Colors.black.withOpacity(0.6),
                                                      radius: 16,
                                                      child: IconButton(
                                                        padding: EdgeInsets.zero,
                                                        icon: const Icon(Icons.close, color: Colors.white, size: 16),
                                                        onPressed: () => _removeFromWishlist(movie.id, category),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(top: 8.0),
                                              child: Text(
                                                movie.title,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              )
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
