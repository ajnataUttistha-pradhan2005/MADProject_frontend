// import 'package:flutter/material.dart';
// import 'package:mathsolver/pages/sign_in_page.dart';
// import 'package:mathsolver/services/auth_service.dart';

// class SignUpPage extends StatefulWidget {
//   const SignUpPage({super.key});

//   @override
//   State<SignUpPage> createState() => _SignUpPageState();
// }

// class _SignUpPageState extends State<SignUpPage> with TickerProviderStateMixin {
//   final _usernameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _confirmPasswordController = TextEditingController();

//   bool _loading = false;
//   String? _error;

//   bool _obscurePassword = true;
//   bool _obscureConfirmPassword = true;

//   late AnimationController _gradientController;

//   int _focusedFieldIndex = -1;

//   @override
//   void initState() {
//     super.initState();
//     _gradientController = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 3),
//     )..repeat();
//   }

//   @override
//   void dispose() {
//     _gradientController.dispose();
//     _usernameController.dispose();
//     _emailController.dispose();
//     _passwordController.dispose();
//     _confirmPasswordController.dispose();
//     super.dispose();
//   }

//   void _signUp() async {
//     setState(() {
//       _loading = true;
//       _error = null;
//     });

//     final result = await AuthService.signUp(
//       _usernameController.text.trim(),
//       _emailController.text.trim(),
//       _passwordController.text,
//       _confirmPasswordController.text,
//     );

//     setState(() => _loading = false);

//     if (result['message'] == 'User registered successfully!') {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Sign-up successful. Please Sign in.")),
//       );
//       Navigator.pop(context);
//     } else {
//       setState(() {
//         _error = result['message'] ?? "Sign up failed.";
//       });
//     }
//   }

//   InputDecoration _inputDecoration(
//     String label,
//     bool focused, {
//     Widget? suffixIcon,
//   }) {
//     return InputDecoration(
//       labelText: label,
//       labelStyle: TextStyle(
//         color: focused ? Colors.white : Colors.white70,
//         fontWeight: FontWeight.w600,
//       ),
//       filled: true,
//       fillColor: const Color(0xFF1F1F1F),
//       contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
//       enabledBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(16),
//         borderSide: const BorderSide(color: Colors.transparent),
//       ),
//       focusedBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(16),
//         borderSide: const BorderSide(
//           color: Color.fromARGB(255, 49, 16, 239),
//           width: 2,
//         ),
//       ),
//       suffixIcon: suffixIcon,
//     );
//   }

//   Widget _buildTextField({
//     required TextEditingController controller,
//     required String label,
//     required int index,
//     bool obscureText = false,
//     TextInputType? keyboardType,
//     Widget? suffixIcon,
//   }) {
//     return Focus(
//       onFocusChange: (hasFocus) {
//         setState(() {
//           _focusedFieldIndex = hasFocus ? index : -1;
//         });
//       },
//       child: TextField(
//         controller: controller,
//         obscureText: obscureText,
//         keyboardType: keyboardType,
//         style: const TextStyle(color: Colors.white),
//         cursorColor: Color.fromARGB(255, 16, 87, 239),
//         decoration: _inputDecoration(
//           label,
//           _focusedFieldIndex == index,
//           suffixIcon: suffixIcon,
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Center(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Image.asset(
//                 'assets/icons/solveBaseLogo.png', // your logo path
//                 width: 150,
//                 height: 150,
//                 fit: BoxFit.contain,
//               ),
//               const SizedBox(height: 25),
//               const Text(
//                 'Create Account',
//                 style: TextStyle(
//                   fontSize: 34,
//                   fontWeight: FontWeight.w900,
//                   color: Colors.white,
//                   letterSpacing: 1.4,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               const Text(
//                 'Join SolveBase and start your journey!',
//                 style: TextStyle(color: Colors.white54, fontSize: 15),
//               ),
//               const SizedBox(height: 30),
//               _buildTextField(
//                 controller: _usernameController,
//                 label: 'Username',
//                 index: 0,
//               ),
//               const SizedBox(height: 20),
//               _buildTextField(
//                 controller: _emailController,
//                 label: 'Email',
//                 index: 1,
//                 keyboardType: TextInputType.emailAddress,
//               ),
//               const SizedBox(height: 20),
//               _buildTextField(
//                 controller: _passwordController,
//                 label: 'Password',
//                 index: 2,
//                 obscureText: _obscurePassword,
//                 suffixIcon: IconButton(
//                   icon: Icon(
//                     _obscurePassword ? Icons.visibility_off : Icons.visibility,
//                     color: Colors.white70,
//                   ),
//                   onPressed:
//                       () => setState(() {
//                         _obscurePassword = !_obscurePassword;
//                       }),
//                 ),
//               ),
//               const SizedBox(height: 20),
//               _buildTextField(
//                 controller: _confirmPasswordController,
//                 label: 'Confirm Password',
//                 index: 3,
//                 obscureText: _obscureConfirmPassword,
//                 suffixIcon: IconButton(
//                   icon: Icon(
//                     _obscureConfirmPassword
//                         ? Icons.visibility_off
//                         : Icons.visibility,
//                     color: Colors.white70,
//                   ),
//                   onPressed:
//                       () => setState(() {
//                         _obscureConfirmPassword = !_obscureConfirmPassword;
//                       }),
//                 ),
//               ),
//               if (_error != null) ...[
//                 const SizedBox(height: 15),
//                 Text(
//                   _error!,
//                   style: const TextStyle(color: Colors.redAccent, fontSize: 14),
//                 ),
//               ],
//               const SizedBox(height: 36),
//               GestureDetector(
//                 onTap: _loading ? null : _signUp,
//                 child: AnimatedBuilder(
//                   animation: _gradientController,
//                   builder: (context, child) {
//                     return Opacity(
//                       opacity: _loading ? 0.7 : 1.0,
//                       child: Container(
//                         width: double.infinity,
//                         padding: const EdgeInsets.symmetric(vertical: 18),
//                         decoration: BoxDecoration(
//                           gradient: LinearGradient(
//                             colors: const [
//                               Color(0xFFED1D20),
//                               Color(0xFFBA1A73),
//                               Color(0xFFA0199D),
//                               Color(0xFF2B41D4),
//                             ],
//                             stops: [
//                               (_gradientController.value - 0.3).clamp(0.0, 1.0),
//                               (_gradientController.value - 0.1).clamp(0.0, 1.0),
//                               (_gradientController.value + 0.1).clamp(0.0, 1.0),
//                               (_gradientController.value + 0.3).clamp(0.0, 1.0),
//                             ],
//                             begin: Alignment.topLeft,
//                             end: Alignment.bottomRight,
//                           ),
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                         child: Center(
//                           child:
//                               _loading
//                                   ? const SizedBox(
//                                     height: 24,
//                                     width: 24,
//                                     child: CircularProgressIndicator(
//                                       strokeWidth: 3,
//                                       valueColor: AlwaysStoppedAnimation<Color>(
//                                         Colors.white,
//                                       ),
//                                     ),
//                                   )
//                                   : const Text(
//                                     'SIGN UP',
//                                     style: TextStyle(
//                                       color: Colors.white,
//                                       fontSize: 18,
//                                       fontWeight: FontWeight.bold,
//                                       letterSpacing: 2.5,
//                                     ),
//                                   ),
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//               const SizedBox(height: 20),
//               TextButton(
//                 onPressed: () {
//                   Navigator.pushReplacement(
//                     context,
//                     MaterialPageRoute(builder: (_) => const SignInPage()),
//                   );
//                 },
//                 child: const Text(
//                   'Already have an account? Sign in',
//                   style: TextStyle(
//                     color: Colors.white70,
//                     fontWeight: FontWeight.w600,
//                     decoration: TextDecoration.underline,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:mathsolver/pages/sign_in_page.dart';
import 'package:mathsolver/services/auth_service.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  bool _loading = false;
  String? _error;

  void _signUp() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await AuthService.signUp(
      _usernameController.text,
      _emailController.text,
      _passwordController.text,
      _confirmPasswordController.text,
    );

    setState(() => _loading = false);

    if (result['message'] == 'User registered successfully!') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sign-up successful. Please log in.")),
      );
      Navigator.pop(context); // Return to sign-in screen
    } else {
      setState(() {
        _error = result['message'] ?? "Sign up failed.";
      });
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Sign Up",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 30),

              // Username
              TextField(
                controller: _usernameController,
                decoration: _inputDecoration("Username"),
                style: const TextStyle(color: Colors.black87),
              ),
              const SizedBox(height: 16),

              // Email
              TextField(
                controller: _emailController,
                decoration: _inputDecoration("Email"),
                style: const TextStyle(color: Colors.black87),
              ),
              const SizedBox(height: 16),

              // Password
              TextField(
                controller: _passwordController,
                obscureText: !_passwordVisible,
                decoration: _inputDecoration("Password").copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _passwordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _passwordVisible = !_passwordVisible;
                      });
                    },
                  ),
                ),
                style: const TextStyle(color: Colors.black87),
              ),

              const SizedBox(height: 16),

              // Confirm Password
              TextField(
                controller: _confirmPasswordController,
                obscureText: !_confirmPasswordVisible,
                decoration: _inputDecoration("Confirm Password").copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _confirmPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _confirmPasswordVisible = !_confirmPasswordVisible;
                      });
                    },
                  ),
                ),
                style: const TextStyle(color: Colors.black87),
              ),

              // Error
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],

              const SizedBox(height: 24),

              // Sign Up Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _signUp,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      _loading
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : const Text("Sign Up"),
                ),
              ),

              const SizedBox(height: 16),

              // Highlighted Sign In link
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SignInPage()),
                  );
                },
                child: RichText(
                  text: const TextSpan(
                    text: "Already have an account? ",
                    style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                    children: [
                      TextSpan(
                        text: "Sign in",
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
