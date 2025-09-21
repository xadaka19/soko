import 'package:flutter_test/flutter_test.dart';
import 'package:sokofiti/services/mpesa_service_simplified.dart';

void main() {
  group('MpesaServiceSimplified Tests', () {
    test('formatPhoneNumber should format phone numbers correctly', () {
      // Test various phone number formats
      expect(MpesaServiceSimplified.formatPhoneNumber('0712345678'), '254712345678');
      expect(MpesaServiceSimplified.formatPhoneNumber('712345678'), '254712345678');
      expect(MpesaServiceSimplified.formatPhoneNumber('254712345678'), '254712345678');
      expect(MpesaServiceSimplified.formatPhoneNumber('+254712345678'), '254712345678');
      expect(MpesaServiceSimplified.formatPhoneNumber('0701234567'), '254701234567');
      expect(MpesaServiceSimplified.formatPhoneNumber('701234567'), '254701234567');
    });

    test('getErrorMessage should return appropriate error messages', () {
      expect(
        MpesaServiceSimplified.getErrorMessage('INSUFFICIENT_FUNDS', 'fallback'),
        'Insufficient funds in your M-Pesa account. Please top up and try again.',
      );
      
      expect(
        MpesaServiceSimplified.getErrorMessage('INVALID_PHONE', 'fallback'),
        'Invalid phone number. Please check and try again.',
      );
      
      expect(
        MpesaServiceSimplified.getErrorMessage('USER_CANCELLED', 'fallback'),
        'Payment was cancelled. Please try again.',
      );
      
      expect(
        MpesaServiceSimplified.getErrorMessage('UNKNOWN_ERROR', 'Custom fallback'),
        'Custom fallback',
      );
      
      expect(
        MpesaServiceSimplified.getErrorMessage(null, 'Default message'),
        'Default message',
      );
    });
  });
}
