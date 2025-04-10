import 'package:flutter/material.dart';
import 'package:keyvalut/views/Tabs/first_tab.dart';
import 'package:keyvalut/views/Widgets/textforms/custom_divider.dart';
import 'package:keyvalut/views/Widgets/textforms/email_input_field.dart';
import 'package:keyvalut/views/Widgets/textforms/password_text_field.dart';
import 'package:keyvalut/views/Widgets/textforms/platform_input_field.dart';
import 'package:keyvalut/views/Widgets/textforms/username_input_field.dart';
import 'package:keyvalut/views/Widgets/textforms/website_input_field.dart';

class CreateElementForm extends StatefulWidget {
  const CreateElementForm({super.key});

  @override
  State<CreateElementForm> createState() => _CreateElementFormState();
}

class _CreateElementFormState extends State<CreateElementForm> {
  final TextEditingController TitleController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController websiteController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks
    TitleController.dispose();
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
        title: Text('Create New'),
        backgroundColor: Colors.amber,
      ),
      body: ListView(
        padding: EdgeInsets.all(8),
        children: [
          CustomDivider(),
          TitleInputField(controller: TitleController),
          CustomDivider(),
          EmailInputField(controller: emailController),
          CustomDivider(),
          UsernameInputField(controller: usernameController),
          CustomDivider(),
          WebsiteInputField(controller: websiteController),
          CustomDivider(),
          PasswordManager(controller: passwordController),
          const SizedBox(height: 16), // Add spacing before the button
          ElevatedButton(
            onPressed: () { Navigator.pop(this.context);
            },

            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.yellow,
              foregroundColor: Colors.black,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
