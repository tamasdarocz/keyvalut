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
import '../textforms/billing_address_input_form.dart';
import '../Widgets/date_picker.dart';
import '../textforms/period_dropdown.dart';
import '../textforms/notification_dropdown.dart';
import 'package:intl/intl.dart';

class CreateLoginsForm extends StatefulWidget {
  final DatabaseHelper dbHelper;
  final Logins? login;
  const CreateLoginsForm({super.key, this.login, required this.dbHelper});

  @override
  State<CreateLoginsForm> createState() => _CreateLoginsFormState();
}

class _CreateLoginsFormState extends State<CreateLoginsForm> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController websiteController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController totpSecretController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final ValueNotifier<DateTime?> _selectedBillingDate = ValueNotifier<DateTime?>(null);
  final ValueNotifier<int?> _selectedCreditCardId = ValueNotifier<int?>(null);
  final ValueNotifier<bool> _isPaidService = ValueNotifier<bool>(false);
  final ValueNotifier<String?> _notificationSetting = ValueNotifier<String?>(null);
  final ValueNotifier<String?> _selectedPeriod = ValueNotifier<String?>(null);

  final _billingAddressKey = GlobalKey<BillingAddressInputState>();
  late Future<List<CreditCard>> _creditCardsFuture;

  @override
  void initState() {
    super.initState();
    _creditCardsFuture = _loadCreditCards();
    if (widget.login != null) {
      titleController.text = widget.login!.title;
      usernameController.text = widget.login!.username;
      passwordController.text = widget.login!.password;
      if (widget.login!.email != null) emailController.text = widget.login!.email!;
      if (widget.login!.website != null) websiteController.text = widget.login!.website!;
      if (widget.login!.totpSecret != null) totpSecretController.text = widget.login!.totpSecret!;
      if (widget.login!.phoneNumber != null) phoneController.text = widget.login!.phoneNumber!;
      if (widget.login!.billingDate != null) {
        _selectedBillingDate.value = DateFormat('dd/MM/yyyy').parse(widget.login!.billingDate!);
        _isPaidService.value = true;
      }
      if (widget.login!.creditCardId != null) _selectedCreditCardId.value = widget.login!.creditCardId;
      _notificationSetting.value = widget.login!.notificationSetting ?? 'Disabled'; // Fallback to 'Disabled'
      _selectedPeriod.value = widget.login!.selectedPeriod ?? 'None'; // Fallback to 'Monthly'
    } else {
      _notificationSetting.value = 'Disabled'; // Default value
      _selectedPeriod.value = 'None'; // Default value
    }
  }

  Future<List<CreditCard>> _loadCreditCards() async {
    final provider = Provider.of<DatabaseProvider>(context, listen: false);
    return provider.creditCards;
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
    _selectedBillingDate.dispose();
    _selectedCreditCardId.dispose();
    _isPaidService.dispose();
    _notificationSetting.dispose();
    _selectedPeriod.dispose();
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
            onPhoneChanged: (phone) => phoneController.text = phone ?? '',
          ),
          const CustomDivider(),
          UsernameInputField(controller: usernameController),
          const CustomDivider(),
          PasswordManager(controller: passwordController),
          const CustomDivider(),
          TotpSecretInputField(controller: totpSecretController),
          const CustomDivider(),
          BillingAddressInput(
            key: _billingAddressKey,
            initialAddress: widget.login?.billingAddress,
          ),
          const CustomDivider(),
          Row(
            children: [
              Flexible(
                flex: 2,
                child: DatePickerInput(
                  labelText: 'Billing Date',
                  initialDate: _selectedBillingDate.value,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                  onDateChanged: (date) => _selectedBillingDate.value = date,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                flex: 2,
                child: PeriodDropdown(periodNotifier: _selectedPeriod),
              ),
            ],
          ),
          const CustomDivider(),
          FutureBuilder<List<CreditCard>>(
            future: _creditCardsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text('Error loading credit cards: ${snapshot.error}');
              } else {
                final creditCards = snapshot.data!;
                return ValueListenableBuilder<int?>(
                  valueListenable: _selectedCreditCardId,
                  builder: (context, creditCardId, child) {
                    return DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.credit_card),
                        labelText: 'Link Credit Card',
                        border: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 1,
                          ),
                        ),
                      ),
                      value: creditCardId,
                      items: [
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Text('None'),
                        ),
                        ...creditCards.map((card) {
                          return DropdownMenuItem<int>(
                            value: card.id,
                            child: Text('${card.title} - ${card.cardNumber.substring(card.cardNumber.length - 4)}'),
                          );
                        }),
                      ],
                      onChanged: (value) => _selectedCreditCardId.value = value,
                    );
                  },
                );
              }
            },
          ),
          const CustomDivider(),
          NotificationDropdown(notificationSetting: _notificationSetting),
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
                billingDate: _selectedBillingDate.value != null
                    ? DateFormat('dd/MM/yyyy').format(_selectedBillingDate.value!)
                    : null,
                creditCardId: _selectedCreditCardId.value,
                notificationSetting: _notificationSetting.value, // Ensure this is set
                selectedPeriod: _selectedPeriod.value, // Ensure this is set
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
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: Text(widget.login != null ? 'Update' : 'Create'),
          ),
        ],
      ),
    );
  }
}