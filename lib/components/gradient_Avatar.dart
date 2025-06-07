import 'dart:io';
import 'package:flutter/material.dart';

class GradientAvatar extends StatelessWidget {
  final String imagePath;
  final bool isAsset;
  final bool isFile;
  final double size;
  final double borderWidth;
  final List<Color> gradientColors;

  const GradientAvatar({
    super.key,
    required this.imagePath, // Can be asset path, file path, or URL
    this.isAsset = false,
    this.isFile = false,
    this.size = 80,
    this.borderWidth = 4,
    // this.gradientColors = const [
    //   Color(0xFF1D7DFA),
    //   Color(0xFF8617C7),
    //   Color.fromARGB(255, 213, 14, 18),
    // ],
    this.gradientColors = const [
      Color(0xFF007ACC), // Vivid Blue
      Color(0xFF00B8D9), // Cyan Blue
      Color(0xFF00D1A0), // Mint Green
      Color(0xFF12C2E9), // Aqua
    ],
  });

  Widget _buildImage() {
    try {
      if (imagePath.isEmpty) return _fallbackIcon();

      // Priority: Manual flags -> Detect
      if (isAsset ||
          (!imagePath.startsWith('http') && !File(imagePath).existsSync())) {
        return Image.asset(imagePath, fit: BoxFit.cover);
      } else if (isFile || File(imagePath).existsSync()) {
        return Image.file(File(imagePath), fit: BoxFit.cover);
      } else {
        return Image.network(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackIcon(),
        );
      }
    } catch (e) {
      print('GradientAvatar error: $e');
      return _fallbackIcon();
    }
  }

  Widget _fallbackIcon() {
    return Container(
      color: Colors.grey.shade300,
      child: Icon(Icons.person, size: size / 2, color: Colors.grey.shade600),
    );
  }

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
      child: ClipOval(child: _buildImage()),
    );
  }
}
