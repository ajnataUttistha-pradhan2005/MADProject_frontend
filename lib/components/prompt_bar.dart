import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:saver_gallery/saver_gallery.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class PromptBar extends StatefulWidget {
  final TextEditingController controller;
  final void Function(dynamic) onSend;
  final bool isLoading;
  final void Function(bool)? onFocusChange;
  final FocusNode focusNode; // Add FocusNode to manage focus explicitly

  const PromptBar({
    super.key,
    required this.controller,
    required this.onSend,
    this.isLoading = false,
    this.onFocusChange,
    required this.focusNode, // Receive FocusNode here
  });

  @override
  State<PromptBar> createState() => _PromptBarState();
}

class _PromptBarState extends State<PromptBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 20),
      color: Colors.transparent,
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1B1F),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: const Color(0xFF636363)),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 120),
                child: TextField(
                  controller: widget.controller,
                  focusNode: widget.focusNode, // Pass FocusNode here
                  maxLines: null,
                  style: const TextStyle(
                    color: Color.fromARGB(255, 207, 206, 206),
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: "Enter your Problem...",
                    hintStyle: TextStyle(color: Color(0xFFB3B3B3)),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              if (widget.controller.text.trim().isNotEmpty) {
                widget.onSend(widget.controller.text.trim());
                widget.controller.clear();
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.greenAccent,
              ),
              child: Icon(
                widget.isLoading ? Icons.pause : Icons.send,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              widget.focusNode
                  .unfocus(); // Unfocus keyboard when media options are tapped
              _showMediaOptions(context);
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blueAccent,
              ),
              child: const Icon(Icons.attach_file, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showMediaOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[850],
      builder: (BuildContext context) {
        return Container(
          height: 135,
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.white),
                title: const Text(
                  'Use Camera',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickMedia(context, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo, color: Colors.white),
                title: const Text(
                  'From Gallery',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickMedia(context, ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // void _pickMedia(BuildContext context, ImageSource source) async {
  //   final ImagePicker picker = ImagePicker();
  //   final XFile? pickedFile = await picker.pickImage(source: source);

  //   if (pickedFile != null) {
  //     File imageFile = File(pickedFile.path);

  //     if (source == ImageSource.camera) {
  //       Uint8List fileBytes = await imageFile.readAsBytes();
  //       String fileName =
  //           'captured_${DateTime.now().millisecondsSinceEpoch}${path.extension(pickedFile.path)}';
  //       await SaverGallery.saveImage(
  //         fileBytes,
  //         fileName: fileName,
  //         skipIfExists: false,
  //       );
  //     }

  //     widget.onSend(imageFile); // ✅ Send image to HomePage
  //   } else {
  //     print("No image selected");
  //   }
  // }

  void _pickMedia(BuildContext context, ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: source);

      if (pickedFile == null) {
        debugPrint("⚠️ No image selected");
        return;
      }

      File originalFile = File(pickedFile.path);
      File finalFile = originalFile;

      final int originalSizeKB = await originalFile.length() ~/ 1024;
      debugPrint('📸 Original file size: $originalSizeKB KB');

      // ✅ Only compress if from camera and size > 1MB
      if (source == ImageSource.camera && originalSizeKB > 1024) {
        try {
          final dir = await getTemporaryDirectory();
          final targetPath = path.join(
            dir.absolute.path,
            "compressed_${DateTime.now().millisecondsSinceEpoch}.jpg",
          );

          final XFile? compressedXFile =
              await FlutterImageCompress.compressAndGetFile(
                originalFile.absolute.path,
                targetPath,
                quality: 85, // Tuned for OCR
              );

          if (compressedXFile != null) {
            finalFile = File(compressedXFile.path);
            final int compressedSizeKB = await finalFile.length() ~/ 1024;
            debugPrint("✅ Compressed file size: $compressedSizeKB KB");
          } else {
            debugPrint("❌ Compression failed, using original file.");
          }
        } catch (e) {
          debugPrint("❌ Error during compression: $e");
        }
      }

      // ✅ Send image (compressed or original) to handler
      widget.onSend(finalFile);
    } catch (e, stack) {
      debugPrint("❌ Unexpected error in _pickMedia: $e");
      debugPrint(stack.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Something went wrong while picking the image."),
        ),
      );
    }
  }
}
