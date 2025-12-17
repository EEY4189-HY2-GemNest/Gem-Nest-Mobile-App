



























































    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      _showCustomDialog(
        title: 'Error',
        message: 'Please fill in all fields',
        isError: true,
      );
      return;
    }

    