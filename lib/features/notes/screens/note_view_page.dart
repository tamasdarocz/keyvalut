import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:keyvalut/core/model/database_model.dart';
import 'package:keyvalut/features/notes/screens/note_edit_page.dart';

class NoteViewPage extends StatefulWidget {
  final Note note;

  const NoteViewPage({super.key, required this.note});

  @override
  State<NoteViewPage> createState() => _NoteViewPageState();
}

class _NoteViewPageState extends State<NoteViewPage> {
  late final ScrollController scrollController;
  late final quill.QuillController quillController;
  late final FocusNode _focusNode;
  quill.Document? _document;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
    _focusNode = FocusNode(canRequestFocus: false);

    try {

      final deltaJson = jsonDecode(widget.note.content);
      _document = quill.Document.fromJson(deltaJson);
    } catch (e) {
      _document = quill.Document()..insert(0, widget.note.content);
    }

    quillController = quill.QuillController(
      document: _document!,
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: true,
    );
  }

  @override
  void dispose() {
    scrollController.dispose();
    quillController.dispose();
    _focusNode.dispose();
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
      body: Container(
                width: MediaQuery.sizeOf(context).width,
                height: MediaQuery.sizeOf(context).height,
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                ),

                child: quill.QuillEditor.basic(
                  controller: quillController,
                  configurations: quill.QuillEditorConfigurations(
                    padding: const EdgeInsets.all(8),
                    scrollable: true, // Ensure content is scrollable

                  ),
                ),
              ),
    );
  }
}