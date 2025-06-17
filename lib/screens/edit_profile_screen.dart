import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  // Kunci form terpisah untuk dialog ganti password
  final _passwordFormKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  // Controller untuk field password
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;

  User? _user;
  bool _isLoading = true;
  String _email = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    _user = _auth.currentUser;
    if (_user == null) {
      // Handle user not logged in case
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Load display name from Firestore
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(_user!.uid).get();

      String displayName = _user!.displayName ?? '';
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>?;
        displayName = data?.containsKey('displayName') == true
            ? data!['displayName']
            : displayName;
      }

      setState(() {
        _nameController.text = displayName;
        _email = _user!.email ?? 'No email associated';
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load user data: $e')),
      );
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final newName = _nameController.text.trim();

      // Update display name in Firebase Auth
      await _user!.updateDisplayName(newName);

      // Update display name in Firestore
      await _firestore.collection('users').doc(_user!.uid).set(
        {'displayName': newName},
        SetOptions(merge: true),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );

      // Reload user to get the updated info
      await _user!.reload();
      setState(() {
        _user = _auth.currentUser;
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Menampilkan dialog untuk ganti password
  void _showChangePasswordDialog() {
    // Reset field setiap kali dialog dibuka
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();

    showDialog(
      context: context,
      builder: (context) {
        bool isChangingPassword = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.grey[850],
              title: const Text('Change Password', style: TextStyle(color: Colors.white)),
              content: Form(
                key: _passwordFormKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _currentPasswordController,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Current Password'),
                        validator: (value) => value!.isEmpty ? 'Cannot be empty' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _newPasswordController,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('New Password'),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Cannot be empty';
                          if (value.length < 6) return 'Password must be at least 6 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Confirm New Password'),
                        validator: (value) {
                          if (value != _newPasswordController.text) return 'Passwords do not match';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                ),
                if (isChangingPassword)
                  const CircularProgressIndicator()
                else
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                    onPressed: () {
                      _changePassword(setDialogState);
                    },
                    child: const Text('Update', style: TextStyle(color: Colors.white)),
                  ),
              ],
            );
          },
        );
      },
    );
  }
  
  // Fungsi untuk mengubah password
  Future<void> _changePassword(StateSetter setDialogState) async {
    if (_passwordFormKey.currentState?.validate() != true) {
      return;
    }
    
    setDialogState(() => true);

    try {
      final user = _auth.currentUser;
      final cred = EmailAuthProvider.credential(
        email: user!.email!,
        password: _currentPasswordController.text.trim(),
      );

      // Re-autentikasi pengguna
      await user.reauthenticateWithCredential(cred);

      // Jika berhasil, update password
      await user.updatePassword(_newPasswordController.text.trim());

      Navigator.of(context).pop(); // Tutup dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Password updated successfully!'),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'wrong-password') {
        message = 'The current password you entered is incorrect.';
      } else if (e.code == 'weak-password') {
        message = 'The new password is not strong enough.';
      } else {
        message = 'An error occurred: ${e.message}';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text(message),
        ),
      );
    } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('An unexpected error occurred: $e'),
          ),
        );
    } finally {
        setDialogState(() => false);
    }
  }

  // Helper untuk dekorasi input di dialog
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.grey[800],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.blueAccent),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('Edit Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.grey[900],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? const Center(child: Text("Not logged in", style: TextStyle(color: Colors.white)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Profile picture placeholder
                        const Center(
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.blueGrey,
                            child: Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Email (read-only)
                        const Text(
                          'Email',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _email,
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Display Name
                        const Text(
                          'Display Name',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey[800],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            hintText: 'Enter your name',
                            hintStyle: const TextStyle(color: Colors.white54),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Name cannot be empty';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),

                        // Save button
                        ElevatedButton(
                          onPressed: _updateProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Save Changes',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Tombol Ganti Password
                        OutlinedButton.icon(
                          icon: const Icon(Icons.lock_outline),
                          label: const Text('Change Password'),
                          onPressed: _showChangePasswordDialog,
                          style: OutlinedButton.styleFrom(
                             foregroundColor: Colors.white70,
                             side: const BorderSide(color: Colors.white24),
                             padding: const EdgeInsets.symmetric(vertical: 12),
                             shape: RoundedRectangleBorder(
                               borderRadius: BorderRadius.circular(12),
                             )
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}