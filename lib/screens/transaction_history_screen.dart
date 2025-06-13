import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fp_ppb/Services/services.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final APIservices _apiServices = APIservices();

  @override
  Widget build(BuildContext context) {
    final User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Transaction History'),
          backgroundColor: Colors.black,
        ),
        body: const Center(
          child: Text(
            'Please log in to view your transaction history.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    print('Current User UID: ${currentUser.uid}');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Transaction'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('transactions')
            .where('userId', isEqualTo: currentUser.uid)
            .orderBy('startDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No transactions found.',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final transactions = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index].data() as Map<String, dynamic>;
              final String movieTitle = transaction['movieTitle'] ?? 'Unknown Movie';
              final String? posterPath = transaction['posterPath'];
              final String startDate = transaction['startDate'] ?? 'N/A';
              final String status = transaction['status'] ?? 'N/A';
              final int totalPrice = (transaction['totalPrice'] as num?)?.toInt() ?? 0;

              Color statusColor;
              switch (status) {
                case 'waiting for confirmation':
                  statusColor = Colors.yellow;
                  break;
                case 'on rent':
                  statusColor = Colors.green;
                  break;
                case 'lost':
                  statusColor = Colors.red;
                  break;
                case 'returned':
                  statusColor = Colors.blue;
                  break;
                default:
                  statusColor = Colors.grey;
              }

              return Card(
                color: Colors.grey[900],
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      if (posterPath != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.network(
                            'https://image.tmdb.org/t/p/w200$posterPath',
                            width: 80,
                            height: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 80,
                                height: 120,
                                color: Colors.grey[800],
                                child: const Icon(Icons.movie, color: Colors.white54),
                              );
                            },
                          ),
                        )
                      else
                        Container(
                          width: 80,
                          height: 120,
                          color: Colors.grey[800],
                          child: const Icon(Icons.movie, color: Colors.white54),
                        ),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              movieTitle,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              'Status: $status',
                              style: TextStyle(
                                fontSize: 16,
                                color: statusColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              'Start Date: $startDate',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              'Total Price: Rp ${totalPrice.toString()}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
} 