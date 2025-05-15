import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_swipe_action_cell/flutter_swipe_action_cell.dart';
import 'package:keyvalut/core/services/database_provider.dart';
import 'package:keyvalut/features/notes/screens/note_edit_page.dart';
import 'note_view_page.dart';

class NotesPage extends StatelessWidget {
  const NotesPage({super.key});

  Widget _getIconButton(Color color, IconData icon) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(45),
        color: color,
      ),
      child: Icon(
        icon,
        color: Colors.white,
      ),
    );
  }

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
            padding: const EdgeInsets.symmetric(vertical: 5),
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
                plainContent = note.content;
              }

              return SwipeActionCell(
                key: ValueKey(note.id),
                trailingActions: <SwipeAction>[
                  SwipeAction(
                    color: Colors.transparent,
                    content: _getIconButton(theme.colorScheme.primary, Icons.edit),
                    onTap: (CompletionHandler handler) async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NoteEditPage(note: note),
                        ),
                      );
                      handler(false); // Prevent dismissal
                    },
                  ),
                ],
                leadingActions: <SwipeAction>[
                  SwipeAction(
                    color: Colors.transparent,
                    content: _getIconButton(Colors.red, Icons.delete),
                    nestedAction: SwipeNestedAction(
                      content: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(45),
                          color: Colors.red,
                        ),
                        height: 70,
                        child: OverflowBox(
                          maxWidth: double.infinity,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                              Text('Confirm', style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    onTap: (CompletionHandler handler) async {
                      await provider.moveToTrash(note.id!);
                      Fluttertoast.showToast(
                        msg: 'Moved to Trash',
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.CENTER,
                        backgroundColor: Colors.red,
                        textColor: Colors.white,
                      );
                    },
                  ),
                  SwipeAction(
                    color: Colors.transparent,
                    content: _getIconButton(theme.colorScheme.secondary, Icons.archive),
                    onTap: (CompletionHandler handler) async {
                      await provider.archiveNote(note.id!);
                      Fluttertoast.showToast(
                        msg: 'Note Archived',
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.CENTER,
                        backgroundColor: theme.colorScheme.primary,
                        textColor: theme.colorScheme.onPrimary,
                      );
                    },
                  )
                ],
                child: Container(
                  height: 100,
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Column(
                        children: [
                          Expanded(
                            child: Container(
                              color: Colors.red,
                              width: 5,
                            ),
                          ),
                          Expanded(
                            child: Container(
                              color: theme.colorScheme.secondary,
                              width: 5,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width - 10,
                        child: ListTile(
                          title: Text(note.title),
                          titleTextStyle: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                          subtitle: Text(
                            plainContent,
                            maxLines: 3,
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
                      Container(
                        width: 5,
                        height: 100,
                        color: theme.colorScheme.primary,
                      )
                    ],
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
