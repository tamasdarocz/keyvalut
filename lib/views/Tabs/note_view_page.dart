import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:keyvalut/data/database_model.dart';
import 'package:keyvalut/views/screens/note_edit_page.dart';


class NoteViewPage extends StatefulWidget {
  final Note note;

  const NoteViewPage({super.key, required this.note});

  @override
  State<NoteViewPage> createState() => _NoteViewPageState();
}

class _NoteViewPageState extends State<NoteViewPage> {
  late final ScrollController scrollController;
  late final quill.QuillController quillController;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();

    // Parse Quill Delta JSON to display formatted content
    quill.Document document;
    try {
      final deltaJson = jsonDecode(widget.note.content);
      document = quill.Document.fromJson(deltaJson);
    } catch (e) {
      // Fallback to plain text if not JSON
      document = quill.Document()..insert(0, widget.note.content);
    }

    quillController = quill.QuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: -1),
    );
    quillController.readOnly = true; // Set read-only mode on the controller
  }

  @override
  void dispose() {
    scrollController.dispose();
    quillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => NoteEditPage(note: widget.note),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.note.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: quill.QuillEditor(
                  controller: quillController,
                  scrollController: scrollController,
                  focusNode: FocusNode(canRequestFocus: false), // Optional: disable focus
                  configurations: quill.QuillEditorConfigurations(
                    placeholder: 'No content...',
                    autoFocus: false,
                    expands: true,
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}