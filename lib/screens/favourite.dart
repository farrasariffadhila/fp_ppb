import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fp_ppb/Services/services.dart';
import '../Model/model.dart';
import 'detail.dart';
import 'login.dart';

class FavouriteScreen extends StatefulWidget {
  const FavouriteScreen({super.key});

  @override
  State<FavouriteScreen> createState() => _FavouriteScreenState();
}

class _FavouriteScreenState extends State<FavouriteScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final APIservices _apiServices = APIservices();

  late String userId;

  void logout() async {
    await _auth.signOut();
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, 'login');
  }

  Future<void> _removeFavourite(int movieId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'favourites': FieldValue.arrayRemove([movieId]),
      });
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
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'My Favourites',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
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
                        return const Center(child: Text('No favourite movies'));
                      }

                      final data = snapshot.data!.data() as Map<String, dynamic>;
                      final favourites = List<int>.from(data['favourites'] ?? []);

                      if (favourites.isEmpty) {
                        return const Center(child: Text('No favourite movies'));
                      }

                      return FutureBuilder<List<Movie>>(
                        future: _apiServices.getMoviesByIds(favourites),
                        builder: (context, movieSnapshot) {
                          if (movieSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (movieSnapshot.hasError) {
                            return Center(child: Text('Error loading movies: ${movieSnapshot.error}'));
                          }

                          final movies = movieSnapshot.data ?? [];

                          if (movies.isEmpty) {
                            return const Center(child: Text('No favourite movies'));
                          }

                          return Expanded(
                            child: GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 0.6,
                              ),
                              itemCount: movies.length,
                              itemBuilder: (context, index) {
                                final movie = movies[index];
                                return GestureDetector(
                                  onTap: () => _navigateToDetailScreen(context, movie),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: movie.posterPath != null
                                            ? Image.network(
                                                'https://image.tmdb.org/t/p/w342${movie.posterPath}',
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                                height: double.infinity,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Container(
                                                      color: Colors.grey[800],
                                                      child: const Center(
                                                          child: Icon(Icons.broken_image, color: Colors.white24)));
                                                },
                                              )
                                            : Container(
                                                color: Colors.grey[800],
                                                child: const Center(
                                                    child: Icon(Icons.movie, color: Colors.white24))),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: CircleAvatar(
                                          backgroundColor: Colors.black.withOpacity(0.6),
                                          radius: 16,
                                          child: IconButton(
                                            padding: EdgeInsets.zero,
                                            icon: const Icon(Icons.favorite, color: Colors.red, size: 16),
                                            onPressed: () => _removeFavourite(movie.id),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 8,
                                        left: 8,
                                        right: 8,
                                        child: Text(
                                          movie.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              color: Colors.white, fontWeight: FontWeight.w500),
                                        ),
                                      )
                                    ],
                                  ),
                                );
                              },
                            ),
                          );
                        },
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
