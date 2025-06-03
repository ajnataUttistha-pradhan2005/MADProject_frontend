import 'dart:io';
import 'package:flutter/material.dart';

class ImageViewerPage extends StatelessWidget {
  final String imageContent;

  const ImageViewerPage({super.key, required this.imageContent});

  @override
  Widget build(BuildContext context) {
    final isNetwork = imageContent.startsWith('http');
    final isFile = File(imageContent).existsSync();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          child:
              isNetwork
                  ? Image.network(
                    imageContent,
                    errorBuilder: (context, error, stackTrace) {
                      return const Text(
                        '❌ Failed to load image from URL',
                        style: TextStyle(color: Colors.red),
                      );
                    },
                  )
                  : isFile
                  ? Image.file(
                    File(imageContent),
                    errorBuilder: (context, error, stackTrace) {
                      return const Text(
                        '❌ Failed to load local image file',
                        style: TextStyle(color: Colors.red),
                      );
                    },
                  )
                  : const Text(
                    '🛑 Invalid image path or content',
                    style: TextStyle(color: Colors.red),
                  ),
        ),
      ),
    );
  }
}
