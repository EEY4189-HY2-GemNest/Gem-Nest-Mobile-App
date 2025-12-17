






















  bool isLoading = false; 














































    setState(() => isLoading = true);

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      String? userId = userCredential.user?.uid;

      DocumentSnapshot buyerSnapshot = await _firestore
          .collection('buyers')
          .doc(userId)
          .get();
      DocumentSnapshot sellerSnapshot = await _firestore
          .collection('sellers')
          .doc(userId)
          .get();

      if (buyerSnapshot.exists) {
        await _saveCredentials();
        _navigateTo(const HomeScreen());
      } else if (sellerSnapshot.exists) {
        Map<String, dynamic> sellerData =
            sellerSnapshot.data() as Map<String, dynamic>;
        if (!sellerData['isActive']) {
          await _auth.signOut();
          _showCustomDialog(
            title: 'Account Disabled',
            message:
                'Your seller account is disabled. Please wait for Admin approval.',
            isError: true,
          );
        } else {
          await _saveCredentials();
          _navigateTo(const SellerHomePage());
        }
      } else {
        throw Exception('User role not found.');
      }
    } on FirebaseAuthException catch (e) {
      _showCustomDialog(
        title: 'Login Failed',
        message: e.message ?? 'Login failed. Please try again.',
        isError: true,
      );
    } catch (e) {
      _showCustomDialog(title: 'Error', message: 'Error: $e', isError: true);
    } finally {
      setState(() => isLoading = false);
    }
  