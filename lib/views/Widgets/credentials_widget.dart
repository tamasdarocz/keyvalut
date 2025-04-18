import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../data/credentialProvider.dart';
import '../../data/credential_model.dart';
import '../../data/credential_detail.dart';
import '../../data/database_helper.dart';
import 'create_element_form.dart';

class CredentialsWidget extends StatelessWidget {
  const CredentialsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final credentialProvider = Provider.of<CredentialProvider>(context);

    // Load credentials on initial build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      credentialProvider.loadCredentials();
    });

    return Consumer<CredentialProvider>(
      builder: (context, provider, child) {
        if (provider.credentials.isEmpty) {
          return const Center(child: Text('No credentials found'));
        }

        return ListView.builder(
          itemCount: provider.credentials.length,
          itemBuilder: (context, index) {
            final credential = provider.credentials[index];

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Slidable(
                // Key is required for Slidable
                key: ValueKey(credential.id),

                // Left slide actions (Archive and Delete)
                startActionPane: ActionPane(
                  motion: const ScrollMotion(),
                  children: [
                    SlidableAction(
                      onPressed: (context) async {
                        // Archive functionality
                        final updatedCredential = Credential(
                          id: credential.id,
                          title: credential.title,
                          website: credential.website,
                          email: credential.email,
                          username: credential.username,
                          password: credential.password,
                          totpSecret: credential.totpSecret,
                          isArchived: true,
                          isDeleted: credential.isDeleted,
                          deletedAt: credential.deletedAt,
                          archivedAt: DateTime.now(),
                        );
                        await provider.updateCredential(updatedCredential);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${credential.title} archived')),
                        );
                      },
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.white,
                      icon: Icons.archive,
                      label: 'Archive',
                    ),
              SlidableAction(
                onPressed: (context) async {
                  // Delete confirmation
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Move to Trash'),
                      content: const Text('Are you sure you want to move this credential to trash?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Move to Trash'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    // Use moveToTrash instead of deleteCredential
                    await provider.moveToTrash(credential);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${credential.title} moved to trash')),
                    );
                  }
                },
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                icon: Icons.delete,
                label: 'Delete',
              ),

                  ],
                ),

                // Right slide action (Edit)
                endActionPane: ActionPane(
                  motion: const ScrollMotion(),
                  children: [
                    SlidableAction(
                      onPressed: (context) {
                        // Navigate directly to CreateElementForm instead of CredentialDetail
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreateElementForm(
                              dbHelper: DatabaseHelper.instance,
                              credential: credential,
                            ),
                          ),
                        );
                      },
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      icon: Icons.edit,
                      label: 'Edit',
                    ),
                  ],
                ),

                // Main content
                child: ExpansionTile(
                  leading: const Icon(Icons.key),
                  title: Text(credential.title),
                  subtitle: Text("Username: ${credential.username}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: credential.password));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Center(child: Text('Password copied!'))),
                      );
                    },
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (credential.website != null && credential.website!.isNotEmpty)
                            _buildDetailRow(context, 'Website', credential.website!),

                          if (credential.email != null && credential.email!.isNotEmpty)
                            _buildDetailRow(context, 'Email', credential.email!),

                          _buildDetailRow(context, 'Username', credential.username),

                          // Password with visibility toggle
                          _PasswordRow(password: credential.password),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
          IconButton(
            icon: const Icon(Icons.copy, size: 20),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Center(child: Text('$label copied!'))),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PasswordRow extends StatefulWidget {
  final String password;

  const _PasswordRow({required this.password});

  @override
  _PasswordRowState createState() => _PasswordRowState();
}

class _PasswordRowState extends State<_PasswordRow> {
  bool _showPassword = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          const SizedBox(
            width: 80,
            child: Text(
              'Password:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(_showPassword ? widget.password : '••••'),
          ),
          IconButton(
            icon: Icon(
              _showPassword ? Icons.visibility_off : Icons.visibility,
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _showPassword = !_showPassword;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 20),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: widget.password));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Center(child: Text('Password copied!'))),
              );
            },
          ),
        ],
      ),
    );
  }
}