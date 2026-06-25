import 'package:url_launcher/url_launcher.dart';

class UpiService {
  /// Launches any installed UPI app pre-filled with the payment details.
  /// Note: Returns false if no UPI apps are installed or if it fails.
  static Future<bool> initiatePayment({
    required String payeeUpiId,
    required String payeeName,
    required double amount,
    required String transactionNote,
  }) async {
    // Amount should be formatted to 2 decimal places max
    final String amountStr = amount.toStringAsFixed(2);
    
    // Build the deep-link URI
    final Uri upiUri = Uri(
      scheme: 'upi',
      host: 'pay',
      queryParameters: {
        'pa': payeeUpiId,
        'pn': payeeName,
        'am': amountStr,
        'cu': 'INR',
        'tn': transactionNote,
      },
    );

    try {
      // url_launcher defaults can handle native intents on Android
      bool launched = await launchUrl(
        upiUri,
        mode: LaunchMode.externalApplication,
      );
      return launched;
    } catch (e) {
      return false;
    }
  }
}
