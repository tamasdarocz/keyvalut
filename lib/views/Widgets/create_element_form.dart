import 'package:flutter/material.dart';
import 'package:keyvalut/views/Widgets/textforms/custom_divider.dart';
import 'package:keyvalut/views/Widgets/textforms/email_input_field.dart';
import 'package:keyvalut/views/Widgets/textforms/password_text_field.dart';
import 'package:keyvalut/views/Widgets/textforms/title_input_field.dart';
import 'package:keyvalut/views/Widgets/textforms/username_input_field.dart';
import 'package:keyvalut/views/Widgets/textforms/website_input_field.dart';

import '../../data/credential_model.dart';
import '../../data/database_helper.dart';

class CreateElementForm extends StatefulWidget {
  final DatabaseHelper dbHelper;
  final Credential? credential;
  const CreateElementForm({super.key, this.credential, required this.dbHelper});

  @override
  State<CreateElementForm> createState() => _CreateElementFormState();
}

class _CreateElementFormState extends State<CreateElementForm> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController websiteController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.credential != null) {
      titleController.text = widget.credential!.title;
      emailController.text = widget.credential!.email;
      usernameController.text = widget.credential!.username;
      websiteController.text = widget.credential!.website;
      passwordController.text = widget.credential!.password;
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    emailController.dispose();
    usernameController.dispose();
    websiteController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(widget.credential != null ? 'Edit Credential' : 'Create Credential'),
        backgroundColor: Colors.amber,
      ),
      body: ListView(
        padding: EdgeInsets.all(8),
        children: [
          CustomDivider(),
          TitleInputField(controller: titleController),
          CustomDivider(),
          EmailInputField(controller: emailController),
          CustomDivider(),
          UsernameInputField(controller: usernameController),
          CustomDivider(),
          WebsiteInputField(controller: websiteController),
          CustomDivider(),
          PasswordManager(controller: passwordController),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isEmpty ||
                  usernameController.text.isEmpty ||
                  passwordController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please fill in all required fields')),
                );
                return;
              }
              final credential = Credential(
                id: widget.credential?.id, // Include ID for updates
                title: titleController.text,
                username: usernameController.text,
                password: passwordController.text,
                website: websiteController.text,
                email: emailController.text,
              );
              if (widget.credential != null) {
                await widget.dbHelper.updateCredential(credential);
                // Update existing
              } else {
                await widget.dbHelper.insertCredential(credential); // Create new
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.yellow,
              foregroundColor: Colors.black,
            ),
            child: Text(widget.credential != null ? 'Update' : 'Save'),
          )
        ],
      ),
    );
  }
}