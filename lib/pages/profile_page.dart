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

class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin {
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  bool _isEditing = false;
  bool _isLoggingOut = false;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  late final AnimationController _logoutAnimController;
  late final Animation<double> _logoutFadeAnim;
  late final Animation<double> _logoutScaleAnim;

  late final AnimationController _gradientController;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: Globals.username ?? '');
    _emailController = TextEditingController(text: Globals.email ?? '');

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();

    _logoutAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _logoutFadeAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _logoutAnimController, curve: Curves.easeInOut),
    );
    _logoutScaleAnim = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _logoutAnimController, curve: Curves.easeInOut),
    );

    _gradientController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _logoutAnimController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _gradientController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<void> _submitChanges() async {
    setState(() => _isLoading = true);
    bool success = await ProfileService.editProfile(
      userId: Globals.userId!,
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      imageFile: _selectedImage,
    );
    setState(() => _isLoading = false);

    if (success) {
      Globals.username = _usernameController.text.trim();
      Globals.email = _emailController.text.trim();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Profile updated successfully!')),
      );
      setState(() => _isEditing = false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Failed to update profile.')),
      );
    }
  }

  Future<void> _handleLogout() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);

    await _logoutAnimController.forward();

    AuthService.signout();

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => const SignInPage(),
        transitionsBuilder:
            (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final baseTextStyle = const TextStyle(
      color: Colors.white70,
      fontFamily: 'LexendDeca',
      fontWeight: FontWeight.w600,
    );

    const twitterBlue = Color(0xFF1DA1F2);

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _logoutAnimController,
          builder: (context, child) {
            return Opacity(
              opacity: _logoutFadeAnim.value,
              child: Transform.scale(
                scale: _logoutScaleAnim.value,
                child: FadeTransition(opacity: _fadeAnimation, child: child),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    BackButton(color: Colors.white),
                    const Spacer(),
                    ShaderMask(
                      shaderCallback:
                          (bounds) => const LinearGradient(
                            colors: [
                              Color.fromARGB(255, 141, 141, 144),
                              Colors.white,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                      child: Text(
                        'PROFILE',
                        style: baseTextStyle.copyWith(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        _isEditing
                            ? Icons.check_circle_outline
                            : Icons.edit_outlined,
                        color: twitterBlue,
                      ),
                      onPressed: () => setState(() => _isEditing = !_isEditing),
                      tooltip: _isEditing ? 'Save' : 'Edit',
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                Center(
                  child: GestureDetector(
                    onTap: _isEditing ? _pickImage : null,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      transitionBuilder:
                          (child, anim) =>
                              ScaleTransition(scale: anim, child: child),
                      child:
                          _selectedImage != null
                              ? CircleAvatar(
                                key: const ValueKey('file'),
                                radius: 58,
                                backgroundImage: FileImage(_selectedImage!),
                              )
                              : GradientAvatar(
                                key: const ValueKey('gradient'),
                                imagePath: Globals.profileImg ?? '',
                                isAsset: Globals.profileImg == null,
                                size: 116,
                                borderWidth: 3,
                              ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    _isEditing ? 'Tap image to change' : '',
                    style: baseTextStyle.copyWith(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildEditableField(
                        "Username",
                        _usernameController,
                        _isEditing,
                      ),
                      _buildEditableField(
                        "Email",
                        _emailController,
                        _isEditing,
                      ),
                      const SizedBox(height: 22),
                      if (_isEditing)
                        _isLoading
                            ? const Center(
                              child: CircularProgressIndicator(strokeWidth: 3),
                            )
                            : Center(
                              child: ElevatedButton.icon(
                                onPressed: _submitChanges,
                                icon: const Icon(
                                  Icons.save_alt_rounded,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  'SAVE CHANGES',
                                  style: baseTextStyle.copyWith(
                                    color: Colors.white,
                                    fontSize: 16,
                                    letterSpacing: 1.2,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: twitterBlue,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 36,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                ),
                              ),
                            ),
                      const SizedBox(height: 20),
                      Center(
                        child: GestureDetector(
                          onTap: _handleLogout,
                          child: AnimatedBuilder(
                            animation: _gradientController,
                            builder: (context, child) {
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                                margin: const EdgeInsets.only(top: 10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFFED1D20),
                                      Color(0xFFBA1A73),
                                      Color(0xFFA0199D),
                                      Color(0xFF2B41D4),
                                    ],
                                    stops: [
                                      (_gradientController.value - 0.3).clamp(
                                        0.0,
                                        1.0,
                                      ),
                                      (_gradientController.value - 0.1).clamp(
                                        0.0,
                                        1.0,
                                      ),
                                      (_gradientController.value + 0.1).clamp(
                                        0.0,
                                        1.0,
                                      ),
                                      (_gradientController.value + 0.3).clamp(
                                        0.0,
                                        1.0,
                                      ),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Center(
                                  child: Text(
                                    _isLoggingOut ? 'LOGGING OUT...' : 'LOGOUT',
                                    style: baseTextStyle.copyWith(
                                      color: Colors.white,
                                      fontSize: 18,
                                      letterSpacing: 2.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditableField(
    String label,
    TextEditingController controller,
    bool enabled,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        enabled: enabled,
        controller: controller,
        style: const TextStyle(color: Colors.white70, fontSize: 17),
        decoration: InputDecoration(
          labelText: label.toUpperCase(),
          labelStyle: const TextStyle(
            color: Colors.grey,
            letterSpacing: 1.3,
            fontWeight: FontWeight.w600,
          ),
          fillColor: const Color(0xFF1E1E1E),
          filled: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 14,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.white24),
          ),
        ),
        keyboardType:
            label == "Email" ? TextInputType.emailAddress : TextInputType.text,
      ),
    );
  }
}
