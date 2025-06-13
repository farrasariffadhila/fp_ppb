import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:flutter/services.dart';

class AdminVoucherScreen extends StatefulWidget {
  const AdminVoucherScreen({Key? key}) : super(key: key);

  @override
  State<AdminVoucherScreen> createState() => _AdminVoucherScreenState();
}

class _AdminVoucherScreenState extends State<AdminVoucherScreen> {
  final TextEditingController _durationController = TextEditingController();
  String _generatedCode = '';
  final Random _random = Random();

  String _generateRandomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    return List.generate(6, (index) => chars[_random.nextInt(chars.length)]).join();
  }

  Future<void> _createVoucher() async {
    if (_durationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter duration in days')),
      );
      return;
    }

    final duration = int.tryParse(_durationController.text);
    if (duration == null || duration <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid duration')),
      );
      return;
    }

    final code = _generateRandomCode();
    final expiryDate = DateTime.now().add(Duration(days: duration));

    try {
      await FirebaseFirestore.instance.collection('vouchers').add({
        'code': code,
        'createdAt': FieldValue.serverTimestamp(),
        'expiryDate': expiryDate,
        'isUsed': false,
        'discountPercentage': 10.toInt(), // 10% discount
      });

      setState(() {
        _generatedCode = code;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voucher created successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating voucher: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voucher Management'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create New Voucher',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _durationController,
              decoration: const InputDecoration(
                labelText: 'Duration (days)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _createVoucher,
              child: const Text('Generate Voucher'),
            ),
            if (_generatedCode.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Generated Voucher Code:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _generatedCode,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _generatedCode));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Voucher code copied to clipboard')),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            const Text(
              'Active Vouchers',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('vouchers')
                    .where('expiryDate', isGreaterThan: DateTime.now())
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No active vouchers'));
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final doc = snapshot.data!.docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final expiryDate = (data['expiryDate'] as Timestamp).toDate();

                      return Card(
                        child: ListTile(
                          title: Text('Code: ${data['code']}'),
                          subtitle: Text(
                            'Expires: ${expiryDate.toString().split(' ')[0]}\n'
                            'Status: ${data['isUsed'] ? 'Used' : 'Available'}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              doc.reference.delete();
                            },
                          ),
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
    );
  }

  @override
  void dispose() {
    _durationController.dispose();
    super.dispose();
  }
} 