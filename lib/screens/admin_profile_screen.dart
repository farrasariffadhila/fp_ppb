import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminProfileScreen extends StatefulWidget {
  final String adminEmail;
  const AdminProfileScreen({Key? key, required this.adminEmail}) : super(key: key);

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final _nameController = TextEditingController();
  final _reauthPasswordController = TextEditingController();
  bool _isLoading = true;
  String? _docId;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: widget.adminEmail)
        .limit(1)
        .get();
    if (userDoc.docs.isNotEmpty) {
      final data = userDoc.docs.first.data();
      _nameController.text = data['name'] ?? '';
      _docId = userDoc.docs.first.id;
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveProfile() async {
    if (_docId != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_docId)
          .update({'name': _nameController.text});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil diperbarui')));
    }
  }

  Future<void> _deleteAccount() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (_docId == null || currentUser == null) {
      return;
    }

    final String? password = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Re-autentikasi Diperlukan'),
        content: TextField(
          controller: _reauthPasswordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Password Anda'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, _reauthPasswordController.text),
            child: const Text('Konfirmasi'),
          ),
        ],
      ),
    );

    if (password == null || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Re-autentikasi dibatalkan.')));
      return;
    }

    try {
      final AuthCredential credential = EmailAuthProvider.credential(
        email: currentUser.email!,
        password: password,
      );

      await currentUser.reauthenticateWithCredential(credential);

      await FirebaseFirestore.instance.collection('users').doc(_docId).delete();
      await currentUser.delete();

      if (!context.mounted) return;
      Navigator.pushReplacementNamed(context, 'login');

    } on FirebaseAuthException catch (e) {
      String errorMessage;
      if (e.code == 'wrong-password') {
        errorMessage = 'Password salah. Silakan coba lagi.';
      } else if (e.code == 'user-not-found') {
        errorMessage = 'User tidak ditemukan.';
      } else {
        errorMessage = 'Terjadi kesalahan: ${e.message}';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Terjadi kesalahan tak terduga: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profil Admin')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Nama'),
                  ),
                  const SizedBox(height: 16),
                  Text('Email: ${widget.adminEmail}'),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _saveProfile,
                    child: const Text('Simpan'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _deleteAccount,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Hapus Akun'),
                  ),
                ],
              ),
            ),
    );
  }
} 