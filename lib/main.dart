import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gemnest_mobile_app/firebase_options.dart';
import 'package:gemnest_mobile_app/screen/cart_screen/cart_provider.dart';
import 'package:gemnest_mobile_app/services/notification_service.dart';
import 'package:gemnest_mobile_app/services/tax_service_charge_service.dart';
import 'package:gemnest_mobile_app/splash_screen.dart';
import 'package:gemnest_mobile_app/stripe_service.dart';
import 'package:gemnest_mobile_app/stripe_service_direct.dart';
import 'package:gemnest_mobile_app/theme/app_theme.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Warning: Could not load .env file: $e');
    // Set fallback values so the app can still run
  }

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Register background message handler BEFORE runApp
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

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

    // Initialize tax & service charge config from Firebase
    await TaxServiceChargeService().loadConfig();

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
    debugPrint('Signed in anonymously with UID: ${userCredential.user?.uid}');
  } on FirebaseAuthException catch (e) {
    debugPrint('Failed to sign in anonymously: ${e.message}');
    rethrow;
  } catch (e) {
    debugPrint('Unexpected error during anonymous sign-in: $e');
    rethrow;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'GemNest Mobile App',
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
