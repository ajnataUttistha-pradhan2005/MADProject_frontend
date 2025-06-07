import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class WelcomeIntro extends StatelessWidget {
  const WelcomeIntro({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(height: 80),

        // App Logo
        SizedBox(
          height: 100,
          width: 100,
          child: Image.asset(
            'assets/icons/NumTutorLogo.png',
            fit: BoxFit.contain,
          ),
        ),

        const SizedBox(height: 30),

        // Welcome Text
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: const Text(
            "Meet Your Math Guide",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color.fromARGB(255, 47, 55, 59),
              fontSize: 36,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),

        const SizedBox(height: 10),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: const Text(
            "NumTutor",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color.fromARGB(255, 33, 90, 210),
              fontSize: 24,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ),

        const SizedBox(height: 80),

        // Shimmer Text
        Shimmer.fromColors(
          baseColor: const Color.fromARGB(194, 26, 105, 252),
          highlightColor: const Color.fromARGB(227, 33, 239, 167),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: const Text(
              'Stuck on a problem? Let’s solve it together – fast and stress-free!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
