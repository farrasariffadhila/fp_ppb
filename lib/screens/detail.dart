import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'package:fp_ppb/Services/services.dart';

class DetailScreen extends StatefulWidget {
  final int movieId;

  const DetailScreen({super.key, required this.movieId});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  Map<String, dynamic>? movieDetails;
  List<dynamic> cast = [];
  bool isLoading = true;
  bool isFavorite = false;
  String? wishlistCategory;
  int wishlistCount = 0;
  List<String> existingCategories = [];


  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final APIservices _apiServices = APIservices();

  @override
  void initState() {
    super.initState();
    _fetchMovieDetails();
    _checkFavoriteAndWishlistStatus();
    _getWishlistCount();
    _fetchExistingWishlistCategories();
  }

  Future<void> _fetchExistingWishlistCategories() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        final wishlist = List<Map<String, dynamic>>.from(data['wishlist'] ?? []);
        final categories = wishlist.map((item) => item['category'] as String).toSet().toList();
        if (mounted) {
          setState(() {
            existingCategories = categories;
          });
        }
      }
    } catch (e) {
      print('Error fetching existing categories: $e');
    }
  }

  Future<void> _getWishlistCount() async {
    try {
      final count = await _apiServices.getWishlistCount(widget.movieId);
      if (mounted) {
        setState(() {
          wishlistCount = count;
        });
      }
    } catch (e) {
      print('Error getting wishlist count: $e');
    }
  }

  Future<void> _fetchMovieDetails() async {
    try {
      final details = await _apiServices.getMovieDetails(widget.movieId);
      final credits = await _apiServices.getMovieCredits(widget.movieId);

      if (credits != null) {
        setState(() {
          movieDetails = details;
          cast = credits['cast'] ?? [];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
      print('Error fetching movie details: $e');
    }
  }

  Future<void> _checkFavoriteAndWishlistStatus() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        final favorites = List<int>.from(data['favourites'] ?? []);
        final wishlist = List<Map<String, dynamic>>.from(data['wishlist'] ?? []);
        final movieInWishlist = wishlist.firstWhere(
          (item) => item['movieId'] == widget.movieId,
          orElse: () => {},
        );

        setState(() {
          isFavorite = favorites.contains(widget.movieId);
          if (movieInWishlist.isNotEmpty) {
            wishlistCategory = movieInWishlist['category'];
          } else {
            wishlistCategory = null;
          }
        });
      }
    } catch (e) {
      print('Error checking status: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final docRef = _firestore.collection('users').doc(user.uid);
      
      if (isFavorite) {
        await docRef.update({
          'favourites': FieldValue.arrayRemove([widget.movieId])
        });
      } else {
        await docRef.set({
          'favourites': FieldValue.arrayUnion([widget.movieId])
        }, SetOptions(merge: true));
      }
      
      setState(() => isFavorite = !isFavorite);
    } catch (e) {
      print('Favorite error: $e');
    }
  }

  void _showCategoryDialog() {
    final newCategoryController = TextEditingController();
    String? selectedValue = wishlistCategory;
    bool showNewCategoryField = false;
    const String createNewCategoryOption = 'Buat Kategori Baru...';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final dropdownItems = [
              ...existingCategories,
              if (!existingCategories.contains(createNewCategoryOption))
                createNewCategoryOption,
            ];
            if (wishlistCategory != null && !dropdownItems.contains(wishlistCategory)) {
                dropdownItems.insert(0, wishlistCategory!);
            }


            return AlertDialog(
              backgroundColor: Colors.grey[900],
              title: Text(
                wishlistCategory == null ? 'Add to Wishlist' : 'Update Wishlist',
                style: TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedValue,
                    items: dropdownItems.map((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        if (value == createNewCategoryOption) {
                          showNewCategoryField = true;
                          selectedValue = null;
                        } else {
                          showNewCategoryField = false;
                          selectedValue = value;
                        }
                      });
                    },
                    hint: Text("Pilih kategori", style: TextStyle(color: Colors.white70)),
                    dropdownColor: Colors.grey[800],
                    style: TextStyle(color: Colors.white),
                  ),
                  if (showNewCategoryField)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: TextField(
                        controller: newCategoryController,
                        autofocus: true,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Nama kategori baru",
                          hintStyle: TextStyle(color: Colors.white54),
                        ),
                      ),
                    ),
                ],
              ),
              actions: [
                if (wishlistCategory != null)
                  TextButton(
                    onPressed: () async {
                      final user = _auth.currentUser;
                      if (user == null) return;
                      final docRef = _firestore.collection('users').doc(user.uid);
                      final movieToRemove = {
                        'movieId': widget.movieId,
                        'category': wishlistCategory!,
                      };
                      await docRef.update({
                        'wishlist': FieldValue.arrayRemove([movieToRemove])
                      });
                      setState(() => wishlistCategory = null);
                      Navigator.pop(context);
                      await _getWishlistCount();
                      await _fetchExistingWishlistCategories();
                    },
                    child: Text('Remove', style: TextStyle(color: Colors.red)),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: Colors.white70)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    String? finalCategory;
                    if (showNewCategoryField) {
                      finalCategory = newCategoryController.text.trim();
                    } else {
                      finalCategory = selectedValue;
                    }

                    if (finalCategory == null || finalCategory.isEmpty) return;

                    final user = _auth.currentUser;
                    if (user == null) return;
                    final docRef = _firestore.collection('users').doc(user.uid);

                    if (wishlistCategory != null && wishlistCategory != finalCategory) {
                      final oldMovie = {'movieId': widget.movieId, 'category': wishlistCategory!};
                      await docRef.update({'wishlist': FieldValue.arrayRemove([oldMovie])});
                    }

                    final movieToUpsert = {'movieId': widget.movieId, 'category': finalCategory};
                    await docRef.update({'wishlist': FieldValue.arrayUnion([movieToUpsert])});
                    
                    setState(() => wishlistCategory = finalCategory);
                    Navigator.pop(context);
                    await _getWishlistCount();
                    await _fetchExistingWishlistCategories();
                  },
                  child: Text(wishlistCategory == null ? 'Add' : 'Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatRuntime(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins}m';
  }

  String _formatRating(double rating) {
    return rating.toStringAsFixed(1);
  }

  Widget _buildStarRating(double rating) {
    final stars = (rating / 2).round();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < stars ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 20,
        );
      }),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animation/loading.json',
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            const Text(
              'Loading Movie Details...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: 200,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[400]!),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingScreen();
    }

    if (movieDetails == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/lottie/error_animation.json',
                width: 150,
                height: 150,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 20),
              const Text(
                'Failed to load movie details',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    isLoading = true;
                  });
                  _fetchMovieDetails();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final posterPath = movieDetails!['poster_path'];
    final backdropPath = movieDetails!['backdrop_path'];
    final title = movieDetails!['title'] ?? 'Unknown Title';
    final releaseYear = movieDetails!['release_date']?.split('-')[0] ?? '2024';
    final genres = movieDetails!['genres'] as List<dynamic>? ?? [];
    final runtime = movieDetails!['runtime'] ?? 0;
    final rating = (movieDetails!['vote_average'] ?? 0.0).toDouble();
    final overview = movieDetails!['overview'] ?? 'No description available.';
    final bool isInWishlist = wishlistCategory != null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            backgroundColor: Colors.black,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : Colors.white,
                ),
                onPressed: _toggleFavorite,
              ),
              IconButton(
                icon: Icon(
                  isInWishlist ? Icons.bookmark : Icons.bookmark_border,
                  color: isInWishlist ? Colors.blue : Colors.white,
                ),
                onPressed: _showCategoryDialog,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (backdropPath != null)
                    Image.network(
                      'https://image.tmdb.org/t/p/w780$backdropPath',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[900],
                          child: const Center(
                            child: Icon(Icons.broken_image, 
                                color: Colors.white24, size: 50),
                          ),
                        );
                      },
                    )
                  else
                    Container(
                      color: Colors.grey[900],
                      child: const Center(
                        child: Icon(Icons.movie, color: Colors.white, size: 50),
                      ),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                          Colors.black,
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          width: 120,
                          height: 180,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: posterPath != null
                                ? Image.network(
                                    'https://image.tmdb.org/t/p/w342$posterPath',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[800],
                                        child: const Center(
                                          child: Icon(Icons.broken_image, 
                                              color: Colors.white24),
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    color: Colors.grey[800],
                                    child: const Center(
                                      child: Icon(Icons.movie, color: Colors.white),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$releaseYear • ${genres.isNotEmpty ? genres.first['name'] : 'Drama'} • ${runtime > 0 ? _formatRuntime(runtime) : '1h 43m'}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    _formatRating(rating),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildStarRating(rating),
                                  const SizedBox(width: 16),
                                  Icon(Icons.bookmark, color: Colors.blue, size: 20),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$wishlistCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    overview,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Cast',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 140,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: cast.length,
                      itemBuilder: (context, index) {
                        final actor = cast[index];
                        final profilePath = actor['profile_path'];
                        
                        return Container(
                          width: 100,
                          margin: const EdgeInsets.only(right: 16),
                          child: Column(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: ClipOval(
                                  child: profilePath != null
                                      ? Image.network(
                                          'https://image.tmdb.org/t/p/w185$profilePath',
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.grey[800],
                                              child: const Center(
                                                child: Icon(Icons.person, color: Colors.white),
                                              ),
                                            );
                                          },
                                        )
                                      : Container(
                                          color: Colors.grey[800],
                                          child: const Center(
                                            child: Icon(Icons.person, color: Colors.white),
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                actor['name'] ?? 'Unknown',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, 'rent', arguments: {
                          'movieId': widget.movieId,
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Rent',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
