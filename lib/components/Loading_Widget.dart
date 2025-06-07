import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the screen width using MediaQuery
    double screenWidth = MediaQuery.of(context).size.width;

    // Set width as a percentage of the screen width
    double width = screenWidth * 0.94; // 80% of screen width

    return Column(
      children: [
        // Shimmer effect for "Crunching numbers"
        Shimmer.fromColors(
          // baseColor: const Color.fromARGB(148, 46, 35, 197),
          // highlightColor: const Color.fromARGB(191, 219, 11, 21),
          baseColor: const Color.fromARGB(194, 26, 105, 252),
          highlightColor: const Color.fromARGB(227, 33, 239, 167),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(
                width: 16.0,
              ), // Adds space between the left edge and the text
              Text(
                // 'Crunching numbers....',
                'Putting numbers to work...',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Shimmer effect for the loading rectangle
        shimmerRec(width, 50),
        const SizedBox(height: 20),
        shimmerRec(width, 70),
        const SizedBox(height: 20),
        shimmerRec(width, 100),
        const SizedBox(height: 20),
        shimmerRec(width, 90),
        const SizedBox(height: 20),
        shimmerRec(width, 70),
        const SizedBox(height: 20),
      ],
    );
  }

  Shimmer shimmerRec(double width, double height) {
    return Shimmer.fromColors(
      baseColor: Color.fromARGB(107, 123, 123, 123),
      highlightColor: Colors.grey[600]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(25)),
          gradient: LinearGradient(
            colors: [Color(0x66747474), Color(0x6B262222)],
          ),
        ),
      ),
    );
  }
}
