import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:keyvalut/data/credential_model.dart';
import 'package:keyvalut/data/credential_provider.dart';

class NoteEditPage extends StatefulWidget {
  final Note? note;

  const NoteEditPage({super.key, this.note});

  @override
  State<NoteEditPage> createState() => _NoteEditPageState();
}

class _NoteEditPageState extends State<NoteEditPage> {
  final _titleController = TextEditingController();
  final _quillController = quill.QuillController.basic();
  final _scrollController = ScrollController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      try {
        final deltaJson = jsonDecode(widget.note!.content);
        _quillController.document = quill.Document.fromJson(deltaJson);
      } catch (e) {
        _quillController.document = quill.Document()..insert(0, widget.note!.content);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _quillController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _saveNote() {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<CredentialProvider>(context, listen: false);
    final deltaJson = jsonEncode(_quillController.document.toDelta().toJson());
    final newNote = Note(
      id: widget.note?.id,
      title: _titleController.text,
      content: deltaJson,
      isArchived: widget.note?.isArchived ?? false,
      archivedAt: widget.note?.archivedAt,
      isDeleted: widget.note?.isDeleted ?? false,
      deletedAt: widget.note?.deletedAt,
    );

    if (widget.note == null) {
      provider.addNote(newNote);
    } else {
      provider.updateNote(newNote);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? 'New Note' : 'Edit Note'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveNote,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              quill.QuillToolbar.simple(
                configurations: quill.QuillSimpleToolbarConfigurations(
                  controller: _quillController,
                  multiRowsDisplay: false,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).colorScheme.outline),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: quill.QuillEditor(
                    controller: _quillController,
                    scrollController: _scrollController,
                    focusNode: FocusNode(),
                    configurations: quill.QuillEditorConfigurations(
                      placeholder: 'Enter content...',
                      autoFocus: false,
                      expands: false,
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}