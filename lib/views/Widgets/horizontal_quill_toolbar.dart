import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

class HorizontalQuillToolbar extends StatelessWidget {
  final quill.QuillController controller;

  const HorizontalQuillToolbar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: quill.QuillToolbar.simple(
        configurations: quill.QuillSimpleToolbarConfigurations(
          controller: controller,
          multiRowsDisplay: false,
          showDividers: false,
          showHeaderStyle: true,
          showFontFamily: true,
          showFontSize: true,
          showColorButton: false,
          showBoldButton: false,
          showItalicButton: false,
          showUnderLineButton: false,
          showStrikeThrough: false,
          showInlineCode: false,
          showSubscript: false,
          showSuperscript: false,
          showBackgroundColorButton: false,
          showClearFormat: false,
          showUndo: false,
          showRedo: false,
          showListNumbers: false,
          showListBullets: false,
          showListCheck: false,
          showCodeBlock: false,
          showQuote: false,
          showIndent: false,
          showLink: false,
          toolbarIconAlignment: WrapAlignment.center,
          showClipboardCopy: false,
          showClipboardCut: false,
          showClipboardPaste: false,
        ),
      )
    );
  }
}
