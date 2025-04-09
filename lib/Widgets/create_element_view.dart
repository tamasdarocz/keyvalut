import 'package:flutter/material.dart';
import 'package:keyvalut/Widgets/textforms/password_text_field.dart';
import 'package:keyvalut/Widgets/textforms/custom_divider.dart';
import 'package:keyvalut/Widgets/textforms/email_input_field.dart';
import 'package:keyvalut/Widgets/textforms/platform_input_field.dart';
import 'package:keyvalut/Widgets/textforms/username_input_field.dart';
import 'package:keyvalut/Widgets/textforms/website_input_field.dart';

class CreateElementForm extends StatefulWidget {
  const CreateElementForm({super.key});

  @override
  State<CreateElementForm> createState() => _CreateElementFormState();
}

class _CreateElementFormState extends State<CreateElementForm> {
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
          PlatformInputField(),
          CustomDivider(),
          EmailInputField(),
          CustomDivider(),
          UsernameInputField(),
          CustomDivider(),
          WebsiteInputField(),
          CustomDivider(),
          PasswordManager(),
        ],
      ),
    );
  }
}
