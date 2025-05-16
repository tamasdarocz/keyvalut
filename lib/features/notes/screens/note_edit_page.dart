import 'dart:convert';
import 'package:flutter/material.dart';
// Added for Clipboard
import 'package:flutter_quill/flutter_quill.dart';
import 'package:keyvalut/features/notes/widgets/horizontal_quill_toolbar.dart';
import 'package:keyvalut/features/notes/widgets/vertical_quill_toolbar.dart';
import 'package:provider/provider.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:keyvalut/core/model/database_model.dart';
import 'package:keyvalut/core/services/database_provider.dart';
import '../../dialogs/unsaved_changes_dialog.dart';

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
  String? _initialTitle;
  String? _initialContent;
// Track if text is selected

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      try {
        final deltaJson = jsonDecode(widget.note!.content);
        _quillController.document = quill.Document.fromJson(deltaJson);
      } catch (e) {
        _quillController.document = quill.Document()
          ..insert(0, widget.note!.content);
      }
    }
    _initialTitle = _titleController.text;
    _initialContent = jsonEncode(_quillController.document.toDelta().toJson());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _quillController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool _hasChanges() {
    final currentTitle = _titleController.text;
    final currentContent = jsonEncode(_quillController.document.toDelta().toJson());
    return currentTitle != _initialTitle || currentContent != _initialContent;
  }

  void _saveNote() {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<DatabaseProvider>(context, listen: false);
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

  Future<bool> _onWillPop() async {
    if (!_hasChanges()) {
      return true;
    }
    return await showDialog<bool>(
      context: context,
      builder: (context) => UnsavedChangesDialog(
        initialTitle: _initialTitle ?? '',
        initialContent: _initialContent ?? '',
        titleController: _titleController,
        quillController: _quillController,
        onSave: _saveNote,
        note: widget.note,
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
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
          padding: const EdgeInsets.all(8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _titleController,
                  style: Theme.of(context).textTheme.titleSmall,
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
                const SizedBox(height: 8),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      VerticalQuillToolbar(controller: _quillController),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Container(
                          decoration: const BoxDecoration(),
                          child: quill.QuillEditor(
                            controller: _quillController,
                            scrollController: _scrollController,
                            focusNode: FocusNode(),
                            configurations: quill.QuillEditorConfigurations(
                              placeholder: 'Enter content...',
                              autoFocus: false,
                              expands: false,
                              disableClipboard: false,
                              enableSelectionToolbar: true,
                              enableInteractiveSelection: true,
                              textSelectionThemeData: TextSelectionTheme.of(context),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              customStyles: DefaultStyles(
                                inlineCode: InlineCodeStyle(
                                  backgroundColor: Colors.black45,
                                  style: const TextStyle(),
                                ),
                                strikeThrough: const TextStyle(
                                  decorationColor: Colors.white,
                                  decoration: TextDecoration.lineThrough,
                                  decorationThickness: 2,
                                ),
                                underline: const TextStyle(
                                  decorationColor: Colors.white,
                                  decoration: TextDecoration.underline,
                                  decorationThickness: 2,
                                ),
                              ),
                              elementOptions: quill.QuillEditorElementOptions(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                HorizontalQuillToolbar(controller: _quillController),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
