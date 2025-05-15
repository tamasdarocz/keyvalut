import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:keyvalut/features/auth/services/auth_service.dart';
import 'package:keyvalut/core/services/database_provider.dart';
import 'package:keyvalut/core/services/database_helper.dart';
import 'package:keyvalut/features/settings/services/utils.dart';


import '../auth/screens/login_screen.dart';

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
            'This will permanently delete all logins, credit cards, and notes in this database. This action cannot be undone.',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          const Text(
            'Are you sure you want to proceed?',
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

              // Update DatabaseProvider
              if (remainingDatabases.isEmpty) {
                provider.setDatabaseName(''); // Clear the database name if no databases remain
              } else {
                provider.setDatabaseName(remainingDatabases.first); // Set to the first remaining database
              }

              if (mounted) {
                Navigator.pop(context); // Close this dialog
                Fluttertoast.showToast(msg: 'Database deleted successfully');
                widget.onDeleteSuccess(); // Trigger logout or navigation
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