# Environment Variables Setup Guide

## Overview
Your project now uses environment variables for secure credential management. This prevents accidental exposure of API keys in version control.

## File Structure

### Flutter App (Root Directory)
- **.env** - Your actual environment variables (DO NOT COMMIT - in .gitignore)
- **.env.example** - Template file for documentation (safe to commit)

### Firebase Cloud Functions (functions/)
- **functions/.env.local** - Your actual environment variables (DO NOT COMMIT - in .gitignore)
- **functions/.env.example** - Template file for documentation (safe to commit)

## Setup Instructions

### 1. Update Flutter .env File

Copy `.env.example` to `.env` and add your actual Stripe publishable key:

```bash
cp .env.example .env
```

Edit `.env`:
```env
STRIPE_PUBLISHABLE_KEY=pk_live_YOUR_ACTUAL_KEY_HERE
BACKEND_URL=https://stripewebhook-tvrnolinbq-uc.a.run.app
```

### 2. Update Firebase Cloud Functions .env.local

The file already exists at `functions/.env.local` with your keys configured via Firebase CLI.

To manually update if needed:
```bash
cd functions
cp .env.example .env.local
# Edit .env.local with your actual keys
```

### 3. Initialize Flutter Dotenv in main.dart

Your `main.dart` needs to load the .env file before running the app:

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  // Load environment variables from .env file
  await dotenv.load(fileName: ".env");
  
  // Initialize Stripe
  await StripeService.initialize();
  
  runApp(const MyApp());
}
```

### 4. Install Dependencies

After updating pubspec.yaml, run:

```bash
flutter pub get
```

## Environment Variables Reference

### STRIPE_PUBLISHABLE_KEY
- **Location**: `.env` (Flutter)
- **Type**: Public key (safe to expose)
- **Value**: Starts with `pk_test_` or `pk_live_`
- **Source**: https://dashboard.stripe.com/apikeys

### STRIPE_SECRET_KEY (Backend Only)
- **Location**: `functions/.env.local` (Firebase Cloud Functions)
- **Type**: Secret key (NEVER expose)
- **Value**: Starts with `sk_test_` or `sk_live_`
- **Source**: https://dashboard.stripe.com/apikeys
- **Protection**: Stored securely in Firebase, not committed to Git

### STRIPE_WEBHOOK_SECRET (Backend Only)
- **Location**: `functions/.env.local` (Firebase Cloud Functions)
- **Type**: Secret key (NEVER expose)
- **Value**: Starts with `whsec_`
- **Source**: https://dashboard.stripe.com/webhooks
- **Protection**: Stored securely in Firebase, not committed to Git

### BACKEND_URL
- **Location**: `.env` (Flutter)
- **Type**: Public URL
- **Value**: Firebase Cloud Functions URL or your backend server
- **Example**: `https://stripewebhook-tvrnolinbq-uc.a.run.app`

## Security Best Practices

✅ **Do:**
- Keep `.env` and `functions/.env.local` in `.gitignore`
- Commit `.env.example` and `functions/.env.example` (templates only)
- Use different keys for development (test_) and production (live_)
- Rotate keys if accidentally exposed

❌ **Don't:**
- Commit actual `.env` or `.env.local` files
- Share API keys via email, chat, or version control
- Use production keys in development/testing
- Hardcode keys directly in source code

## Testing Sandbox Payments

Before going live with production keys:

1. Get test keys from Stripe Dashboard (marked as "Test key")
2. Update `.env` with test publishable key: `pk_test_...`
3. Use test card numbers:
   - **Visa**: 4242 4242 4242 4242
   - **Mastercard**: 5555 5555 5555 4444
   - **Expiry**: Any future date
   - **CVC**: Any 3 digits

## Current Configuration Status

✅ **Flutter App (.env)**
- STRIPE_PUBLISHABLE_KEY: Ready to configure
- BACKEND_URL: Pre-filled with Cloud Functions URL

✅ **Firebase Cloud Functions (functions/.env.local)**
- STRIPE_SECRET_KEY: Configured via Firebase CLI
- STRIPE_WEBHOOK_SECRET: Configured via Firebase CLI

✅ **Version Control Protection**
- `.env` excluded in `.gitignore` ✓
- `.env.local` excluded in `functions/.gitignore` ✓
- `.env.example` files safe to commit ✓

## Troubleshooting

### "STRIPE_PUBLISHABLE_KEY not found"
- Ensure `.env` file exists in project root
- Verify `dotenv.load()` is called in `main()` before `StripeService.initialize()`
- Check that the variable name matches exactly (case-sensitive)

### "BACKEND_URL not found"
- Add `BACKEND_URL` to your `.env` file
- Verify Firebase Cloud Functions URL is correct

### "packages/flutter_dotenv not found"
- Run `flutter pub get` to install dependencies
- Ensure `flutter_dotenv: ^5.1.0` is in `pubspec.yaml`

## Next Steps

1. Update your `.env` file with actual Stripe publishable key
2. Run `flutter pub get` to install `flutter_dotenv`
3. Ensure `main.dart` calls `dotenv.load()` before `StripeService.initialize()`
4. Test that environment variables load correctly
5. Deploy to production with production keys when ready
