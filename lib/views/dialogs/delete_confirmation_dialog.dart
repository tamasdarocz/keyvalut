import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:keyvalut/services/auth_service.dart';
import 'package:keyvalut/data/credential_provider.dart';
import 'package:keyvalut/data/database_helper.dart';

/// A dialog widget that confirms database deletion with authentication.
///
/// The user must check a confirmation box and enter their PIN or password
/// to proceed with deleting the database. Upon successful deletion,
/// the [onDeleteSuccess] callback is triggered.
class DeleteConfirmationDialog extends StatefulWidget {
  final AuthService authService;
  final bool isPinMode;
  final String currentDatabase;
  final VoidCallback onDeleteSuccess;

  const DeleteConfirmationDialog({
    super.key,
    required this.authService,
    required this.isPinMode,
    required this.currentDatabase,
    required this.onDeleteSuccess,
  });

  @override
  State<DeleteConfirmationDialog> createState() => _DeleteConfirmationDialogState();
}

class _DeleteConfirmationDialogState extends State<DeleteConfirmationDialog> {
  final TextEditingController _credentialController = TextEditingController();
  bool _isConfirmed = false;
  String? _errorMessage;

  @override
  void dispose() {
    _credentialController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete Database'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Are you sure you want to delete this database? This action cannot be undone.'),
          const SizedBox(height: 16),
          Row(
            children: [
              Checkbox(
                value: _isConfirmed,
                onChanged: (value) {
                  setState(() {
                    _isConfirmed = value ?? false;
                  });
                },
              ),
              const Text('I understand this action is permanent'),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _credentialController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: widget.isPinMode ? 'PIN' : 'Password',
              border: const OutlineInputBorder(),
              errorText: _errorMessage,
            ),
            keyboardType: widget.isPinMode ? TextInputType.number : TextInputType.text,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _isConfirmed
              ? () async {
            final input = _credentialController.text.trim();
            if (input.isEmpty) {
              setState(() {
                _errorMessage = 'Please enter your ${widget.isPinMode ? 'PIN' : 'password'}';
              });
              return;
            }

            final isAuthenticated = await widget.authService.verifyMasterCredential(input);
            if (!isAuthenticated) {
              setState(() {
                _errorMessage = 'Incorrect ${widget.isPinMode ? 'PIN' : 'password'}';
              });
              return;
            }

            try {
              // Delete the database
              final dbHelper = DatabaseHelper(widget.currentDatabase);
              final provider = Provider.of<CredentialProvider>(context, listen: false);
              await provider.clearAllData(); // Clear in-memory data
              await (await dbHelper.database).close(); // Close the database
              await dbHelper.deleteDatabase(); // Delete the database file

              // Clear the current database from SharedPreferences
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('currentDatabase');

              // Reset CredentialProvider
              provider.setDatabaseName('default');

              if (mounted) {
                Navigator.pop(context); // Close this dialog
                Fluttertoast.showToast(msg: 'Database deleted successfully');
                widget.onDeleteSuccess(); // Trigger logout
              }
            } catch (e) {
              if (mounted) {
                setState(() {
                  _errorMessage = 'Error deleting database: $e';
                });
              }
            }
          }
              : null,
          child: const Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}