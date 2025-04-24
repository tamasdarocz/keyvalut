import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';

class RecoveryKeyDialog extends StatelessWidget {
  final String recoveryKey;

  const RecoveryKeyDialog({
    super.key,
    required this.recoveryKey,
  });

  Future<void> _exportRecoveryKey(BuildContext context) async {
    try {
      final content = 'KeyVault Recovery Key: $recoveryKey';
      final bytes = utf8.encode(content);

      // Use FilePicker to let the user choose the save location, reusing the approach from ExportService
      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Recovery Key',
        fileName: 'recovery_key.txt',
        type: FileType.custom,
        allowedExtensions: ['txt'],
        bytes: bytes, // Provide bytes for web; native will handle writing manually
      );

      if (outputPath != null) {
        if (!kIsWeb) {
          // Native: Write the file to the user-selected path
          final file = await File(outputPath).writeAsBytes(bytes);
          Fluttertoast.showToast(
            msg: 'Recovery key saved to ${file.path}',
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.CENTER,
            backgroundColor: Colors.black54,
            textColor: Colors.white,
            fontSize: 16.0,
          );
        } else {
          // Web: FilePicker already handled the download with the bytes provided
          Fluttertoast.showToast(
            msg: 'Recovery key exported successfully',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            backgroundColor: Colors.black54,
            textColor: Colors.white,
            fontSize: 16.0,
          );
        }
      } else {
        // User cancelled the save operation
        Fluttertoast.showToast(
          msg: 'Export cancelled',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.black54,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error exporting recovery key: $e',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.redAccent,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: recoveryKey));
    if (context.mounted) {
      Fluttertoast.showToast(
        msg: 'Recovery key copied to clipboard',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  void _shareRecoveryKey() {
    SharePlus.instance.share(
      ShareParams(
        text: 'KeyVault Recovery Key: $recoveryKey',
        subject: 'KeyVault Recovery Key',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      title: Text(
        'Your Recovery Key',
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: theme.colorScheme.error,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'This is your recovery key. It is crucial for resetting your master credential if you forget it. Store it securely!',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: SelectableText(
              recoveryKey,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => _exportRecoveryKey(context),
          child: Text(
            'Export',
            style: TextStyle(color: theme.colorScheme.primary),
          ),
        ),
        TextButton(
          onPressed: () => _copyToClipboard(context),
          child: Text(
            'Copy to Clipboard',
            style: TextStyle(color: theme.colorScheme.primary),
          ),
        ),
        TextButton(
          onPressed: _shareRecoveryKey,
          child: Text(
            'Share',
            style: TextStyle(color: theme.colorScheme.primary),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Close',
            style: TextStyle(color: theme.colorScheme.primary),
          ),
        ),
      ],
    );
  }
}