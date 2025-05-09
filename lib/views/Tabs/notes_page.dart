import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:keyvalut/data/database_provider.dart';
import 'package:keyvalut/views/screens/note_edit_page.dart';

import 'note_view_page.dart';

class NotesPage extends StatelessWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DatabaseProvider>(context);
    final theme = Theme.of(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      provider.loadNotes();
    });

    return Scaffold(
      body: Consumer<DatabaseProvider>(
        builder: (context, provider, child) {
          if (provider.notes.isEmpty) {
            return Center(
              child: Text(
                'No notes found',
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
            );
          }

          return ListView.builder(
            itemCount: provider.notes.length,
            itemBuilder: (context, index) {
              final note = provider.notes[index];
              // Extract plain text from Quill Delta JSON
              String plainContent;
              try {
                final deltaJson = jsonDecode(note.content);
                final doc = quill.Document.fromJson(deltaJson);
                plainContent = doc.toPlainText();
              } catch (e) {
                // Fallback to raw content if not JSON (backward compatibility)
                plainContent = note.content;
              }
              return Slidable(
                key: ValueKey(note.id),
                startActionPane: ActionPane(
                  motion: const ScrollMotion(),
                  children: [
                    SlidableAction(
                      onPressed: (context) async {
                        await provider.archiveNote(note.id!);
                        Fluttertoast.showToast(
                          msg: 'Note Archived',
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.CENTER,
                          backgroundColor: theme.colorScheme.primary,
                          textColor: theme.colorScheme.onPrimary,
                        );
                      },
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      icon: Icons.archive,
                      label: 'Archive',
                    ),
                    SlidableAction(
                      onPressed: (context) async {
                        await provider.moveToTrash(note.id!);
                        Fluttertoast.showToast(
                          msg: 'Note Moved to Trash',
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.CENTER,
                          backgroundColor: Colors.red,
                          textColor: Colors.white,
                        );
                      },
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      icon: Icons.delete,
                      label: 'Delete',
                    ),
                  ],
                ),
                endActionPane: ActionPane(
                  motion: ScrollMotion(),
                  children: [
                    SlidableAction(
                      onPressed: (context) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NoteEditPage(note: note),
                          ),
                        );
                      },
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      icon: Icons.edit,
                      label: 'Edit',
                    ),
                  ],
                ),
                child: Container(
                  margin: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                  ),
                  child: ListTile(
                        title: Text(note.title),
                        titleTextStyle: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        subtitle: Text(
                          plainContent.length > 100 ? '${plainContent.substring(0, 100)}...' : plainContent,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NoteViewPage(note: note),
                            ),
                          );
                        },
                      ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NoteEditPage(),
            ),
          );
        },
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(Icons.add),
      ),
    );
  }
}