import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Services/inventory_service.dart';
import '../Services/services.dart';
import '../Model/model.dart';

class AdminMovieItemPage extends StatelessWidget {
  const AdminMovieItemPage({Key? key}) : super(key: key);

  void _addStockDialog(BuildContext context, String docId) {
    int movieId = docId.isNotEmpty ? int.tryParse(docId) ?? 0 : 0;
    int jumlahTambah = 1;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tambah Stok Film'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(labelText: 'Jumlah Tambah'),
              keyboardType: TextInputType.number,
              onChanged: (val) {
                jumlahTambah = int.tryParse(val) ?? 1;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (movieId > 0 && jumlahTambah > 0) {
                await InventoryService().changeAvailableStock(movieId, jumlahTambah);
                Navigator.pop(context);
              }
            },
            child: Text('Tambah'),
          ),
        ],
      ),
    );
  }

  void _reduceStockDialog(BuildContext context, String docId, int currentAvailable) {
    int jumlahKurang = 1;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Kurangi Stok Film'),
        content: TextField(
          decoration: InputDecoration(labelText: 'Jumlah Kurang'),
          keyboardType: TextInputType.number,
          onChanged: (val) {
            jumlahKurang = int.tryParse(val) ?? 1;
          },
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final movieId = int.tryParse(docId) ?? 0;
              if (movieId > 0 && jumlahKurang > 0 && currentAvailable > 0) {
                await InventoryService().changeAvailableStock(movieId, -jumlahKurang);
                Navigator.pop(context);
              }
            },
            child: Text('Kurangi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final CollectionReference inventory = FirebaseFirestore.instance.collection('inventory');

    return Scaffold(
      appBar: AppBar(title: Text('Admin: Movie Inventory')),
      body: StreamBuilder<QuerySnapshot>(
        stream: inventory.snapshots(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Semua film ready dengan total 2 item.',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            );
          }

          // Ada data di inventory
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final docId = docs[index].id;
                    final available = data['availableCount'] ?? 0;

                    return FutureBuilder<Map<String, dynamic>>(
                      future: APIservices().getMovieDetails(int.parse(docId)),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return ListTile(
                            leading: SizedBox(width: 50, child: Center(child: CircularProgressIndicator())),
                            title: Text("Loading..."),
                            subtitle: Text('Tersedia: $available'),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data == null) {
                          return ListTile(
                            leading: Icon(Icons.movie),
                            title: Text('Film tidak ditemukan'),
                            subtitle: Text('Tersedia: $available'),
                          );
                        }
                        final movie = snapshot.data!;
                        final posterPath = movie['poster_path'];
                        final title = movie['title'] ?? 'No title available';
                        return Card(
                          margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: ListTile(
                            leading: posterPath != null
                              ? Image.network(
                                  "https://image.tmdb.org/t/p/w200${posterPath}",
                                  width: 50,
                                  fit: BoxFit.cover,
                                )
                              : Icon(Icons.movie),
                            title: Text(title),
                            subtitle: Text('Tersedia: $available'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.add),
                                  onPressed: () => _addStockDialog(context, docId),
                                ),
                                IconButton(
                                  icon: Icon(Icons.remove),
                                  onPressed: () => _reduceStockDialog(context, docId, available),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
