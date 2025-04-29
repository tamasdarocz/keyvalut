import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:keyvalut/services/auth_service.dart';
import 'package:keyvalut/data/database_provider.dart';
import 'package:keyvalut/data/database_helper.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io' show File;
import 'package:flutter/foundation.dart'; // For debugPrint

/// A dialog widget that allows the user to rename the current database.
///
/// This dialog prompts the user to enter a new database name, validates the input,
/// and performs the rename operation by updating the database file, [SharedPreferences],
/// [DatabaseProvider], and [AuthService]. It provides feedback via [ScaffoldMessenger].
class RenameDatabaseDialog extends StatefulWidget {
  final String currentDatabase;
  final AuthService authService;
  final VoidCallback onRenameSuccess;

  const RenameDatabaseDialog({
    super.key,
    required this.currentDatabase,
    required this.authService,
    required this.onRenameSuccess,
  });

  @override
  State<RenameDatabaseDialog> createState() => _RenameDatabaseDialogState();
}

class _RenameDatabaseDialogState extends State<RenameDatabaseDialog> {
  final TextEditingController _renameController = TextEditingController();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _renameController.text = widget.currentDatabase;
  }

  @override
  void dispose() {
    _renameController.dispose();
    super.dispose();
  }

  /// Migrates AuthService-related secure storage keys to the new database name.
  ///
  /// Copies all relevant keys from the old database name to the new one and deletes the old keys.
  Future<void> _migrateAuthServiceKeys(String oldDatabaseName, String newDatabaseName) async {
    const authServiceKeys = [
      'salt_',
      'isPin_',
      'masterCredential_',
      'recoveryKey_',
      'biometricEnabled_',
      'failedAttempts_',
      'lockoutEndTime_',
      'forceResetRequired_',
    ];

    for (final keyPrefix in authServiceKeys) {
      final oldKey = '$keyPrefix$oldDatabaseName';
      final newKey = '$keyPrefix$newDatabaseName';
      final value = await _secureStorage.read(key: oldKey);
      if (value != null) {
        await _secureStorage.write(key: newKey, value: value);
        await _secureStorage.delete(key: oldKey);
      }
    }
  }

  /// Renames the database and updates all necessary dependencies.
  ///
  /// Validates the new database name, renames the database file, migrates AuthService keys,
  /// and updates [SharedPreferences], [DatabaseProvider], and [AuthService].
  /// Shows a toast message on success or failure.
  Future<void> _renameDatabase(BuildContext dialogContext) async {
    final newDatabaseName = _renameController.text.trim();

    if (newDatabaseName.isEmpty) {
      ScaffoldMessenger.of(dialogContext).showSnackBar(
        const SnackBar(content: Text('Database name cannot be empty')),
      );
      return;
    }

    if (newDatabaseName == widget.currentDatabase) {
      Navigator.pop(dialogContext, null);
      return;
    }

    try {
      // Check if a database with the new name already exists
      final tempDbHelper = DatabaseHelper(newDatabaseName);
      if (await tempDbHelper.databaseExists()) {
        if (mounted) {
          ScaffoldMessenger.of(dialogContext).showSnackBar(
            const SnackBar(content: Text('A database with this name already exists')),
          );
        }
        return;
      }

      // Get the database provider
      final provider = Provider.of<DatabaseProvider>(dialogContext, listen: false);

      // Construct the old and new database file paths
      final directory = await getApplicationDocumentsDirectory();
      final oldPath = join(directory.path, '${widget.currentDatabase}.db');
      final newPath = join(directory.path, '$newDatabaseName.db');

      debugPrint('Attempting to rename database from $oldPath to $newPath');

      // Verify the old file exists
      final oldFile = File(oldPath);
      if (!await oldFile.exists()) {
        throw Exception('Database file does not exist at path: $oldPath');
      }
      debugPrint('Old database file exists at $oldPath');

      // Close the current database connection to release the file
      await provider.closeDatabase();
      debugPrint('Closed database connection via provider for ${widget.currentDatabase}');

      // Handle SQLite journal files (-shm and -wal)
      final oldShmPath = join(directory.path, '${widget.currentDatabase}.db-shm');
      final oldWalPath = join(directory.path, '${widget.currentDatabase}.db-wal');
      final newShmPath = join(directory.path, '$newDatabaseName.db-shm');
      final newWalPath = join(directory.path, '$newDatabaseName.db-wal');

      // Rename the main database file
      await oldFile.rename(newPath);
      debugPrint('Renamed main database file to $newPath');

      // Rename journal files if they exist
      if (await File(oldShmPath).exists()) {
        await File(oldShmPath).rename(newShmPath);
        debugPrint('Renamed -shm file to $newShmPath');
      }
      if (await File(oldWalPath).exists()) {
        await File(oldWalPath).rename(newWalPath);
        debugPrint('Renamed -wal file to $newWalPath');
      }

      // Migrate AuthService secure storage keys
      await _migrateAuthServiceKeys(widget.currentDatabase, newDatabaseName);

      // Update SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currentDatabase', newDatabaseName);

      // Update DatabaseProvider
      provider.setDatabaseName(newDatabaseName);

      // Update AuthService
      widget.authService.setDatabaseName(newDatabaseName);

      if (mounted) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          const SnackBar(content: Text('Database renamed successfully')),
        );

        widget.onRenameSuccess();
        Navigator.pop(dialogContext, newDatabaseName);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          SnackBar(content: Text('Error renaming database: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rename Database'),
      content: TextField(
        controller: _renameController,
        decoration: const InputDecoration(
          labelText: 'New Database Name',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => _renameDatabase(context),
          child: const Text('Rename'),
        ),
      ],
    );
  }
}