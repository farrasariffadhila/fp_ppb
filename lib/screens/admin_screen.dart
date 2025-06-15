import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Model/transaction.dart';
import 'admin_profile_screen.dart';
import 'admin_history_screen.dart';
import 'admin_voucher_screen.dart';
import 'admin_movie_item_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../Services/inventory_service.dart';

class AdminScreen extends StatefulWidget {
  final String adminEmail;
  const AdminScreen({Key? key, required this.adminEmail}) : super(key: key);

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final Map<String, Future<String>> _movieTitleCache = {};
  final InventoryService _inventoryService = InventoryService();


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

  String formatNumber(int number) {
    return number.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.');
  }


  void _showUpdateDialog(TransactionModel tx) {
    TextEditingController nameController = TextEditingController(text: tx.name);
    TextEditingController phoneController = TextEditingController(text: tx.phone);
    TextEditingController addressController = TextEditingController(text: tx.address);
    TextEditingController totalPriceController = TextEditingController(text: tx.totalPrice.toString());
    TextEditingController startDateController = TextEditingController(text: tx.startDate);
    TextEditingController endDateController = TextEditingController(text: tx.endDate);

    String formatDate(DateTime date) {
      final DateFormat formatter = DateFormat('dd/MM/yyyy');
      return formatter.format(date);
    }

    // Function to pick a date and update the corresponding TextField
    Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
      final DateTime currentDate = DateTime.now();
      // apabila endDateController maka
      final DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: DateFormat('dd/MM/yyyy').parse(controller.text),
        firstDate: currentDate,
        lastDate: DateTime(2101),
        builder: (BuildContext context, Widget? child) {
          return Theme(
            data: ThemeData.dark().copyWith(
              primaryColor: Colors.blueAccent, // Change the primary color
              hintColor: Colors.blueAccent, // Change the accent color
              colorScheme: ColorScheme.dark(primary: Colors.blueAccent), // Change the color scheme
              buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary), // Change button text color
            ),
            child: child!,
          );
        },
      );
      if (pickedDate != null && pickedDate != currentDate) {
        controller.text = formatDate(pickedDate); // Update the text field with selected date
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Transaction'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                ),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                ),
                TextField(
                  controller: totalPriceController,
                  decoration: const InputDecoration(labelText: 'Total Price'),
                ),
                GestureDetector(
                  onTap: () => _selectDate(context, startDateController),
                  child: AbsorbPointer(
                    child: TextField(
                      controller: startDateController,
                      decoration: const InputDecoration(labelText: 'Start Date'),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _selectDate(context, endDateController),
                  child: AbsorbPointer(
                    child: TextField(
                      controller: endDateController,
                      decoration: const InputDecoration(labelText: 'End Date'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red[700],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Cancel', style: TextStyle(color: Colors.white)),
              ),
            ),
            TextButton(
              onPressed: () async {
                // Save the updated data back to Firestore
                await FirebaseFirestore.instance.collection('transactions').doc(tx.id).update({
                  'name': nameController.text,
                  'totalPrice': int.tryParse(totalPriceController.text) ?? 0,
                  'startDate': startDateController.text,
                  'endDate': endDateController.text,
                });

                Navigator.of(context).pop(); // Close the dialog
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue[700],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Update', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        );
      },
    );
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
              leading: const Icon(Icons.movie),
              title: const Text('Movie Inventory'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminMovieItemPage(),
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
            ListTile(
              leading: const Icon(Icons.card_giftcard),
              title: const Text('Voucher Management'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminVoucherScreen(),
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
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Row for Title and Dropdown
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: FutureBuilder<String>(
                              future: _getMovieTitle(tx.movieId),
                              builder: (context, movieTitleSnapshot) {
                                if (movieTitleSnapshot.connectionState == ConnectionState.waiting) {
                                  return const Text('Loading movie...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16));
                                }
                                if (movieTitleSnapshot.hasError) {
                                  return Text('Error: ${movieTitleSnapshot.error}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16));
                                }
                                return Text(
                                  movieTitleSnapshot.data ?? 'Unknown Movie',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          DropdownButton<String>(
                            value: tx.status,
                            items: [
                              DropdownMenuItem(
                                value: 'waiting for confirmation', 
                                child: Text('Waiting for confirmatio', style: TextStyle(color: Colors.yellow[700]))),
                              DropdownMenuItem(
                                value: 'on rent', 
                                child: Text('On Rent', style: TextStyle(color: Colors.green[700]))),
                              DropdownMenuItem(
                                value: 'returned', 
                                child: Text('Returned', style: TextStyle(color: Colors.blue[700]))),
                              DropdownMenuItem(
                                value: 'lost', 
                                child: Text('Lost', style: TextStyle(color: Colors.red[700]))),
                            ],
                            onChanged: (value) async {
                              if (value != null) {
                                if (value == 'returned' && !tx.isReturned) {
                                  await _inventoryService.returnMovie(int.tryParse(tx.movieId) ?? 0);
                                  await FirebaseFirestore.instance.collection('transactions').doc(tx.id).update({'isReturned': true});
                                }
                                await FirebaseFirestore.instance.collection('transactions').doc(tx.id).update({'status': value});
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Transaction Details
                      Text('User: ${tx.name}'),
                      const SizedBox(height: 4),
                      Text('Status: ${tx.status}'),
                      const SizedBox(height: 4),
                      Text('Total: Rp ${formatNumber(tx.totalPrice)}'),
                      const SizedBox(height: 4),
                      Text('Tanggal: ${tx.startDate} - ${tx.endDate}'),
                      const SizedBox(height: 4),

                      // Update Button aligned to the right
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          width: 100,
                          margin: EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.blue,
                          ),
                          child: TextButton(
                            onPressed: () => _showUpdateDialog(tx),
                            child: const Text('Update', style: TextStyle(color: Colors.white)),
                          ),
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
} 