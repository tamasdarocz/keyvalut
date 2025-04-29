import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:keyvalut/views/Widgets/custom_divider.dart';
import 'package:keyvalut/views/textforms/email_input_field.dart';
import 'package:keyvalut/views/textforms/password_text_field.dart';
import 'package:keyvalut/views/textforms/title_input_field.dart';
import 'package:keyvalut/views/textforms/totp_secret_input_field.dart';
import 'package:keyvalut/views/textforms/username_input_field.dart';
import 'package:keyvalut/views/textforms/website_input_field.dart';
import 'package:provider/provider.dart';
import '../../data/database_model.dart';
import '../../data/database_helper.dart';
import '../../data/database_provider.dart';

class CreateElementForm extends StatefulWidget {
  final DatabaseHelper dbHelper;
  final Logins? login;
  const CreateElementForm({super.key, this.login, required this.dbHelper});

  @override
  State<CreateElementForm> createState() => _CreateElementFormState();
}

class _CreateElementFormState extends State<CreateElementForm> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController websiteController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController totpSecretController = TextEditingController(); // Add this controller

  @override
  void initState() {
    super.initState();
    if (widget.login != null) {
      titleController.text = widget.login!.title;
      usernameController.text = widget.login!.username;
      passwordController.text = widget.login!.password;
      // Initialize other fields if they exist
      if (widget.login!.email != null) {
        emailController.text = widget.login!.email!;
      }
      if (widget.login!.website != null) {
        websiteController.text = widget.login!.website!;
      }
      if (widget.login!.totpSecret != null) {
        totpSecretController.text = widget.login!.totpSecret!;
      }
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    emailController.dispose();
    usernameController.dispose();
    websiteController.dispose();
    passwordController.dispose();
    totpSecretController.dispose(); // Dispose the new controller
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
        title: Text(widget.login != null ? 'Edit login' : 'Create login'),
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
          CustomDivider(),
          TotpSecretInputField(controller: totpSecretController),
          CustomDivider(),
          ElevatedButton(
            onPressed: () async {
              if (!_isValid) {
                Fluttertoast.showToast(msg: 'Please fill in all required fields', backgroundColor: Colors.red);
                return;
              }

              final login = Logins(
                id: widget.login?.id,
                title: titleController.text,
                username: usernameController.text,
                password: passwordController.text,
                website: websiteController.text.isNotEmpty ? websiteController.text : null,
                email: emailController.text.isNotEmpty ? emailController.text : null,
                totpSecret: totpSecretController.text.isNotEmpty ? totpSecretController.text : null, // Add TOTP secret
              );

              final provider = Provider.of<DatabaseProvider>(context, listen: false);

              try {
                if (widget.login != null) {
                  await provider.updateLogin(login);
                } else {
                  await provider.addLogin(login);
                }
                Navigator.pop(context);
              } catch (e) {
                Fluttertoast.showToast(msg:e.toString() );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 50),

            ),
            child: Text(widget.login != null ? 'Update' : 'Create'),
          )

        ],
      ),
    );
  }
}