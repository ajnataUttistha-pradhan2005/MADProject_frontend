import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:saver_gallery/saver_gallery.dart';

class PromptBar extends StatefulWidget {
  final TextEditingController controller;
  final void Function(dynamic) onSend;
  final bool isLoading;
  final void Function(bool)? onFocusChange;

  const PromptBar({
    super.key,
    required this.controller,
    required this.onSend,
    this.isLoading = false,
    this.onFocusChange,
  });

  @override
  State<PromptBar> createState() => _PromptBarState();
}

class _PromptBarState extends State<PromptBar> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();

    _focusNode.addListener(() {
      if (widget.onFocusChange != null) {
        widget.onFocusChange!(_focusNode.hasFocus);
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

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
                  focusNode: _focusNode,
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
              _focusNode.unfocus();
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

  void _pickMedia(BuildContext context, ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);

      if (source == ImageSource.camera) {
        Uint8List fileBytes = await imageFile.readAsBytes();
        String fileName =
            'captured_${DateTime.now().millisecondsSinceEpoch}${path.extension(pickedFile.path)}';
        await SaverGallery.saveImage(
          fileBytes,
          fileName: fileName,
          skipIfExists: false,
        );
      }

      widget.onSend(imageFile); // ✅ Send image to HomePage
    } else {
      print("No image selected");
    }
  }
}
