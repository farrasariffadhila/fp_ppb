import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter/material.dart';
import 'login.dart';

class PaymentScreen extends StatefulWidget {
  final String transactionId;

  const PaymentScreen({super.key, required this.transactionId});

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  DocumentSnapshot? _transactionData;
  bool _isLoading = true;  
  bool _showSuccess = false;

  @override
  void initState() {
    super.initState();
    _startPaymentProcess();
    if (widget.transactionId.isEmpty) {
      // print('Transaction ID is empty, redirecting to home'); and transactionId
      print('Transaction ID is empty, redirecting to home "${widget.transactionId}" dasda');
    } else {
      getTransactionData();  // Fetch transaction data when transactionId is available
    }
  }

  Future<void> _startPaymentProcess() async {
    await Future.delayed(const Duration(seconds: 3)); 

    if (mounted) {
      setState(() {
        _isLoading = false;
        _showSuccess = true;
      });
    }

    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _showSuccess = false;
      });
    }
  }

  String formatNumber(int number) {
    return number.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.');
  }

  void getTransactionData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final transactionRef = FirebaseFirestore.instance
        .collection('transactions')
        .doc(widget.transactionId);  // Accessing transactionId from widget


    try {
      _transactionData = await transactionRef.get();
      if (_transactionData != null && _transactionData!.exists) {
        setState(() {});
      }
      print('Transaction data: ${_transactionData?.data()}');
    } catch (e) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, 'home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background content
          SingleChildScrollView(
            padding: const EdgeInsets.only(left: 16, right: 16),
            child: Center(
              child: Visibility(
                visible: !_isLoading && !_showSuccess,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 30),
                    Image.asset(
                      'assets/logo/logo.png',
                      height: 200,
                    ),
                    const Text(
                      'Payment Successful',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text(
                      _transactionData != null && _transactionData!.exists
                          ? 'Rp ${formatNumber(_transactionData!['totalPrice'] ?? 0)}'
                          : '', 
                      style: TextStyle(fontSize: 30, color: Colors.black, fontWeight: FontWeight.w900),
                    ),
                    SizedBox(height: 10),
                    Text(
                      _transactionData != null && _transactionData!.exists
                          ? 'Ref: ${_transactionData!['transactionId'] ?? widget.transactionId}'
                          : 'Ref: ${widget.transactionId}',  // Fallback to widget.transactionId if no transaction data exists
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
                    SizedBox(height: 20),
                    const Text(
                      'Movie Details',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Divider(
                      color: Colors.grey.shade800,
                      thickness: 1,
                      height: 1,
                    ),
                    
                    Container(
                      margin: EdgeInsets.all(8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            height: 150,
                            width: 112,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.black, width: 3),
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
                                          color: Colors.black, // White text color
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
                                          color: Colors.black, // Lighter text color
                                        ),
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
                    
                    // Text header
                    const SizedBox(height: 20),
                    Column(
                      children: [
                        const Text(
                          'Payment Details',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        Divider(
                          color: Colors.grey.shade800,
                          thickness: 1,
                          height: 1,
                        ),
                        InfoRow(label: 'Name', value: _transactionData?['name'] ?? 'N/A'),
                        InfoRow(label: 'Email', value: _transactionData?['email'] ?? 'N/A'),
                        InfoRow(label: 'Phone', value: _transactionData?['phone'] ?? 'N/A'),
                        InfoRow(label: 'Address', value: _transactionData?['address'] ?? 'N/A'),
                        InfoRow(label: 'Start Date', value: _transactionData?['startDate'] ?? 'N/A'),
                        InfoRow(label: 'End Date', value: _transactionData?['endDate'] ?? 'N/A'),
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              Navigator.pushNamed(context, 'home');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black, // Button color
                              padding: const EdgeInsets.symmetric(vertical: 16), // Button padding
                            ),
                            child: const Text('Return to Home', 
                              style: TextStyle(fontSize: 18, color: Colors.white)),

                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Display loading animation while _isLoading is true, centered
          if (_isLoading)
            Center(
              child: Lottie.asset('assets/animation/loading.json', height: 300),
            ),
          
          // Display success animation if _showSuccess is true, centered
          if (_showSuccess)
            Center(
              child: Lottie.asset('assets/animation/paymentSuccess.json', height: 350),
            ),
        ],
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space between to push label to the left and value to the right
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Expanded(  // Make sure value takes up remaining space
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.end,  // Align the value to the right
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
