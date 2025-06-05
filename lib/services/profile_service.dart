import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mathsolver/globals.dart';
import 'package:path/path.dart';

class ProfileService {
  static String baseUrl = '${Globals.httpURI}/user';

  // Edit profile API call
  static Future<bool> editProfile({
    required String userId,
    String? username,
    String? email,
    File? imageFile,
  }) async {
    try {
      var uri = Uri.parse('$baseUrl/editprofile');
      var request = http.MultipartRequest('POST', uri);

      request.fields['userId'] = userId;

      if (username != null) {
        request.fields['username'] = username;
      }
      if (email != null) {
        request.fields['email'] = email;
      }

      if (imageFile != null) {
        var stream = http.ByteStream(imageFile.openRead());
        var length = await imageFile.length();
        var multipartFile = http.MultipartFile(
          'image',
          stream,
          length,
          filename: basename(imageFile.path),
        );
        request.files.add(multipartFile);
      }

      var response = await request.send();

      if (response.statusCode == 200) {
        try {
          final responseBody = await response.stream.bytesToString();
          final decoded = json.decode(responseBody);

          final user = decoded['user'];

          // Safely update global variables if available
          Globals.email = user['email'] ?? Globals.email;
          Globals.username = user['username'] ?? Globals.username;
          Globals.profileImg = user['profileImg'] ?? Globals.profileImg;

          return true;
        } catch (e) {
          print('Error parsing profile update response: $e');
          return false;
        }
      } else {
        print('Edit profile failed with status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Edit profile error: $e');
      return false;
    }
  }
}
