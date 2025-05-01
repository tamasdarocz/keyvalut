import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:keyvalut/views/Widgets/custom_divider.dart';
import 'package:keyvalut/views/textforms/email_input_field.dart';
import 'package:keyvalut/views/textforms/password_text_field.dart';
import 'package:keyvalut/views/textforms/phone_number_input_field.dart';
import 'package:keyvalut/views/textforms/title_input_field.dart';
import 'package:keyvalut/views/textforms/totp_secret_input_field.dart';
import 'package:keyvalut/views/textforms/username_input_field.dart';
import 'package:keyvalut/views/textforms/website_input_field.dart';
import 'package:provider/provider.dart';
import '../../data/database_model.dart';
import '../../data/database_helper.dart';
import '../../data/database_provider.dart';
import 'billing_adress_input_form.dart';
import 'date_picker.dart';

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
  final TextEditingController totpSecretController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  DateTime? _selectedBillingDate;

  final _billingAddressKey = GlobalKey<BillingAddressInputState>();

  @override
  void initState() {
    super.initState();
    if (widget.login != null) {
      titleController.text = widget.login!.title;
      usernameController.text = widget.login!.username;
      passwordController.text = widget.login!.password;
      if (widget.login!.email != null) {
        emailController.text = widget.login!.email!;
      }
      if (widget.login!.website != null) {
        websiteController.text = widget.login!.website!;
      }
      if (widget.login!.totpSecret != null) {
        totpSecretController.text = widget.login!.totpSecret!;
      }
      if (widget.login!.phoneNumber != null) {
        phoneController.text = widget.login!.phoneNumber!;
      }
      if (widget.login!.billingAddress != null) {
        // BillingAddressInput will handle its own initialization
      }
      // Parse the billing date if it exists (assumed to be stored in a separate field or derived)
      // For now, we'll assume billing date is not stored in the model yet; we'll add it later if needed
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    emailController.dispose();
    usernameController.dispose();
    websiteController.dispose();
    passwordController.dispose();
    totpSecretController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  bool get _isValid {
    return titleController.text.isNotEmpty &&
        usernameController.text.isNotEmpty &&
        passwordController.text.isNotEmpty &&
        phoneController.text.isNotEmpty &&
        _selectedBillingDate != null;
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
        padding: const EdgeInsets.all(8),
        children: [
          const CustomDivider(),
          TitleInputField(controller: titleController),
          const CustomDivider(),
          WebsiteInputField(controller: websiteController),
          const CustomDivider(),
          EmailInputField(controller: emailController),
          const CustomDivider(),
          PhoneNumberInput(
            labelText: 'Phone Number',
            initialPhone: widget.login?.phoneNumber,
            onPhoneChanged: (phone) {
              phoneController.text = phone ?? '';
            },
          ),
          const CustomDivider(),
          UsernameInputField(controller: usernameController),
          const CustomDivider(),
          PasswordManager(controller: passwordController),
          const CustomDivider(),
          TotpSecretInputField(controller: totpSecretController),
          const CustomDivider(),
          DatePickerInput(
            labelText: 'Billing Date',
            initialDate: _selectedBillingDate,
            firstDate: DateTime.now().subtract(const Duration(days: 365)), // 1 year ago
            lastDate: DateTime.now().add(const Duration(days: 365 * 10)), // 10 years from now
            onDateChanged: (date) {
              setState(() {
                _selectedBillingDate = date;
              });
            },
          ),
          const CustomDivider(),
          BillingAddressInput(
            key: _billingAddressKey,
            initialAddress: widget.login?.billingAddress,
          ),
          const CustomDivider(),
          ElevatedButton(
            onPressed: () async {
              if (!_isValid) {
                Fluttertoast.showToast(
                  msg: 'Please fill in all required fields',
                  backgroundColor: Colors.red,
                );
                return;
              }

              final login = Logins(
                id: widget.login?.id,
                title: titleController.text,
                username: usernameController.text,
                password: passwordController.text,
                website: websiteController.text.isNotEmpty ? websiteController.text : null,
                email: emailController.text.isNotEmpty ? emailController.text : null,
                totpSecret: totpSecretController.text.isNotEmpty ? totpSecretController.text : null,
                billingAddress: _billingAddressKey.currentState!.getFormattedAddress().isNotEmpty
                    ? _billingAddressKey.currentState!.getFormattedAddress()
                    : null,
                phoneNumber: phoneController.text.isNotEmpty ? phoneController.text : null,
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
                Fluttertoast.showToast(msg: e.toString());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: Text(widget.login != null ? 'Update' : 'Create'),
          ),
        ],
      ),
    );
  }
}