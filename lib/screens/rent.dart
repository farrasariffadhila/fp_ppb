import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'login.dart';

class RentScreen extends StatefulWidget {
  const RentScreen({super.key});

  @override
  State<RentScreen> createState() => _RentScreenState();
}

class _RentScreenState extends State<RentScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  static const price = 50000;
  late String userId;

  Future<void> getEmail() async {
    User? user = _auth.currentUser;
    if (user != null) {
      userId = user.uid;
      _emailController.text = user.email ?? '';
    } else {
      if (!context.mounted) return;
      Navigator.pushReplacementNamed(context, 'login');
    }
  }

  String formatNumber(int number) {
    return number.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.');
  }

  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    getEmail();
    _startDateController.text = DateTime.now().toLocal().toString().split(' ')[0];
    _endDateController.text = (DateTime.now().add(Duration(days: 1)).toLocal().toString().split(' ')[0]);
  }

  void payment(transactionId) {
    // push transaction id to payment screen
    Navigator.pushReplacementNamed(context, 'payment', arguments:{
      'transactionId': transactionId,
    });
  }
     

  void addTransaction(movieid) async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        // check movie availability
        DocumentSnapshot movieDoc = await _firestore.collection('movies').doc(movieid).get();
        if (!movieDoc.exists) {
          await _firestore.collection('movies').doc(movieid).set({
            'availableItems': 1,
          });
        } else {
          int availableItems = movieDoc['availableItems'] ?? 0;
          if (availableItems > 0) {
            await _firestore.collection('movies').doc(movieid).update({
              'availableItems': availableItems - 1,
            });
          } else {
            if (!context.mounted) return;
            // create popup dialog to inform user that there are no available items
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('No Available Items'),
                content: Text('Sorry, there are no available items for rent at the moment.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('OK'),
                  ),
                ],
              ),
            );
            return;
          }
        }

        // create ref of the transaction from time now
        final now = DateTime.now();
        final transactionRef = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}${now.millisecond.toString().padLeft(3, '0')}';
        // Add transaction to Firestore
        DocumentReference transactionDocRef = await _firestore.collection('transactions').add({
          'userId': userId,
          'name': _nameController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
          'address': _addressController.text,
          'startDate': _startDateController.text,
          'endDate': _endDateController.text,
          'totalPrice': price * (_endDate != null && _startDate != null ? _endDate!.difference(_startDate!).inDays : 0),
          'transactionId': transactionRef,
          'movieId': movieid,
        });

        // Pass the generated transaction ID to the payment method
        payment(transactionDocRef.id);

        // clear the form fields
        _nameController.clear();
        _emailController.clear();
        _phoneController.clear();
        _addressController.clear();
        _startDateController.clear();
        _endDateController.clear();

      } catch (e) {
        if (!context.mounted) return;
      }
    }
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
            backgroundColor: Colors.black, // Dark background for the scaffold
            body: SafeArea(
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white), // Change icon color
                      onPressed: () {
                        Navigator.pop(context); // Go back to the previous screen
                      },
                    ),
                    SizedBox(width: 16),
                    Text(
                      'Rent Details',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // White text color
                      ),
                    ),
                  ],
                ),
                Container(
                  height: 20, 
                  color: Colors.transparent,
                  child: const Divider(
                    color: Colors.white, // White divider color
                    thickness: 1,
                    indent: 16,
                    endIndent: 16,
                  ),
                ), 
                SizedBox(height: 20),
                Container(
                  margin: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: Offset(0, 3),
                        color: Colors.black45, // Dark shadow
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        height: 200,
                        width: 150,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFFFF),
                          image: const DecorationImage(
                            image: NetworkImage('https://images.tokopedia.net/img/cache/700/product-1/2019/2/21/15258503/15258503_ce050051-1d6c-4ab6-9793-9b27c3dfa2f1_348_528.jpg'),
                            fit: BoxFit.cover,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                          
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  alignment: Alignment.topLeft,
                                  child: Text(
                                    'Rent Item Name',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white, // White text color
                                    ),
                                  ),
                                ),
                                SizedBox(height: 10),
                                Container(
                                  height: 100,
                                  child: Text(
                                    'Description of the item goes here. It can be a brief overview of the item being rented.',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white70, // Lighter text color
                                    ),
                                  ),
                                ),
                                SizedBox(height: 10),
                                Container(
                                  alignment: Alignment.bottomRight,
                                  child: Text(
                                    'Price: \$100',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white, // White text color
                                    ),
                                    textAlign: TextAlign.end, // Center align the price text
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(25),
                        topRight: Radius.circular(25),
                      ),
                      color: Colors.grey[900], // Dark background for the form container
                      boxShadow: [
                        BoxShadow(
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                          color: Colors.black45, // Dark shadow
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Please fill in the details below to proceed with your rental.',
                            style: TextStyle(fontSize: 18, color: Colors.white70),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                SizedBox(height: 16),
                                SizedBox(height: 2),
                                _buildTextField(_nameController, 'Name'),
                                SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(right: 8.0),
                                        child: _buildTextField(_emailController, 'Email'),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 8.0),
                                        child: _buildTextField(_phoneController, 'Phone'),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),
                                _buildTextField(_addressController, 'Address'),
                                SizedBox(height: 16),
                                  Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(right: 8.0),
                                        child:_buildDatePicker('Start Date', _startDateController, (date) {
                                        setState(() {
                                          _startDate = date;
                                        });
                                        }
                                      ),
                                    ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 8.0),
                                        child: _buildDatePicker('End Date', _endDateController, (date) {
                                          setState(() {
                                            _endDate = date;
                                          });
                                        }
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 20),
                          Divider(
                            color: Colors.white, // White divider color
                            thickness: 1,
                          ),
                          SizedBox(height: 10),
                          Container(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              'Total Price: Rp ${_startDate != null && _endDate != null ? formatNumber(price * (_endDate!.difference(_startDate!).inDays)) : '0'}',
                              style: TextStyle(fontSize: 20, color: Colors.white70),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(height: 15),
                          Container(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState?.validate() ?? false) {
                                  addTransaction('rent_item_id'); // Replace with actual movie ID
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent, // Button color
                                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                              ),
                              child: Text('Submit', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white), // White label text color
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: TextStyle(color: Colors.white54), // Lighter hint color
        filled: true,
        fillColor: Colors.grey[800], // Dark field background color
      ),
      style: TextStyle(color: Colors.white), // Text input color
      validator: (value) {
        if (controller == _emailController) {
          if (value == null || value.isEmpty) {
            return '$label is required';
          }
          final emailPattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
          final regex = RegExp(emailPattern);
          if (!regex.hasMatch(value)) {
            return 'Please enter a valid email address';
          }
        } else if (controller == _phoneController) {
          if (value == null || value.isEmpty) {
            return '$label is required';
          }
          final phonePattern = r'^\+?[0-9]{9,15}$';
          final regex = RegExp(phonePattern);
          if (!regex.hasMatch(value)) {
            return 'Please enter a valid phone number';
          }
        } else if (controller == _addressController) {
          if (value == null || value.isEmpty) {
            return '$label is required';
          }
        } else {
        }
        if (value == null || value.isEmpty) {
          return '$label is required';
        }
        return null;
      },
    );
  }

  Widget _buildDatePicker(String label, TextEditingController controller, Function(DateTime?) onDateSelected) {
    return GestureDetector(
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2101),
          builder: (BuildContext context, Widget? child) {
            return Theme(
              data: ThemeData.light().copyWith(
                primaryColor: Colors.blueAccent, // Change the primary color
                hintColor: Colors.blueAccent, // Change the accent color
                colorScheme: ColorScheme.light(primary: Colors.blueAccent), // Change the color scheme
                buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary), // Change button text color
              ),
              child: child!,
            );
          },
        );
        if (pickedDate != null) {
          onDateSelected(pickedDate);
          controller.text = '${pickedDate.day}/${pickedDate.month}/${pickedDate.year}'; // Set the picked date in the controller
        }
      },
      child: AbsorbPointer(
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: Colors.white), // White label text color
            
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            suffixIcon: Icon(Icons.calendar_today, color: Colors.white), // Calendar icon color
          ),
          style: TextStyle(color: Colors.white), // Text input color
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '$label is required';
            }
            return null;
          },
        ),
      ),
    );
  }
}
