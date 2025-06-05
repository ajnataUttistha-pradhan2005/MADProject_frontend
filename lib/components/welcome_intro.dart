// import 'package:flutter/material.dart';
// import 'package:shimmer/shimmer.dart';

// class WelcomeIntro extends StatelessWidget {
//   const WelcomeIntro({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         const SizedBox(height: 100),
//         // Welcome Text inside a Container with centered text alignment
//         Container(
//           padding: const EdgeInsets.all(
//             16.0,
//           ), // Padding for spacing around the text
//           child: Text(
//             "Welcome To Math Solver App",
//             textAlign: TextAlign.center, // Center the text
//             style: TextStyle(
//               color: Color(0xB5C2C7D9),
//               fontSize: 36,
//               fontWeight: FontWeight.w800,
//             ),
//           ),
//         ),

//         const SizedBox(height: 100),

//         // Shimmer effect with centered and paragraph-aligned text
//         Shimmer.fromColors(
//           baseColor: const Color.fromARGB(148, 46, 35, 197),
//           highlightColor: const Color.fromARGB(191, 219, 11, 21),
//           child: Container(
//             padding: const EdgeInsets.all(
//               16.0,
//             ), // Padding for spacing around the text
//             child: Text(
//               'Quick, smart, and reliable math solutions at your fingertips. Let’s solve it together!',
//               textAlign: TextAlign.center, // Center the text
//               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Custom shimmer text widget
class ShimmerText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Color baseColor;
  final Color highlightColor;
  final TextAlign textAlign;

  const ShimmerText({
    super.key,
    required this.text,
    required this.style,
    this.baseColor = const Color(0xFF3C3C3C),
    this.highlightColor = const Color(0xFFE91E63),
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Text(text, textAlign: textAlign, style: style),
    );
  }
}

/// Final welcome intro with animated entrance
class WelcomeIntro extends StatefulWidget {
  const WelcomeIntro({super.key});

  @override
  State<WelcomeIntro> createState() => _WelcomeIntroState();
}

class _WelcomeIntroState extends State<WelcomeIntro>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    // Start animation after layout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      color: Colors.black,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              const Spacer(flex: 1),

              Image.asset(
                'assets/icons/solveBaseLogo.png',
                width: width * 0.45,
                height: width * 0.45,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 28),

              ShimmerText(
                text: 'SolveBase',
                style: const TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                  color: Colors.white,
                ),
                baseColor: Color.fromARGB(148, 46, 35, 197),
                highlightColor: Color.fromARGB(191, 219, 11, 21),
              ),

              const SizedBox(height: 38),

              ShimmerText(
                text: 'AI-Powered Math Guide & Solver.\nFast. Smart. Reliable.',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                baseColor: Colors.teal,
                highlightColor: Colors.greenAccent,
              ),

              const SizedBox(height: 20),

              ShimmerText(
                text: 'Just type it, snap it.\nSolveBase will guide you.',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                baseColor: const Color.fromARGB(255, 208, 208, 208),
                highlightColor: const Color.fromARGB(255, 75, 78, 76),
              ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
