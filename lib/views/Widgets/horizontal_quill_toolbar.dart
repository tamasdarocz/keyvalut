import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

class HorizontalQuillToolbar extends StatelessWidget {
  final quill.QuillController controller;

  const HorizontalQuillToolbar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    // Define custom font size options: 0, 2, 4, ..., 36
    final fontSizeOptions = {
      for (var i = 5; i <= 18; i++) (i*2).toString(): (i*2).toString(),
    };

    return SizedBox(
      height: 40,
        child: quill.QuillToolbar.simple(
          controller: controller,
          configurations: quill.QuillSimpleToolbarConfigurations(
            color: Theme.of(context).colorScheme.secondary,
            multiRowsDisplay: false,
            showClipboardCopy: true,
            showClipboardCut: true,
            showClipboardPaste: true,
            showFontFamily: true,
            showFontSize: true,// Enable font size dropdown
            fontSizesValues: fontSizeOptions, // Use custom font size map
            showDividers: false,
            showHeaderStyle: false,
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
            showLineHeightButton: false,
            toolbarIconAlignment: WrapAlignment.center,


          ),
        ),
    );
  }
}