import 'package:flutter/material.dart';
import 'package:mathsolver/globals.dart';
import 'package:mathsolver/services/auth_service.dart';
import 'package:mathsolver/pages/home_page.dart';
import 'package:mathsolver/pages/sign_up_page.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  String? _error;

  bool _obscurePassword = true;

  late AnimationController _gradientController;

  int _focusedFieldIndex = -1;

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _signIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await AuthService.signIn(
      _emailController.text.trim(),
      _passwordController.text,
    );

    setState(() => _loading = false);

    if (result['token'] != null) {
      Globals.token = result['token'];
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else {
      setState(() {
        _error = result['message'] ?? "Sign in failed.";
      });
    }
  }

  InputDecoration _inputDecoration(
    String label,
    bool focused, {
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: focused ? Colors.white : Colors.white70,
        fontWeight: FontWeight.w600,
      ),
      filled: true,
      fillColor: const Color(0xFF1F1F1F),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.transparent),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color.fromARGB(255, 49, 16, 239),
          width: 2,
        ),
      ),
      suffixIcon: suffixIcon,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required int index,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return Focus(
      onFocusChange: (hasFocus) {
        setState(() {
          _focusedFieldIndex = hasFocus ? index : -1;
        });
      },
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        cursorColor: const Color.fromARGB(255, 16, 87, 239),
        decoration: _inputDecoration(
          label,
          _focusedFieldIndex == index,
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20), // Push a bit from top
              Image.asset(
                'assets/icons/solveBaseLogo.png', // same logo as SignUpPage
                width: 150,
                height: 150,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 25),
              const Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign in to continue solving problems!',
                style: TextStyle(color: Colors.white54, fontSize: 15),
              ),
              const SizedBox(height: 30),
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                index: 0,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _passwordController,
                label: 'Password',
                index: 1,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white70,
                  ),
                  onPressed:
                      () => setState(() {
                        _obscurePassword = !_obscurePassword;
                      }),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 15),
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                ),
              ],
              const SizedBox(height: 36),
              GestureDetector(
                onTap: _loading ? null : _signIn,
                child: AnimatedBuilder(
                  animation: _gradientController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _loading ? 0.7 : 1.0,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: const [
                              Color(0xFFED1D20),
                              Color(0xFFBA1A73),
                              Color(0xFFA0199D),
                              Color(0xFF2B41D4),
                            ],
                            stops: [
                              (_gradientController.value - 0.3).clamp(0.0, 1.0),
                              (_gradientController.value - 0.1).clamp(0.0, 1.0),
                              (_gradientController.value + 0.1).clamp(0.0, 1.0),
                              (_gradientController.value + 0.3).clamp(0.0, 1.0),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child:
                              _loading
                                  ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                  : const Text(
                                    'SIGN IN',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2.5,
                                    ),
                                  ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const SignUpPage()),
                  );
                },
                child: const Text(
                  "Don't have an account? Sign up",
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
