import 'package:flutter/material.dart';

class GradientAvatar extends StatelessWidget {
  final String imageUrl;
  final bool isAsset;
  final double size;
  final double borderWidth;
  final List<Color> gradientColors;

  const GradientAvatar({
    super.key,
    required this.imageUrl, // Image is required
    this.isAsset = false,
    this.size = 80,
    this.borderWidth = 4,
    this.gradientColors = const [
      Color(0xFF1D7DFA),
      Color(0xFF8617C7),
      // Color(0XFF4B148D),
      Color.fromARGB(255, 213, 14, 18),
    ],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(borderWidth),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ClipOval(
        child:
            isAsset
                ? Image.asset(imageUrl, fit: BoxFit.cover)
                : Image.network(imageUrl, fit: BoxFit.cover),
      ),
    );
  }
}
