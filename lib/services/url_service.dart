import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

import '../views/Widgets/top_message.dart';

class UrlService {
  static Future<void> launchWebsite({
    required BuildContext context,
    required String? url,
  }) async {
    if (url == null || url.isEmpty) {
      _showError(context, 'No website available');
      return;
    }

    try {
      // Clean and validate URL
      final cleanedUrl = _cleanUrl(url);
      final parsedUrl = Uri.parse(cleanedUrl);

      if (!await canLaunchUrl(parsedUrl)) {
        _showError(context, 'No app available to handle this URL');
        return;
      }

      await launchUrl(
        parsedUrl,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      _showError(context, 'Failed to launch URL: ${e.toString()}');
    }
  }

  static String _cleanUrl(String url) {
    // Remove any existing protocols and whitespace
    var cleaned = url
        .trim()
        .replaceAll(RegExp(r'^https?://'), '')
        .replaceAll(RegExp(r'\s+'), '');

    // Add https protocol if missing
    if (!cleaned.startsWith('http')) {
      cleaned = 'https://$cleaned';
    }

    return cleaned;
  }

  static void _showError(BuildContext context, String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      backgroundColor: Theme.of(context).colorScheme.error,
      textColor: Theme.of(context).colorScheme.onError,
      fontSize: 16.0,
    );
  }
}