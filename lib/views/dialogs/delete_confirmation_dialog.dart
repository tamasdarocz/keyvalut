import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:keyvalut/services/auth_service.dart';
import 'package:keyvalut/data/database_provider.dart';
import 'package:keyvalut/data/database_helper.dart';
import 'package:keyvalut/services/utils.dart';
import 'package:keyvalut/views/Tabs/login_screen.dart';

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
          const Text(
            'Are you sure you want to delete this database? This action cannot be undone.',
            overflow: TextOverflow.ellipsis,
          ),
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
              final provider = Provider.of<DatabaseProvider>(context, listen: false);
              await provider.clearAllData(); // Clear in-memory data
              await (await dbHelper.database).close(); // Close the database
              await dbHelper.deleteDatabase(); // Delete the database file

              // Fetch remaining databases
              final remainingDatabases = await fetchDatabaseNames();

              // Update SharedPreferences
              final prefs = await SharedPreferences.getInstance();
              if (remainingDatabases.isEmpty) {
                await prefs.remove('currentDatabase');
              } else {
                await prefs.setString('currentDatabase', remainingDatabases.first);
              }

              // Update CredentialProvider
              if (remainingDatabases.isEmpty) {
                provider.setDatabaseName(''); // Clear the database name if no databases remain
              } else {
                provider.setDatabaseName(remainingDatabases.first); // Set to the first remaining database
              }

              if (mounted) {
                Navigator.pop(context); // Close this dialog
                Fluttertoast.showToast(msg: 'Database deleted successfully');
                widget.onDeleteSuccess(); // Trigger logout or navigation
                // Ensure navigation to LoginScreen if not already handled by onDeleteSuccess
                if (remainingDatabases.isEmpty) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                }
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