import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:gemnest_mobile_app/screen/auth_screens/login_screen.dart';
import 'package:gemnest_mobile_app/widget/custom_dialog.dart'; // Import the new dialog
import 'package:image_picker/image_picker.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool isBuyer = true;
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;

  final TextEditingController displayNameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController nicController = TextEditingController();
  final TextEditingController businessNameController = TextEditingController();
  final TextEditingController brNumberController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();

  // File upload state variables
  File? _businessRegistrationFile;
  File? _nicFile;
  String? _businessRegistrationFileName;
  String? _nicFileName;
  bool _isUploadingBusinessReg = false;
  bool _isUploadingNic = false;

  // Method to upload file to Firebase Storage
  Future<String?> _uploadFile(File file, String folder, String userId) async {
    try {
      String fileName =
          '${userId}_${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      Reference storageRef = _storage.ref().child('$folder/$fileName');
      UploadTask uploadTask = storageRef.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }

  // Method to pick business registration document
  Future<void> _pickBusinessRegistrationFile() async {
    try {
      setState(() => _isUploadingBusinessReg = true);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.business, color: Colors.blue, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Business Registration',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Please upload your business registration document:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              _buildUploadOption(
                icon: Icons.camera_alt,
                title: 'Take Photo',
                subtitle: 'Use camera to capture document',
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image =
                      await _imagePicker.pickImage(source: ImageSource.camera);
                  if (image != null) {
                    setState(() {
                      _businessRegistrationFile = File(image.path);
                      _businessRegistrationFileName = image.name;
                    });
                  }
                },
              ),
              const SizedBox(height: 8),
              _buildUploadOption(
                icon: Icons.photo_library,
                title: 'Choose from Gallery',
                subtitle: 'Select from your photos',
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image =
                      await _imagePicker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    setState(() {
                      _businessRegistrationFile = File(image.path);
                      _businessRegistrationFileName = image.name;
                    });
                  }
                },
              ),
              const SizedBox(height: 8),
              _buildUploadOption(
                icon: Icons.attach_file,
                title: 'Choose File',
                subtitle: 'Select PDF or image file',
                onTap: () async {
                  Navigator.pop(context);
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                  );
                  if (result != null && result.files.single.path != null) {
                    setState(() {
                      _businessRegistrationFile =
                          File(result.files.single.path!);
                      _businessRegistrationFileName = result.files.single.name;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    } finally {
      setState(() => _isUploadingBusinessReg = false);
    }
  }

  // Method to pick NIC document
  Future<void> _pickNicFile() async {
    try {
      setState(() => _isUploadingNic = true);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.credit_card, color: Colors.blue, size: 24),
              const SizedBox(width: 8),
              const Text(
                'NIC Document',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Please upload your National Identity Card:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              _buildUploadOption(
                icon: Icons.camera_alt,
                title: 'Take Photo',
                subtitle: 'Use camera to capture NIC',
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image =
                      await _imagePicker.pickImage(source: ImageSource.camera);
                  if (image != null) {
                    setState(() {
                      _nicFile = File(image.path);
                      _nicFileName = image.name;
                    });
                  }
                },
              ),
              const SizedBox(height: 8),
              _buildUploadOption(
                icon: Icons.photo_library,
                title: 'Choose from Gallery',
                subtitle: 'Select from your photos',
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image =
                      await _imagePicker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    setState(() {
                      _nicFile = File(image.path);
                      _nicFileName = image.name;
                    });
                  }
                },
              ),
              const SizedBox(height: 8),
              _buildUploadOption(
                icon: Icons.attach_file,
                title: 'Choose File',
                subtitle: 'Select PDF or image file',
                onTap: () async {
                  Navigator.pop(context);
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                  );
                  if (result != null && result.files.single.path != null) {
                    setState(() {
                      _nicFile = File(result.files.single.path!);
                      _nicFileName = result.files.single.name;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    } finally {
      setState(() => _isUploadingNic = false);
    }
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;

    if (passwordController.text != confirmPasswordController.text) {
      _showCustomDialog(
        title: 'Error',
        message: 'Passwords do not match!',
        isError: true,
      );
      return;
    }

    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      String userId = userCredential.user?.uid ?? '';
      if (userId.isEmpty) {
        throw Exception("Failed to retrieve user ID after sign-up");
      }

      Map<String, dynamic> userData = {
        'firebaseUid': userId,
        'email': emailController.text.trim(),
        'phoneNumber': phoneNumberController.text.trim(),
        'role': isBuyer ? 'buyer' : 'seller',
        'isActive': isBuyer ? true : false,
      };

      if (!isBuyer) {
        // Upload files first
        String? businessRegUrl;
        String? nicUrl;

        if (_businessRegistrationFile != null) {
          businessRegUrl = await _uploadFile(
              _businessRegistrationFile!, 'business_registrations', userId);
        }

        if (_nicFile != null) {
          nicUrl = await _uploadFile(_nicFile!, 'nic_documents', userId);
        }

        userData.addAll({
          'displayName': displayNameController.text.trim(),
          'address': addressController.text.trim(),
          'nicNumber': nicController.text.trim(),
          'businessName': businessNameController.text.trim(),
          'brNumber': brNumberController.text.trim(),
          'businessRegistrationUrl': businessRegUrl,
          'nicDocumentUrl': nicUrl,
        });
      }

      final String collectionName = isBuyer ? 'buyers' : 'sellers';
      await _firestore.collection(collectionName).doc(userId).set(userData);

      if (!isBuyer) {
        _showActivationDialog();
      } else {
        _showCustomDialog(
          title: 'Success',
          message: 'User registered successfully!',
          onConfirm: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          ),
        );
      }
    } catch (e) {
      _showCustomDialog(
        title: 'Error',
        message: 'Error: $e',
        isError: true,
      );
    }
  }

  void _showActivationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return CustomDialog(
          title: 'Account Created',
          message:
              'Your seller account has been created successfully but is currently not verified. The Admin will review your submitted documents and enable your account. You will be notified once verification is complete.',
          onConfirm: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          ),
        );
      },
    );
  }

  void _showCustomDialog({
    required String title,
    required String message,
    VoidCallback? onConfirm,
    bool isError = false,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomDialog(
          title: title,
          message: message,
          onConfirm: onConfirm,
          isError: isError,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset('assets/images/gemnest.png', height: 90),
                const SizedBox(height: 20),
                const Text(
                  'Create an Account',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                _roleSelector(),
                if (!isBuyer) _customTextField('Name', displayNameController),
                if (!isBuyer) _customTextField('Address', addressController),
                if (!isBuyer) _customTextField('NIC Number', nicController),
                if (!isBuyer)
                  _customTextField('Business Name', businessNameController),
                if (!isBuyer) _customTextField('BR Number', brNumberController),
                if (!isBuyer)
                  _buildFileUploadSection(
                      'Business Registration',
                      _businessRegistrationFileName,
                      _isUploadingBusinessReg,
                      _pickBusinessRegistrationFile),
                if (!isBuyer)
                  _buildFileUploadSection('NIC Document', _nicFileName,
                      _isUploadingNic, _pickNicFile),
                _customTextField('Email', emailController),
                _customTextField('Phone Number', phoneNumberController,
                    keyboardType: TextInputType.phone),
                _customTextField('Password', passwordController,
                    isPassword: true),
                _customTextField('Confirm Password', confirmPasswordController,
                    isPassword: true),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saveUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Register',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 20),
                // Already have account? Login section
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          // decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleSelector() {
    return ToggleButtons(
      isSelected: [isBuyer, !isBuyer],
      onPressed: (index) => setState(() => isBuyer = index == 0),
      borderRadius: BorderRadius.circular(12),
      selectedColor: Colors.white,
      fillColor: Colors.blue,
      color: Colors.black,
      borderWidth: 2,
      children: const [
        Padding(
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
            child: Text('Buyer')),
        Padding(
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
            child: Text('Seller')),
      ],
    );
  }

  Widget _buildUploadOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                color: Colors.blue,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileUploadSection(
      String label, String? fileName, bool isUploading, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: isUploading ? null : onTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: isUploading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Uploading...'),
                      ],
                    )
                  : Row(
                      children: [
                        Icon(
                          fileName != null
                              ? Icons.check_circle
                              : Icons.upload_file,
                          color: fileName != null ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            fileName ?? 'Upload $label (PDF/Image)',
                            style: TextStyle(
                              color: fileName != null
                                  ? Colors.green
                                  : Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Icon(Icons.camera_alt, color: Colors.grey.shade600),
                      ],
                    ),
            ),
          ),
          if (fileName != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'File uploaded: $fileName',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green.shade600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _customTextField(String label, TextEditingController controller,
      {bool isPassword = false,
      TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword
            ? (label == 'Password'
                ? !isPasswordVisible
                : !isConfirmPasswordVisible)
            : false,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon((label == 'Password'
                          ? isPasswordVisible
                          : isConfirmPasswordVisible)
                      ? Icons.visibility
                      : Icons.visibility_off),
                  onPressed: () => setState(() {
                    if (label == 'Password') {
                      isPasswordVisible = !isPasswordVisible;
                    } else {
                      isConfirmPasswordVisible = !isConfirmPasswordVisible;
                    }
                  }),
                )
              : null,
        ),
        validator: (value) =>
            value == null || value.isEmpty ? "This field is required" : null,
      ),
    );
  }

  @override
  void dispose() {
    displayNameController.dispose();
    addressController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    emailController.dispose();
    phoneNumberController.dispose();
    nicController.dispose();
    businessNameController.dispose();
    brNumberController.dispose();
    super.dispose();
  }
}
