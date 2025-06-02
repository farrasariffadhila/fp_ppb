import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fp_ppb/Services/services.dart';
import '../Model/model.dart';
import 'detail.dart';
import 'login.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Movie>> nowShowing;
  late Future<List<Movie>> upComing;
  late Future<List<Movie>> popularMovies;

  @override
  void initState() {
    nowShowing = APIservices().getNowShowing();
    upComing = APIservices().getUpComing();
    popularMovies = APIservices().getPopular();
    super.initState();
  }

  void logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, 'login');
  }

  void favourite(BuildContext context) {
    Navigator.pushNamed(context, 'favourite');
  }

  void wishlist(BuildContext context) {
    Navigator.pushNamed(context, 'wishlist');
  }

  void _navigateToDetailScreen(BuildContext context, Movie movie) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailScreen(movieId: movie.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const LoginScreen();
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text("Movie App"),
            centerTitle: true,
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search_rounded),
                onPressed: () {}, // implement search if needed
              ),
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {}, // implement notification if needed
              ),
              const SizedBox(width: 10),
            ],
          ),
          drawer: Drawer(
            backgroundColor: Colors.black,
            child: ListView(
              children: [
                UserAccountsDrawerHeader(
                  decoration: const BoxDecoration(color: Colors.black),
                  accountName: const Text('Welcome', style: TextStyle(color: Colors.white)),
                  accountEmail: Text(snapshot.data?.email ?? "", style: const TextStyle(color: Colors.white70)),
                  currentAccountPicture: const CircleAvatar(
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.favorite, color: Colors.white),
                  title: const Text('Favourite', style: TextStyle(color: Colors.white)),
                  onTap: () => favourite(context),
                ),
                ListTile(
                  leading: const Icon(Icons.bookmark, color: Colors.white),
                  title: const Text('Wishlist', style: TextStyle(color: Colors.white)),
                  onTap: () => wishlist(context),
                ),
                ListTile(
                  leading: const Icon(Icons.house, color: Colors.white),
                  title: const Text('Rent', style: TextStyle(color: Colors.white)),
                  onTap: () => Navigator.pushNamed(context, 'rent'),
                ),
                ListTile(
                  leading: const Icon(Icons.check, color: Colors.white),
                  title: const Text('Test', style: TextStyle(color: Colors.white)),
                  onTap: () => Navigator.pushNamed(context, 'test'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.white),
                  title: const Text('Logout', style: TextStyle(color: Colors.white)),
                  onTap: () => logout(context),
                ),
              ],
            ),
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("  Now Showing",
                      style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 10),
                  FutureBuilder(
                    future: nowShowing,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final movies = snapshot.data!;
                      return CarouselSlider.builder(
                        itemCount: movies.length,
                        itemBuilder: (context, index, realIdx) {
                          final movie = movies[index];
                          return GestureDetector(
                            onTap: () => _navigateToDetailScreen(context, movie),
                            child: Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    image: DecorationImage(
                                      image: NetworkImage(
                                        "https://image.tmdb.org/t/p/original/${movie.backDropPath}",
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 15,
                                  left: 0,
                                  right: 0,
                                  child: Text(
                                    movie.title,
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              ],
                            ),
                          );
                        },
                        options: CarouselOptions(
                          autoPlay: true,
                          enlargeCenterPage: true,
                          aspectRatio: 1.7,
                          autoPlayInterval: const Duration(seconds: 5),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text("  Up Coming Movies",
                      style: TextStyle(fontSize: 18)),
                  SizedBox(
                    height: 250,
                    child: FutureBuilder(
                      future: upComing,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final movies = snapshot.data!;
                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: movies.length,
                          itemBuilder: (context, index) {
                            final movie = movies[index];
                            return GestureDetector(
                            onTap: () => _navigateToDetailScreen(context, movie),
                            child: Stack(
                              children: [
                                Container(
                                  width: 180,
                                  margin: const EdgeInsets.symmetric(horizontal:10),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    image: DecorationImage(
                                      image: NetworkImage(
                                        "https://image.tmdb.org/t/p/original/${movie.backDropPath}",
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 15,
                                  left: 0,
                                  right: 0,
                                  child: Text(
                                    movie.title,
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              ],
                            ),
                          );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text("  Popular Movies",
                      style: TextStyle(fontSize: 18)),
                  SizedBox(
                    height: 250,
                    child: FutureBuilder(
                      future: popularMovies,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final movies = snapshot.data!;
                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                           physics: const BouncingScrollPhysics(),
                          itemCount: movies.length,
                          itemBuilder: (context, index) {
                            final movie = movies[index];
                            return GestureDetector(
                              onTap: () => _navigateToDetailScreen(context, movie),
                              child: Stack(
                                children: [
                                  Container(
                                    width: 180,
                                    margin: const EdgeInsets.symmetric(horizontal:10),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      image: DecorationImage(
                                        image: NetworkImage(
                                          "https://image.tmdb.org/t/p/original/${movie.backDropPath}",
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 15,
                                    left: 0,
                                    right: 0,
                                    child: Text(
                                      movie.title,
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}