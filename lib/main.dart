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
      initialRoute: 'home',
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

          return PaymentScreen(
            transactionId: transactionId,
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
