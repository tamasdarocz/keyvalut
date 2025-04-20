/*import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:keyvalut/data/credential_model.dart';
import 'package:keyvalut/data/credential_provider.dart';
import 'package:keyvalut/views/screens/note_edit_page.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  @override
  void initState() {
    super.initState();
    // Load notes when the page is initialized
    Provider.of<CredentialProvider>(context, listen: false).loadNotes();
  }

  void _showNoteOptions(Note note) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NoteEditPage(note: note),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive),
              title: Text(note.isArchived ? 'Unarchive' : 'Archive'),
              onTap: () {
                Navigator.pop(context);
                final provider = Provider.of<CredentialProvider>(context, listen: false);
                if (note.isArchived) {
                  provider.restoreNote(note.id!);
                } else {
                  provider.archiveNote(note.id!);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: Text(note.isDeleted ? 'Restore' : 'Delete'),
              onTap: () {
                Navigator.pop(context);
                final provider = Provider.of<CredentialProvider>(context, listen: false);
                if (note.isDeleted) {
                  provider.restoreNote(note.id!);
                } else {
                  provider.deleteNote(note.id!);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
      ),
      body: Consumer<CredentialProvider>(
        builder: (context, provider, child) {
          final notes = provider.notes;
          if (notes.isEmpty) {
            return const Center(
              child: Text('No notes available. Create a new note!'),
            );
          }
          return ListView.builder(
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              if (note.isDeleted) return const SizedBox.shrink(); // Skip deleted notes
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: ListTile(
                  title: Text(
                    note.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: note.isArchived ? Colors.grey : null,
                    ),
                  ),
                  subtitle: Text(
                    note.content.length > 50 ? '${note.content.substring(0, 50)}...' : note.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Icon(
                    note.isArchived ? Icons.archive : null,
                    color: Colors.grey,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NoteEditPage(note: note),
                      ),
                    );
                  },
                  onLongPress: () => _showNoteOptions(note),
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
        child: const Icon(Icons.add),
      ),
    );
  }
}

 */