import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../data/credential_provider.dart';


class DeletedItemsView extends StatelessWidget {
  const DeletedItemsView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CredentialProvider>(context);
    final theme = Theme.of(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      provider.loadDeletedItems();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deleted Items'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Consumer<CredentialProvider>(
        builder: (context, provider, child) {
          if (provider.deletedCredentials.isEmpty && provider.deletedCreditCards.isEmpty) {
            return Center(
              child: Text(
                'No deleted items found',
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(8),
            children: [
              // Deleted Credentials
              if (provider.deletedCredentials.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Credentials',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                ...provider.deletedCredentials.map((credential) => Slidable(
                  key: ValueKey(credential.id),
                  endActionPane: ActionPane(
                    motion: const ScrollMotion(),
                    children: [
                      SlidableAction(
                        onPressed: (context) async {
                          await provider.restoreCredential(credential.id!);
                          Fluttertoast.showToast(
                            msg: 'Credential Restored',
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.TOP,
                            backgroundColor: theme.colorScheme.primary,
                            textColor: theme.colorScheme.onPrimary,
                          );
                        },
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        icon: Icons.restore,
                        label: 'Restore',
                      ),
                      SlidableAction(
                        onPressed: (context) async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Permanently Delete Credential'),
                              content: const Text('Are you sure you want to permanently delete this credential? This action cannot be undone.'),
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
                          if (confirmed == true) {
                            await provider.permanentlyDeleteCredential(credential.id!);
                            Fluttertoast.showToast(
                              msg: 'Credential Permanently Deleted',
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.TOP,
                              backgroundColor: theme.colorScheme.primary,
                              textColor: theme.colorScheme.onPrimary,
                            );
                          }
                        },
                        backgroundColor: theme.colorScheme.error,
                        foregroundColor: theme.colorScheme.onError,
                        icon: Icons.delete_forever,
                        label: 'Delete',
                      ),
                    ],
                  ),
                  child: ListTile(
                    title: Text(credential.title),
                    subtitle: Text('Deleted at: ${credential.deletedAt}'),
                  ),
                )),
              ],
              // Deleted Credit Cards
              if (provider.deletedCreditCards.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Credit Cards',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                ...provider.deletedCreditCards.map((card) => Slidable(
                  key: ValueKey(card.id),
                  endActionPane: ActionPane(
                    motion: const ScrollMotion(),
                    children: [
                      SlidableAction(
                        onPressed: (context) async {
                          await provider.restoreCreditCard(card.id!);
                          Fluttertoast.showToast(
                            msg: 'Credit Card Restored',
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.CENTER,
                            backgroundColor: theme.colorScheme.primary,
                            textColor: theme.colorScheme.onPrimary,
                          );
                        },
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        icon: Icons.restore,
                        label: 'Restore',
                      ),
                      SlidableAction(
                        onPressed: (context) async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Permanently Delete Credit Card'),
                              content: const Text('Are you sure you want to permanently delete this credit card? This action cannot be undone.'),
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
                          if (confirmed == true) {
                            await provider.permanentlyDeleteCreditCard(card.id!);
                            Fluttertoast.showToast(
                              msg: 'Credit Card Permanently Deleted',
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.CENTER,
                              backgroundColor: theme.colorScheme.primary,
                              textColor: theme.colorScheme.onPrimary,
                            );
                          }
                        },
                        backgroundColor: theme.colorScheme.error,
                        foregroundColor: theme.colorScheme.onError,
                        icon: Icons.delete_forever,
                        label: 'Delete',
                      ),
                    ],
                  ),
                  child: ListTile(
                    title: Text(card.title),
                    subtitle: Text('Deleted at: ${card.deletedAt}'),
                  ),
                )),
              ],
            ],
          );
        },
      ),
    );
  }
}