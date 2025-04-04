import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class WelcomeIntro extends StatelessWidget {
  const WelcomeIntro({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 100),
        // Welcome Text inside a Container with centered text alignment
        Container(
          padding: const EdgeInsets.all(
            16.0,
          ), // Padding for spacing around the text
          child: Text(
            "Welcome To Math Solver App",
            textAlign: TextAlign.center, // Center the text
            style: TextStyle(
              color: Color(0xB5C2C7D9),
              fontSize: 36,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),

        const SizedBox(height: 100),

        // Shimmer effect with centered and paragraph-aligned text
        Shimmer.fromColors(
          baseColor: const Color.fromARGB(148, 46, 35, 197),
          highlightColor: const Color.fromARGB(191, 219, 11, 21),
          child: Container(
            padding: const EdgeInsets.all(
              16.0,
            ), // Padding for spacing around the text
            child: Text(
              'Quick, smart, and reliable math solutions at your fingertips. Let’s solve it together!',
              textAlign: TextAlign.center, // Center the text
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
