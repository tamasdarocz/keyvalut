import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:keyvalut/core/model/database_model.dart';

class UnsavedChangesDialog extends StatelessWidget {
  final String initialTitle;
  final String initialContent;
  final TextEditingController titleController;
  final quill.QuillController quillController;
  final VoidCallback onSave;
  final Note? note;

  const UnsavedChangesDialog({
    super.key,
    required this.initialTitle,
    required this.initialContent,
    required this.titleController,
    required this.quillController,
    required this.onSave,
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Unsaved Changes'),
      content: const Text('You have unsaved changes. What would you like to do?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false), // Stay
          child: const Text('Stay'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true), // Discard
          child: const Text('Discard'),
        ),
        TextButton(
          onPressed: () {
            onSave(); // Save and pop
            Navigator.of(context).pop(true);
          },
          child: const Text('Save Changes'),
        ),
      ],
    );
  }
}