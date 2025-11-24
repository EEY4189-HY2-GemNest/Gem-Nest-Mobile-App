

  late AnimationController _controller;
  late Animation<double> _animation;
  File? _image;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _titleController.dispose();
    _currentBidController.dispose();
    _minimumIncrementController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_image != null) {
      String fileName =
          'auction_images/${DateTime.now().millisecondsSinceEpoch}_${_image!.path.split('/').last}';
      UploadTask uploadTask = _storage.ref(fileName).putFile(_image!);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    }
    return null;
  }

      body: SafeArea(
        child: FadeTransition(
          opacity: _animation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [

                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.grey[900]!, Colors.grey[800]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blue, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _image != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.file(_image!, fit: BoxFit.cover),
                            )
                          : const Center(
                              child: Icon(Icons.camera_alt,
                                  color: Colors.white, size: 40),
                            ),
                    ),
                  ),

                ],
              ),
            ),
          ),
        ),
      ),
    
  

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required String? Function(String?) validator,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[900],
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white54, fontSize: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
          ),
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          validator: validator,
        ),
      ],
    );
  }

