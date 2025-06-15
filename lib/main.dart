import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fp_ppb/screens/detail.dart';
import 'package:fp_ppb/screens/home.dart';
import 'package:fp_ppb/screens/login.dart';
import 'package:fp_ppb/screens/register.dart';
import 'package:fp_ppb/screens/favourite.dart';
import 'package:fp_ppb/screens/rent.dart';
import 'package:fp_ppb/screens/wishlist.dart';
import 'package:fp_ppb/screens/payment.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'screens/admin_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
    print("✅ .env loaded: ${dotenv.env['TMDB_API_KEY']}");
  } catch (e) {
    print("❌ Failed to load .env: $e");
  }

  // Inisialisasi Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FlutterError.onError = (details) {
    FirebaseCrashlytics.instance.recordFlutterError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Movie App',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.black,
        drawerTheme: const DrawerThemeData(
          backgroundColor: Colors.black,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          bodySmall: TextStyle(color: Colors.white70),
        ),
      ),
      home: const AuthGate(),
      routes: {
        'home': (context) => const HomeScreen(),
        'login': (context) => const LoginScreen(),
        'register': (context) => const RegisterScreen(),
        'favourite': (context) => const FavouriteScreen(),
        'rent': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          final movieId = args?['movieId'] ?? 0;
          return RentScreen(movieId: movieId);
        },
        'wishlist': (context) => const WishlistScreen(),
        'payment': (context) {
          final args = ModalRoute.of(context)?.settings.arguments
          as Map<String, dynamic>?;

          final transactionId = args?['transactionId'] ?? '';
          final movieId = args?['movieId'] ?? 0;

          return PaymentScreen(
            transactionId: transactionId,
            movieId: movieId,
          );
        },
        'detail': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          final movieId = args?['movieId'] ?? 0;
          return DetailScreen(movieId: movieId);
        },
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          final user = snapshot.data!;
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
            builder: (context, userDocSnapshot) {
              if (userDocSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              if (userDocSnapshot.hasData && userDocSnapshot.data!.exists) {
                final userData = userDocSnapshot.data!.data() as Map<String, dynamic>?;
                final isAdmin = userData?['isAdmin'] ?? false;
                if (isAdmin == true) {
                  return AdminScreen(adminEmail: user.email ?? '');
                } else {
                  return const HomeScreen();
                }
              } else {
                // Jika dokumen user tidak ditemukan di Firestore, mungkin user baru register
                // atau data belum disimpan. Arahkan ke home sebagai default.
                return const HomeScreen();
              }
            },
          );
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
