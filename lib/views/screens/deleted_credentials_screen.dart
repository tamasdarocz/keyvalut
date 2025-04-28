import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../data/database_provider.dart';

class DeletedItemsView extends StatelessWidget {
  const DeletedItemsView({super.key});

  Future<bool> _confirmBulkAction(BuildContext context, String action, String itemType) async {
    return (await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$action All $itemType'),
        content: Text('Are you sure you want to $action all $itemType items? ${action == "Permanently Delete" ? "This action cannot be undone." : ""}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    )) ??
        false;
  }

  Future<void> _deleteAllItems(BuildContext context, CredentialProvider provider) async {
    if (provider.deletedCredentials.isEmpty && provider.deletedCreditCards.isEmpty && provider.deletedNotes.isEmpty) return;

    final confirmed = await _confirmBulkAction(context, 'Permanently Delete', 'Deleted');
    if (!confirmed) return;

    for (var credential in provider.deletedCredentials) {
      await provider.permanentlyDeleteCredential(credential.id!);
    }
    for (var card in provider.deletedCreditCards) {
      await provider.permanentlyDeleteCreditCard(card.id!);
    }
    for (var note in provider.deletedNotes) {
      await provider.permanentlyDeleteNote(note.id!);
    }

    Fluttertoast.showToast(
      msg: 'All Deleted Items Permanently Deleted',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      backgroundColor: Theme.of(context).colorScheme.primary,
      textColor: Theme.of(context).colorScheme.onPrimary,
    );
  }

  Future<void> _restoreAllItems(BuildContext context, CredentialProvider provider) async {
    if (provider.deletedCredentials.isEmpty && provider.deletedCreditCards.isEmpty && provider.deletedNotes.isEmpty) return;

    final confirmed = await _confirmBulkAction(context, 'Restore', 'Deleted');
    if (!confirmed) return;

    for (var credential in provider.deletedCredentials) {
      await provider.restoreCredential(credential.id!);
    }
    for (var card in provider.deletedCreditCards) {
      await provider.restoreCreditCard(card.id!);
    }
    for (var note in provider.deletedNotes) {
      await provider.restoreNote(note.id!);
    }

    Fluttertoast.showToast(
      msg: 'All Deleted Items Restored',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      backgroundColor: Theme.of(context).colorScheme.primary,
      textColor: Theme.of(context).colorScheme.onPrimary,
    );
  }

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
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: 'Restore All',
            onPressed: provider.deletedCredentials.isEmpty && provider.deletedCreditCards.isEmpty && provider.deletedNotes.isEmpty
                ? null
                : () => _restoreAllItems(context, provider),
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Delete All',
            onPressed: provider.deletedCredentials.isEmpty && provider.deletedCreditCards.isEmpty && provider.deletedNotes.isEmpty
                ? null
                : () => _deleteAllItems(context, provider),
          ),
        ],
      ),
      body: Consumer<CredentialProvider>(
        builder: (context, provider, child) {
          if (provider.deletedCredentials.isEmpty && provider.deletedCreditCards.isEmpty && provider.deletedNotes.isEmpty) {
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
              // Deleted Notes
              if (provider.deletedNotes.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Notes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                ...provider.deletedNotes.map((note) => Slidable(
                  key: ValueKey(note.id),
                  endActionPane: ActionPane(
                    motion: const ScrollMotion(),
                    children: [
                      SlidableAction(
                        onPressed: (context) async {
                          await provider.restoreNote(note.id!);
                          Fluttertoast.showToast(
                            msg: 'Note Restored',
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
                              title: const Text('Permanently Delete Note'),
                              content: const Text('Are you sure you want to permanently delete this note? This action cannot be undone.'),
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
                            await provider.permanentlyDeleteNote(note.id!);
                            Fluttertoast.showToast(
                              msg: 'Note Permanently Deleted',
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
                    title: Text(note.title),
                    subtitle: Text('Deleted at: ${note.deletedAt}'),
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