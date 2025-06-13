import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Model/transaction.dart';
import 'admin_profile_screen.dart';
import 'admin_history_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

class AdminScreen extends StatefulWidget {
  final String adminEmail;
  const AdminScreen({Key? key, required this.adminEmail}) : super(key: key);

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final Map<String, Future<String>> _movieTitleCache = {};


  Future<String> _getMovieTitle(String movieId) async {
    if (_movieTitleCache.containsKey(movieId)) {
      return _movieTitleCache[movieId]!;
    }

    if (movieId.isEmpty || movieId == '0') {
      final result = Future.value('Unknown Movie (ID: $movieId)');
      _movieTitleCache[movieId] = result;
      return result;
    }

    final tmdbApiKey = dotenv.env['TMDB_API_KEY'];
    if (tmdbApiKey == null) {
      final result = Future.value('API Key Not Found');
      _movieTitleCache[movieId] = result;
      return result;
    }

    final url = 'https://api.themoviedb.org/3/movie/$movieId?api_key=$tmdbApiKey';
    final future = http.get(Uri.parse(url)).then((response) {
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['title']?.toString() ?? 'Movie Title Not Found';
      } else {
        return 'Failed to load movie title (Status: ${response.statusCode})';
      }
    }).catchError((e) {
      print('Error fetching movie title from TMDB for ID $movieId: $e');
      return 'Error Fetching Movie Title';
    });

    _movieTitleCache[movieId] = future; 
    return future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).snapshots(),
              builder: (context, snapshot) {
                String userName = widget.adminEmail; // Default ke email
                String userEmail = widget.adminEmail; // Default ke email

                if (snapshot.hasData && snapshot.data!.exists) {
                  final userData = snapshot.data!.data() as Map<String, dynamic>?;
                  if (userData != null) {
                    userName = userData['name']?.toString() ?? widget.adminEmail; // Ambil nama
                    userEmail = userData['email']?.toString() ?? widget.adminEmail; // Ambil email
                  }
                }

                return UserAccountsDrawerHeader(
                  accountName: Text(userName),
                  accountEmail: Text(userEmail),
                  currentAccountPicture: const CircleAvatar(child: Icon(Icons.person)),
                  decoration: BoxDecoration(color: Colors.grey[800]),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Edit Profil'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminProfileScreen(adminEmail: widget.adminEmail),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('History Transaksi'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminHistoryScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (!context.mounted) return;
                Navigator.pushReplacementNamed(context, 'login');
              },
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('transactions').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No transactions found.'));
          }
          final transactions = snapshot.data!.docs
              .map((doc) => TransactionModel.fromDocument(doc))
              .toList();
          return ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final tx = transactions[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ListTile(
                  title: FutureBuilder<String>(
                    future: _getMovieTitle(tx.movieId),
                    builder: (context, movieTitleSnapshot) {
                      if (movieTitleSnapshot.connectionState == ConnectionState.waiting) {
                        return const Text('Loading movie...');
                      }
                      if (movieTitleSnapshot.hasError) {
                        return Text('Error: ${movieTitleSnapshot.error}');
                      }
                      return Text(movieTitleSnapshot.data ?? 'Unknown Movie');
                    },
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('User: ${tx.name}'),
                      Text('Status: ${tx.status}'),
                      Text('Total: ${tx.totalPrice}'),
                      Text('Tanggal: ${tx.startDate} - ${tx.endDate}'),
                    ],
                  ),
                  trailing: DropdownButton<String>(
                    value: tx.status,
                    items: [
                      DropdownMenuItem(
                        value: 'waiting for confirmation',
                        child: Text('Waiting for Confirmation', style: TextStyle(color: Colors.yellow[700])),
                      ),
                      DropdownMenuItem(
                        value: 'on rent',
                        child: Text('On Rent', style: TextStyle(color: Colors.green[700])),
                      ),
                      DropdownMenuItem(
                        value: 'returned',
                        child: Text('Returned', style: TextStyle(color: Colors.blue[700])),
                      ),
                      DropdownMenuItem(
                        value: 'lost',
                        child: Text('Lost', style: TextStyle(color: Colors.red[700])),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        FirebaseFirestore.instance
                            .collection('transactions')
                            .doc(tx.id)
                            .update({'status': value});
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
} 