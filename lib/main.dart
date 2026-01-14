import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gemnest_mobile_app/firebase_options.dart';
import 'package:gemnest_mobile_app/screen/cart_screen/cart_provider.dart';
import 'package:gemnest_mobile_app/services/notification_service.dart';
import 'package:gemnest_mobile_app/splash_screen.dart';
import 'package:gemnest_mobile_app/stripe_service.dart';
import 'package:gemnest_mobile_app/stripe_service_direct.dart';
import 'package:gemnest_mobile_app/theme/app_theme.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file
  await dotenv.load(fileName: ".env");

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // For development: Sign in anonymously to avoid authentication issues
    if (kDebugMode) {
      try {
        await FirebaseAuth.instance.signInAnonymously();
        debugPrint('Development mode: Signed in anonymously');
      } catch (e) {
        debugPrint('Development mode: Anonymous sign-in failed: $e');
        // Continue anyway, will be handled in Stripe service
      }
    }

    // Initialize Stripe services
    await StripeService.initialize();
    await StripeServiceDirect.initialize();

    // Initialize notification service
    await NotificationService().initialize();

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CartProvider()),
          // Add other providers here if needed (e.g., BannerProvider)
        ],
        child: const MyApp(),
      ),
    );
  } catch (e) {
    // Handle initialization failure with a basic error app
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Failed to initialize app: $e',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Function to sign in anonymously (can be called from elsewhere if needed)
Future<void> signInAnonymously() async {
  try {
    UserCredential userCredential =
        await FirebaseAuth.instance.signInAnonymously();
    print('Signed in anonymously with UID: ${userCredential.user?.uid}');
  } on FirebaseAuthException catch (e) {
    print('Failed to sign in anonymously: ${e.message}');
    rethrow; // Optionally rethrow to handle this error elsewhere
  } catch (e) {
    print('Unexpected error during anonymous sign-in: $e');
    rethrow;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GemNest Mobile App',
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
