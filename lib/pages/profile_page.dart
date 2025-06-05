import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mathsolver/components/gradient_Avatar.dart';
import 'package:mathsolver/globals.dart';
import 'package:mathsolver/pages/sign_in_page.dart';
import 'package:mathsolver/services/auth_service.dart';
import 'package:mathsolver/services/profile_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: Globals.username ?? '');
    _emailController = TextEditingController(text: Globals.email ?? '');
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  Future<void> _submitChanges() async {
    setState(() {
      _isLoading = true;
    });

    bool success = await ProfileService.editProfile(
      userId: Globals.userId!,
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      imageFile: _selectedImage,
    );

    setState(() {
      _isLoading = false;
    });

    if (success) {
      // Update global vars (you might want to reload from backend ideally)
      Globals.username = _usernameController.text.trim();
      Globals.email = _emailController.text.trim();

      // Show success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontFamily: "LexendDeca",
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Center(
                child:
                    _selectedImage != null
                        ? CircleAvatar(
                          radius: 60,
                          backgroundImage: FileImage(_selectedImage!),
                        )
                        : GradientAvatar(
                          imagePath:
                              Globals.profileImg ??
                              'assets/icons/profileImg.jpeg',
                          isAsset: Globals.profileImg == null,
                          size: 120,
                          borderWidth: 3,
                        ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Tap image to change',
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
            const SizedBox(height: 30),

            // Editable Username
            _buildEditableField("Name", _usernameController),

            // Editable Email
            _buildEditableField("Email", _emailController),

            const SizedBox(height: 40),

            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                  onPressed: _submitChanges,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 40,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    backgroundColor: Colors.blueAccent,
                  ),
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),

            const SizedBox(height: 40),

            // Logout Button
            GestureDetector(
              onTap: () {
                AuthService.signout();

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const SignInPage()),
                  (route) => false,
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFED1D20),
                      Color(0xFFBA1A73),
                      Color(0xFFA0199D),
                      Color(0xFF2B41D4),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'LOGOUT',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontFamily: "LexendDeca",
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          filled: true,
          fillColor: const Color(0xFF1C1C1E),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
        keyboardType:
            label == "Email" ? TextInputType.emailAddress : TextInputType.text,
      ),
    );
  }
}
