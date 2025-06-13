import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

class AdminHistoryScreen extends StatelessWidget {
  const AdminHistoryScreen({Key? key}) : super(key: key);

  // Fungsi untuk mendapatkan judul film dari TMDB API
  Future<String> _getMovieTitleFromTmdb(String movieId) async {
    if (movieId.isEmpty || movieId == '0') return 'Unknown Movie (ID: $movieId)';

    final tmdbApiKey = dotenv.env['TMDB_API_KEY'];
    if (tmdbApiKey == null) {
      return 'API Key Not Found';
    }

    final url = 'https://api.themoviedb.org/3/movie/$movieId?api_key=$tmdbApiKey';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['title']?.toString() ?? 'Movie Title Not Found';
      } else {
        return 'Failed to load movie title (Status: ${response.statusCode})';
      }
    } catch (e) {
      print('Error fetching movie title from TMDB for ID $movieId: $e');
      return 'Error Fetching Movie Title';
    }
  }

  Future<List<Map<String, dynamic>>> _getUserTransactions(String userId) async {
    print('DEBUG: Memulai _getUserTransactions untuk userId: $userId');

    final txSnap = await FirebaseFirestore.instance
        .collection('transactions')
        .where('userId', isEqualTo: userId) // Diubah dari 'userID' menjadi 'userId'
        .get();

    print('DEBUG: Query Firestore selesai. Ditemukan ${txSnap.docs.length} dokumen.');

    List<Map<String, dynamic>> txs = [];
    for (var doc in txSnap.docs) {
      final data = doc.data() as Map<String, dynamic>?; // Cast safely

      String movieTitle = 'Unknown Movie'; // Default fallback
      String startDate = 'N/A';
      String endDate = 'N/A';

      if (data != null) {
        // Ambil judul film dari koleksi movies via TMDB API
        if (data.containsKey('movieId') && data['movieId'] != null) {
          final movieId = data['movieId'].toString();
          movieTitle = await _getMovieTitleFromTmdb(movieId); // Panggil fungsi baru ini
        }

        // Ambil dan hitung durasi (bagian ini tidak lagi menghitung durasi)
        if (data.containsKey('startDate') && data['startDate'] != null) {
          startDate = data['startDate'].toString();
        }
        if (data.containsKey('endDate') && data['endDate'] != null) {
          endDate = data['endDate'].toString();
        }
      }

      txs.add({
        'startDate': startDate,
        'endDate': endDate,
        'movieTitle': movieTitle,
      });
    }
    print('DEBUG: Selesai _getUserTransactions. Mengembalikan ${txs.length} transaksi.');
    return txs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History Transaksi User')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No users found.'));
          }
          final users = snapshot.data!.docs;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final userData = user.data() as Map<String, dynamic>?;
              return ListTile(
                title: Text(
                    (userData != null && userData.containsKey('email') && userData['email'] != null)
                        ? userData['email']
                        : user.id),
                onTap: () async {
                  print('DEBUG: ListTile user tapped. user.id: ${user.id}');
                  final txs = await _getUserTransactions(user.id);
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text('History Transaksi', style: Theme.of(context).textTheme.titleLarge),
                        ...txs.map((tx) => ListTile(
                              title: Text(tx['movieTitle']),
                              subtitle: Text('Tanggal: ${tx['startDate']} - ${tx['endDate']}'),
                            )),
                        if (txs.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('Belum ada transaksi.'),
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
  }
} 