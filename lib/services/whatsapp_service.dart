import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

class WhatsAppService {
  /// Open WhatsApp chat with a specific phone number
  static Future<bool> openWhatsAppChat({
    required String phoneNumber,
    String? message,
  }) async {
    try {
      // Format phone number (remove any non-digit characters except +)
      String formattedPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      
      // Ensure phone number starts with country code
      if (formattedPhone.startsWith('0')) {
        formattedPhone = '254${formattedPhone.substring(1)}';
      } else if (!formattedPhone.startsWith('+') && !formattedPhone.startsWith('254')) {
        formattedPhone = '254$formattedPhone';
      }
      
      // Remove + if present for WhatsApp URL
      if (formattedPhone.startsWith('+')) {
        formattedPhone = formattedPhone.substring(1);
      }
      
      // Encode message if provided
      String encodedMessage = '';
      if (message != null && message.isNotEmpty) {
        encodedMessage = '&text=${Uri.encodeComponent(message)}';
      }
      
      // Create WhatsApp URL
      final whatsappUrl = 'https://wa.me/$formattedPhone?$encodedMessage';
      final uri = Uri.parse(whatsappUrl);
      
      // Try to launch WhatsApp
      if (await canLaunchUrl(uri)) {
        return await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('WhatsApp launch error: $e');
      return false;
    }
  }

  /// Open WhatsApp chat for a listing inquiry
  static Future<bool> openWhatsAppForListing({
    required String phoneNumber,
    required String listingTitle,
    String? sellerName,
  }) async {
    final message = sellerName != null
        ? 'Hi $sellerName! I\'m interested in your listing: $listingTitle'
        : 'Hi! I\'m interested in your listing: $listingTitle';
    
    return await openWhatsAppChat(
      phoneNumber: phoneNumber,
      message: message,
    );
  }

  /// Check if WhatsApp is installed (this will attempt to open WhatsApp)
  static Future<bool> isWhatsAppInstalled() async {
    try {
      final uri = Uri.parse('https://wa.me/');
      return await canLaunchUrl(uri);
    } catch (e) {
      return false;
    }
  }

  /// Show WhatsApp contact dialog
  static void showWhatsAppDialog({
    required BuildContext context,
    required String phoneNumber,
    required String listingTitle,
    String? sellerName,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.chat, color: Colors.green),
              SizedBox(width: 8),
              Text('Contact via WhatsApp'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Contact ${sellerName ?? 'seller'} about:'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  listingTitle,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Phone: $phoneNumber',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                
                final success = await openWhatsAppForListing(
                  phoneNumber: phoneNumber,
                  listingTitle: listingTitle,
                  sellerName: sellerName,
                );
                
                if (!success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Could not open WhatsApp. Please make sure it\'s installed.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.chat),
              label: const Text('Open WhatsApp'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }
}
