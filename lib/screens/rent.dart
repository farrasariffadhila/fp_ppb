import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fp_ppb/Services/services.dart';
import 'package:fp_ppb/Services/inventory_service.dart';
import 'login.dart';
import '../Model/voucher.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:intl/intl.dart';
class RentScreen extends StatefulWidget {
  final int movieId;
  
  const RentScreen({super.key,required this.movieId});

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
  final TextEditingController _voucherController = TextEditingController();
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final APIservices _apiServices = APIservices();
  final InventoryService _inventoryService = InventoryService();
  
  static const price = 50000;
  Voucher? _appliedVoucher;
  double _discountedPrice = 0;

  Map<String, dynamic>? movieDetails;
  late String userId;
  bool isLoading = true;

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

  String formatDate(DateTime date) {
    // D/M/YYYY format
    return '${date.day}/${date.month}/${date.year}';
  }

  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    getEmail();
    _fetchMovieDetails();
    _startDateController.text = formatDate(DateTime.now().toLocal());
    _startDate = DateTime.now().toLocal();
    _endDateController.text = formatDate(DateTime.now().toLocal().add(const Duration(days: 1)));
    _endDate = DateTime.now().toLocal().add(const Duration(days: 1));
  }

  Future<void> _fetchMovieDetails() async {
    try {
      final details = await _apiServices.getMovieDetails(widget.movieId);
      
      final credits = await _apiServices.getMovieCredits(widget.movieId);

      if (credits != null) {
        setState(() {
          movieDetails = details;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
      print('Error fetching movie details: $e');
    }
  }

  void payment(transactionId) {
    // push transaction id to payment screen
    Navigator.pushReplacementNamed(context, 'payment', arguments:{
      'transactionId': transactionId,
      'movieId': widget.movieId,
    });
  }
     

  Future<void> _applyVoucher() async {
    if (_voucherController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a voucher code')),
      );
      return;
    }

    try {
      final voucherQuery = await _firestore
          .collection('vouchers')
          .where('code', isEqualTo: _voucherController.text.toUpperCase())
          .get();

      if (voucherQuery.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid voucher code')),
        );
        return;
      }

      final voucher = Voucher.fromDocument(voucherQuery.docs.first);
      
      if (!voucher.isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voucher is expired or has been used')),
        );
        return;
      }

      setState(() {
        _appliedVoucher = voucher;
        // apabila day different = 0, maka day different = 1
        final daysDifference = _endDate != null && _startDate != null ? _endDate!.difference(_startDate!).inDays == 0 ? 1 : _endDate!.difference(_startDate!).inDays : 1;
        _discountedPrice = (price * daysDifference) * (1 - voucher.discountPercentage / 100);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voucher applied successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error applying voucher: $e')),
      );
    }
  }

  void addTransaction(movieid) async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        final reserved = await _inventoryService.reserveMovie(movieid);
        if (!reserved) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Movie tidak tersedia')),
            );
          }
          return;
        }

        final now = DateTime.now();
        final transactionRef = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}${now.millisecond.toString().padLeft(3, '0')}';
        
        final originalPrice = price * (_endDate!.difference(_startDate!).inDays);
        final finalPrice = _appliedVoucher != null ? _discountedPrice.toInt() : originalPrice;
        
        DocumentReference transactionDocRef = await _firestore.collection('transactions').add({
          'userId': userId,
          'movieId': movieid,
          'movieTitle': movieDetails!['title'] ?? 'Unknown Movie',
          'posterPath': movieDetails!['poster_path'],
          'name': _nameController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
          'address': _addressController.text,
          'startDate': _startDateController.text,
          'endDate': _endDateController.text,
          'totalPrice': finalPrice,
          'originalPrice': originalPrice,
          'transactionId': transactionRef,
          'status': 'waiting for confirmation',
          'voucherCode': _appliedVoucher?.code,
          'discountApplied': _appliedVoucher != null ? _appliedVoucher!.discountPercentage : 0,
          'isReturned': false,
        });

        if (_appliedVoucher != null) {
          await _firestore
              .collection('vouchers')
              .doc(_appliedVoucher!.id)
              .update({'isUsed': true});
        }

        payment(transactionDocRef.id);

      } catch (e) {
        print('Error adding transaction: $e');
        await _inventoryService.returnMovie(movieid);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding transaction: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (movieDetails == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Failed to load movie details',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      );
    }

    final posterPath = movieDetails!['poster_path'];
    final title = movieDetails!['title'] ?? 'Unknown Title';
    final overview = movieDetails!['overview'] ?? 'No description available';
    
    return StreamBuilder<User?>(
      stream: _auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData) {
          final user = snapshot.data!;
          userId = user.uid;

          return SafeArea(
            child: Scaffold(
              backgroundColor: Colors.black, // Dark background for the scaffold
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bagian Header dan Detail Film (Statis)
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
                          height: 180,
                          width: 120,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  alignment: Alignment.topLeft,
                                  child: Text(
                                    title,
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
                                    overview,
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
                                    'Price: Rp ${formatNumber(price)}',
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
                      ],
                    ),
                  ),
                  // Bagian Form dan Voucher (Dapat di-scroll)
                  Expanded(
                    child: SingleChildScrollView(
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
                              SizedBox(height: 16),
                              _buildTextField(_nameController, 'Name'),
                              SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildTextField(_emailController, 'Email'),
                                  ),
                                  SizedBox(width: 16), // Jarak antara Email dan Phone
                                  Expanded(
                                    child: _buildTextField(_phoneController, 'Phone'),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              _buildTextField(_addressController, 'Address'),
                              SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildDatePicker('Start Date', _startDateController, (date) {
                                      setState(() {
                                        _startDate = date;
                                      });
                                    }),
                                  ),
                                  SizedBox(width: 16), // Jarak antara Start Date dan End Date
                                  Expanded(
                                    child: _buildDatePicker('End Date', _endDateController, (date) {
                                      setState(() {
                                        _endDate = date;
                                      });
                                    }),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),
                              Divider(
                                color: Colors.white,
                                thickness: 1,
                              ),
                              SizedBox(height: 10),
                              // Apply Voucher section
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Apply Voucher',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _voucherController,
                                          style: const TextStyle(color: Colors.white),
                                          maxLength: 6,
                                          decoration: InputDecoration(
                                            labelText: 'Voucher Code',
                                            labelStyle: const TextStyle(color: Colors.white70),
                                            counterText: '',
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: const BorderSide(color: Colors.white54),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: const BorderSide(color: Colors.white),
                                            ),
                                          ),
                                          textCapitalization: TextCapitalization.characters,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.paste, color: Colors.white),
                                        onPressed: () async {
                                          final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
                                          if (clipboardData != null && clipboardData.text != null) {
                                            setState(() {
                                              _voucherController.text = clipboardData.text!.substring(0, min(clipboardData.text!.length, 6));
                                            });
                                          }
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        onPressed: _applyVoucher,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: const Text('Apply'),
                                      ),
                                    ],
                                  ),
                                  if (_appliedVoucher != null) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.check_circle, color: Colors.green),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Voucher applied: ${_appliedVoucher!.discountPercentage}% off',
                                            style: const TextStyle(color: Colors.green),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              SizedBox(height: 20),
                              Divider(
                                color: Colors.white,
                                thickness: 1,
                              ),
                              SizedBox(height: 10),
                              Container(
                                alignment: Alignment.bottomRight,
                                child: Text(
                                  'Total Price: Rp ${_startDate != null && _endDate != null ? formatNumber(_appliedVoucher != null ? _discountedPrice.toInt() : _endDate!.difference(_startDate!).inDays < 1 ? price : price * (_endDate!.difference(_startDate!).inDays)) : formatNumber(price)}',
                                  style: TextStyle(fontSize: 20, color: Colors.white70),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              SizedBox(height: 15),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () => addTransaction(widget.movieId),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Submit',
                                    style: TextStyle(fontSize: 18, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
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
          initialDate: DateFormat('dd/MM/yyyy').parse(controller.text.isEmpty ? DateFormat('dd/MM/yyyy').format(DateTime.now()) : controller.text),
          firstDate: DateTime.now(),
          lastDate: DateTime(2101),
          builder: (BuildContext context, Widget? child) {
            return Theme(
              data: ThemeData.light().copyWith(
                primaryColor: Colors.blueAccent, // Change the primary color
                hintColor: Colors.blueAccent, // Change the accent color
                colorScheme: ColorScheme.dark(primary: Colors.blueAccent), // Change the color scheme
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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _voucherController.dispose();
    super.dispose();
  }
}