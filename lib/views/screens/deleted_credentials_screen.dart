import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import '../../data/credential_provider.dart';
import '../../data/credential_model.dart';

class DeletedCredentialsScreen extends StatelessWidget {
  const DeletedCredentialsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deleted Credentials'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Consumer<CredentialProvider>(
        builder: (context, provider, child) {
          final deletedCredentials = provider.deletedCredentials;

          if (deletedCredentials.isEmpty) {
            return const Center(child: Text('No deleted credentials'));
          }

          return ListView.builder(
            itemCount: deletedCredentials.length,
            itemBuilder: (context, index) {
              final credential = deletedCredentials[index];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Slidable(
                  key: ValueKey(credential.id),

                  // Left action - Delete permanently
                  startActionPane: ActionPane(
                    motion: const ScrollMotion(),
                    children: [
                      SlidableAction(
                        onPressed: (context) async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Permanently'),
                              content: const Text('This cannot be undone. Are you sure?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );

                          if (confirmed == true && credential.id != null) {
                            await provider.deleteCredential(credential.id!);
                          }
                        },
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        icon: Icons.delete_forever,
                        label: 'Delete',
                      ),
                    ],
                  ),

                  // Right action - Restore
                  endActionPane: ActionPane(
                    motion: const ScrollMotion(),
                    children: [
                      SlidableAction(
                        onPressed: (context) async {
                          await provider.restoreCredential(credential.id!);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${credential.title} restored')),
                          );
                        },
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        icon: Icons.restore,
                        label: 'Restore',
                      ),
                    ],
                  ),

                  child: ListTile(
                    leading: const Icon(Icons.delete_outline),
                    title: Text(credential.title),
                    subtitle: Text('Username: ${credential.username}'),
                    trailing: Text(
                      'Deleted: ${credential.deletedAt?.day}/${credential.deletedAt?.month}/${credential.deletedAt?.year}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}