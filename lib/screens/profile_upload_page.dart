import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../config/api.dart';

class ProfileUploadPage extends StatefulWidget {
  final int userId; // pass user ID
  const ProfileUploadPage({super.key, required this.userId});

  @override
  State<ProfileUploadPage> createState() => _ProfileUploadPageState();
}

class _ProfileUploadPageState extends State<ProfileUploadPage> {
  File? _imageFile;
  bool _isUploading = false;
  String? _uploadedUrl;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null) return;

    setState(() => _isUploading = true);

    var uri = Uri.parse('${Api.baseUrl}${Api.uploadProfilePictureEndpoint}');
    var request = http.MultipartRequest('POST', uri);

    // Add user ID
    request.fields['user_id'] = widget.userId.toString();

    // Attach file
    var fileStream = await http.MultipartFile.fromPath(
      'profile_picture',
      _imageFile!.path,
      filename: path.basename(_imageFile!.path),
    );
    request.files.add(fileStream);

    try {
      var response = await request.send();
      var respStr = await response.stream.bytesToString();
      var jsonResp = json.decode(respStr);

      if (response.statusCode == 200 && jsonResp['success'] == true) {
        setState(() => _uploadedUrl = jsonResp['data']['image_url']);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Upload successful!')));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(jsonResp['message'] ?? 'Upload failed')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Profile Picture')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _imageFile != null
                ? Image.file(_imageFile!, height: 200)
                : const Icon(Icons.account_circle, size: 100),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text('Pick Image'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isUploading ? null : _uploadImage,
              child: _isUploading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Upload Image'),
            ),
            if (_uploadedUrl != null) ...[
              const SizedBox(height: 20),
              Text(
                'Uploaded URL:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(_uploadedUrl!),
            ],
          ],
        ),
      ),
    );
  }
}
