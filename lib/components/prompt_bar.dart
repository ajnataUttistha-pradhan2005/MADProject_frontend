import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data'; // For Uint8List
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:saver_gallery/saver_gallery.dart'; // Import saver_gallery

class PromptBar extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String) onSend;
  final bool isLoading; // New parameter to show loading state

  const PromptBar({
    super.key,
    required this.controller,
    required this.onSend,
    this.isLoading = false, // Default to false (no loading)
  });

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
                color: Color(0xFF1A1B1F), // Darker background
                borderRadius: BorderRadius.circular(25), // More rounded corners
                border: Border.all(color: Color(0xFF636363)),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 120),
                child: TextField(
                  controller: controller,
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
              if (controller.text.trim().isNotEmpty) {
                onSend(controller.text.trim());
                controller.clear();
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.greenAccent,
              ),
              child: Icon(
                isLoading
                    ? Icons.pause
                    : Icons.send, // Change icon based on loading state
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              // Show media options (camera and gallery) when this button is pressed
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
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt, color: Colors.white),
                title: Text(
                  'Use Camera',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickMedia(context, ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo, color: Colors.white),
                title: Text(
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
      File originalFile = File(pickedFile.path);

      // Convert the picked file to Uint8List
      Uint8List fileBytes = await originalFile.readAsBytes();

      if (source == ImageSource.camera) {
        // If the image is from the camera, save it to the gallery

        // Get the app's document directory to save the image temporarily
        Directory appDir = await getApplicationDocumentsDirectory();

        // Create a unique file name using the timestamp to avoid overwriting files
        String fileName =
            'captured_${DateTime.now().millisecondsSinceEpoch}${path.extension(pickedFile.path)}';
        String savedPath = path.join(appDir.path, fileName);

        // Save the image to the gallery
        SaveResult saveResult = await SaverGallery.saveImage(
          fileBytes, // Provide the image as Uint8List
          fileName: fileName, // Provide the file name
          skipIfExists: false, // Don't skip if the file exists
        );

        //logging

        print('Image saved to gallery with result: ${saveResult.isSuccess}');
      } else if (source == ImageSource.gallery) {
        // If the image is from the gallery, just print a message
        print("Image selected from gallery: ${pickedFile.path}");
      }
    } else {
      print("No image selected");
    }
  }
}





// before
//   void _showMediaOptions(BuildContext context) {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.grey[850], // Dark background for the modal
//       builder: (BuildContext context) {
//         return Container(
//           height: 135,
//           decoration: BoxDecoration(
//             color: Colors.grey[850],
//             borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//           ),
//           child: Column(
//             children: [
//               ListTile(
//                 leading: Icon(Icons.camera_alt, color: Colors.white),
//                 title: Text(
//                   'Use Camera',
//                   style: TextStyle(color: Colors.white),
//                 ),
//                 onTap: () {
//                   Navigator.pop(context);
//                 },
//               ),
//               ListTile(
//                 leading: Icon(Icons.photo, color: Colors.white),
//                 title: Text(
//                   'From Gallery',
//                   style: TextStyle(color: Colors.white),
//                 ),
//                 onTap: () {
//                   Navigator.pop(context);
//                 },
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }