import 'package:fp_ppb/screens/login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void logout(context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, 'login');
  }

  void favourite(context) {
    Navigator.pushNamed(context, 'favourite');
  }

  void wishlist(context) {
    Navigator.pushNamed(context, 'wishlist');
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Account Information'),
              centerTitle: true,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Logged in as ${snapshot.data?.email}'),
                  const SizedBox(height: 24),
                  OutlinedButton(
                    onPressed: () => logout(context),
                    child: const Text('Logout'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => wishlist(context),
                    label: const Text('Wishlist'),
                  ),
                  OutlinedButton(
                    onPressed: () => favourite(context),
                    child: const Text('Favourite'),
                  ),
                  OutlinedButton(
                    onPressed: () => Navigator.pushNamed(context, 'rent'),
                    child: const Text('Rent'),
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
}