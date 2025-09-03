import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../utils/session_manager.dart';

class ImageService {
  /// Watermark an image with "Posted on Sokofiti - [Username]"
  static Future<File> watermarkImage(File originalImage) async {
    try {
      // Get user info for watermark
      final user = await SessionManager.getUser();
      final username = user != null
          ? (user['first_name'] ?? 'User').toString()
          : 'User';

      // Read the original image
      final imageBytes = await originalImage.readAsBytes();
      final originalImg = img.decodeImage(imageBytes);

      if (originalImg == null) {
        throw Exception('Failed to decode image');
      }

      // Create watermark text
      final watermarkText = 'Posted on Sokofiti - $username';

      // Calculate watermark position and size
      final imgWidth = originalImg.width;
      final imgHeight = originalImg.height;
      final fontSize = (imgWidth * 0.03).round().clamp(12, 24);

      // Create a copy of the original image
      final watermarkedImg = img.Image.from(originalImg);

      // Add semi-transparent background for watermark
      final watermarkBgColor = img.ColorRgba8(
        0,
        0,
        0,
        128,
      ); // Semi-transparent black
      final watermarkTextColor = img.ColorRgba8(
        255,
        255,
        255,
        255,
      ); // White text

      // Calculate text dimensions (approximate)
      final textWidth = watermarkText.length * (fontSize * 0.6).round();
      final textHeight = fontSize + 4;

      // Position watermark at bottom-right with padding
      final padding = 10;
      final x = imgWidth - textWidth - padding;
      final y = imgHeight - textHeight - padding;

      // Draw background rectangle for watermark
      img.fillRect(
        watermarkedImg,
        x1: x - 5,
        y1: y - 2,
        x2: x + textWidth + 5,
        y2: y + textHeight + 2,
        color: watermarkBgColor,
      );

      // Draw watermark text
      img.drawString(
        watermarkedImg,
        watermarkText,
        font: img.arial14,
        x: x,
        y: y,
        color: watermarkTextColor,
      );

      // Save watermarked image to temporary directory
      final tempDir = await getTemporaryDirectory();
      final fileName =
          'watermarked_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final watermarkedFile = File(path.join(tempDir.path, fileName));

      // Encode and save the watermarked image
      final watermarkedBytes = img.encodeJpg(watermarkedImg, quality: 85);
      await watermarkedFile.writeAsBytes(watermarkedBytes);

      return watermarkedFile;
    } catch (e) {
      debugPrint('Error watermarking image: $e');
      // Return original image if watermarking fails
      return originalImage;
    }
  }

  /// Watermark multiple images
  static Future<List<File>> watermarkImages(List<File> images) async {
    final watermarkedImages = <File>[];

    for (final image in images) {
      final watermarkedImage = await watermarkImage(image);
      watermarkedImages.add(watermarkedImage);
    }

    return watermarkedImages;
  }

  /// Create a more advanced watermark using Flutter's Canvas
  static Future<File> createAdvancedWatermark(File originalImage) async {
    try {
      // Get user info
      final user = await SessionManager.getUser();
      final username = user != null
          ? (user['first_name'] ?? 'User').toString()
          : 'User';

      // Read original image
      final imageBytes = await originalImage.readAsBytes();
      final codec = await ui.instantiateImageCodec(imageBytes);
      final frame = await codec.getNextFrame();
      final originalUiImage = frame.image;

      // Create a canvas to draw on
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Draw the original image
      canvas.drawImage(originalUiImage, Offset.zero, Paint());

      // Create watermark text
      final watermarkText = 'Posted on Sokofiti - $username';

      // Configure text style
      final textStyle = ui.TextStyle(
        color: Colors.white,
        fontSize: originalUiImage.width * 0.025,
        fontWeight: FontWeight.bold,
      );

      final paragraphStyle = ui.ParagraphStyle(textAlign: TextAlign.left);

      final paragraphBuilder = ui.ParagraphBuilder(paragraphStyle)
        ..pushStyle(textStyle)
        ..addText(watermarkText);

      final paragraph = paragraphBuilder.build()
        ..layout(ui.ParagraphConstraints(width: originalUiImage.width * 0.8));

      // Draw semi-transparent background
      final bgPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.5)
        ..style = PaintingStyle.fill;

      final bgRect = Rect.fromLTWH(
        originalUiImage.width - paragraph.width - 20,
        originalUiImage.height - paragraph.height - 20,
        paragraph.width + 10,
        paragraph.height + 10,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(bgRect, const Radius.circular(5)),
        bgPaint,
      );

      // Draw text
      canvas.drawParagraph(
        paragraph,
        Offset(
          originalUiImage.width - paragraph.width - 15,
          originalUiImage.height - paragraph.height - 15,
        ),
      );

      // Convert to image
      final picture = recorder.endRecording();
      final watermarkedUiImage = await picture.toImage(
        originalUiImage.width,
        originalUiImage.height,
      );

      // Convert to bytes
      final byteData = await watermarkedUiImage.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        throw Exception('Failed to convert watermarked image to bytes');
      }

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final fileName =
          'advanced_watermarked_${DateTime.now().millisecondsSinceEpoch}.png';
      final watermarkedFile = File(path.join(tempDir.path, fileName));

      await watermarkedFile.writeAsBytes(byteData.buffer.asUint8List());

      // Clean up
      originalUiImage.dispose();
      watermarkedUiImage.dispose();

      return watermarkedFile;
    } catch (e) {
      debugPrint('Error creating advanced watermark: $e');
      return originalImage;
    }
  }

  /// Resize image if it's too large
  static Future<File> resizeImage(
    File imageFile, {
    int maxWidth = 1920,
    int maxHeight = 1080,
  }) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      final originalImg = img.decodeImage(imageBytes);

      if (originalImg == null) {
        return imageFile;
      }

      // Check if resizing is needed
      if (originalImg.width <= maxWidth && originalImg.height <= maxHeight) {
        return imageFile;
      }

      // Calculate new dimensions maintaining aspect ratio
      double ratio = originalImg.width / originalImg.height;
      int newWidth, newHeight;

      if (originalImg.width > originalImg.height) {
        newWidth = maxWidth;
        newHeight = (maxWidth / ratio).round();
      } else {
        newHeight = maxHeight;
        newWidth = (maxHeight * ratio).round();
      }

      // Resize image
      final resizedImg = img.copyResize(
        originalImg,
        width: newWidth,
        height: newHeight,
        interpolation: img.Interpolation.linear,
      );

      // Save resized image
      final tempDir = await getTemporaryDirectory();
      final fileName = 'resized_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final resizedFile = File(path.join(tempDir.path, fileName));

      final resizedBytes = img.encodeJpg(resizedImg, quality: 85);
      await resizedFile.writeAsBytes(resizedBytes);

      return resizedFile;
    } catch (e) {
      debugPrint('Error resizing image: $e');
      return imageFile;
    }
  }

  /// Process image: resize and watermark
  static Future<File> processImage(File originalImage) async {
    try {
      // First resize if needed
      final resizedImage = await resizeImage(originalImage);

      // Then add watermark
      final watermarkedImage = await watermarkImage(resizedImage);

      return watermarkedImage;
    } catch (e) {
      debugPrint('Error processing image: $e');
      return originalImage;
    }
  }
}
