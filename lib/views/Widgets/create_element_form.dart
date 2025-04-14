import 'package:flutter/material.dart';
import 'package:keyvalut/views/Widgets/textforms/custom_divider.dart';
import 'package:keyvalut/views/Widgets/textforms/email_input_field.dart';
import 'package:keyvalut/views/Widgets/textforms/password_text_field.dart';
import 'package:keyvalut/views/Widgets/textforms/title_input_field.dart';
import 'package:keyvalut/views/Widgets/textforms/username_input_field.dart';
import 'package:keyvalut/views/Widgets/textforms/website_input_field.dart';
import 'package:provider/provider.dart';

import '../../data/credentialProvider.dart';
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
      usernameController.text = widget.credential!.username;
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

  bool get _isValid {
    return titleController.text.isNotEmpty &&
        usernameController.text.isNotEmpty &&
        passwordController.text.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(widget.credential != null ? 'Edit Credential' : 'Create Credential'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: ListView(
        padding: EdgeInsets.all(8),
        children: [
          CustomDivider(),
          TitleInputField(controller: titleController),
          CustomDivider(),
          WebsiteInputField(controller: websiteController),
          CustomDivider(),
          EmailInputField(controller: emailController),
          CustomDivider(),
          UsernameInputField(controller: usernameController),
          CustomDivider(),
          PasswordManager(controller: passwordController),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              if (!_isValid) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill in all required fields'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }


              final credential = Credential(
                id: widget.credential?.id,
                title: titleController.text,
                username: usernameController.text,
                password: passwordController.text,
                website: websiteController.text,
                email: emailController.text.isNotEmpty ? emailController.text : null,
              );

              final provider = Provider.of<CredentialProvider>(context, listen: false);

              try {
                if (widget.credential != null) {
                  await provider.updateCredential(credential);
                } else {
                  await provider.addCredential(credential);
                }
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.primary
            ),
            child: Text(widget.credential != null ? 'Update' : 'Save'),
          )
        ],
      ),
    );
  }
}