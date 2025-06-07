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
  final FocusNode focusNode;

  const PromptBar({
    super.key,
    required this.controller,
    required this.onSend,
    this.isLoading = false,
    this.onFocusChange,
    required this.focusNode,
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
          // Expanded Text Field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color.fromARGB(255, 107, 107, 107),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 120),
                child: TextField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  maxLines: null,
                  style: const TextStyle(color: Colors.black87),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: "Type your question here...",
                    hintStyle: TextStyle(color: Color.fromARGB(200, 3, 3, 3)),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Attach Button
          Material(
            color: Colors.transparent,
            child: Ink(
              decoration: const ShapeDecoration(
                color: Color.fromARGB(255, 230, 19, 3),
                shape: CircleBorder(),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.attach_file_rounded,
                  color: Colors.white,
                ),
                onPressed: () {
                  widget.focusNode.unfocus();
                  _showMediaOptions(context);
                },
              ),
            ),
          ),

          const SizedBox(width: 6),
          // Send Button
          Material(
            color: Colors.transparent,
            child: Ink(
              decoration: const ShapeDecoration(
                color: Color(0xFF0077FF),
                shape: CircleBorder(),
              ),
              child: IconButton(
                icon: Icon(
                  widget.isLoading ? Icons.pause : Icons.send_rounded,
                  color: Colors.white,
                ),
                onPressed: () {
                  if (widget.controller.text.trim().isNotEmpty) {
                    widget.onSend(widget.controller.text.trim());
                    widget.controller.clear();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMediaOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SizedBox(
          height: 150,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.black87),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickMedia(context, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo, color: Colors.black87),
                title: const Text('Choose from Gallery'),
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
