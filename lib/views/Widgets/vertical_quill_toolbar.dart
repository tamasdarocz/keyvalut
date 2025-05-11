import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

class VerticalQuillToolbar extends StatelessWidget {
  final quill.QuillController controller;

  const VerticalQuillToolbar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        color: Theme.of(context).colorScheme.secondary,
        width: 40,
          child: quill.QuillToolbar.simple(
            configurations: quill.QuillSimpleToolbarConfigurations(
              controller: controller,
              toolbarSectionSpacing: 0,
              showDividers: false,
              showHeaderStyle: false,
              showFontFamily: false,
              showFontSize: false,
              showColorButton: true,
              showClipboardCopy: false,
              showClipboardCut: false,
              showClipboardPaste: false,
              showSearchButton: false,

            ),
          ),
      ),
    );
  }
}