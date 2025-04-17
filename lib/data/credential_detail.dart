import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:keyvalut/views/Widgets/textforms/custom_divider.dart';
import 'package:provider/provider.dart';
import '../services/url_service.dart';
import '../views/Widgets/textforms/password_text_field.dart';
import 'credentialProvider.dart';
import 'credential_model.dart';
import 'database_helper.dart';

class CredentialDetail extends StatefulWidget {
  final Credential credential;

  const CredentialDetail({super.key, required this.credential});

  @override
  State<CredentialDetail> createState() => _CredentialDetailState();
}

class _CredentialDetailState extends State<CredentialDetail> {
  late final TextEditingController _titleController;
  late final TextEditingController _websiteController;
  late final TextEditingController _emailController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.credential.title);
    _websiteController = TextEditingController(text: widget.credential.website);
    _emailController = TextEditingController(text: widget.credential.email);
    _usernameController = TextEditingController(
      text: widget.credential.username,
    );
    _passwordController = TextEditingController(
      text: widget.credential.password,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _websiteController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isEditing = false;

  Widget _buildEditableField(Widget child) {
    return _isEditing
        ? child
        : AbsorbPointer(
      child: child,
    ); // Make fields uneditable when not in edit mode
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(widget.credential.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, size: 40, color: Colors.black),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Credential'),
                  content: const Text('Are you sure you want to delete?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirmed == true && widget.credential.id != null) {
                await DatabaseHelper.instance.deleteCredential(
                  widget.credential.id!,
                );
                Navigator.pop(context); // Return to list screen
              }
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: ListView(
            children: [
              // Title Field
              Column(
                children: [
                  Row(
                    children: [
                      const CustomDivider(),
                      Expanded(
                        child: _buildEditableField(
                          TextFormField(
                            controller: _titleController,
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.devices),
                              hintText: 'Required',
                              labelText: 'Title',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(48),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a title';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.copy, color: Theme.of(context).colorScheme.primary,),
                        iconSize: 20,
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: widget.credential.username),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Center(child: Text('Copied!'))),
                          );
                        },
                      ),
                    ],
                  ),
                  const CustomDivider(),
                ],
              ),

              // Website Field
              if (_isEditing ||
                  (widget.credential.website?.isNotEmpty ?? false)) ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildEditableField(
                        TextFormField(
                          controller: _websiteController,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.http),
                            labelText: 'Website',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(48),
                            ),
                          ),
                          keyboardType: TextInputType.url,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.open_in_browser, color: Theme.of(context).colorScheme.primary),
                      onPressed: () {
                        UrlService.launchWebsite(
                            context: context,
                            url: widget.credential.website);
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.copy, color: Theme.of(context).colorScheme.primary),
                      iconSize: 20,
                      onPressed: () {
                        if (widget.credential.website?.isNotEmpty ?? false) {
                          Clipboard.setData(
                            ClipboardData(text: _websiteController.text),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Center(child: Text('Copied!'))),
                          );
                        }
                      },
                    ),
                  ],
                ),
                const CustomDivider(),
              ],

              // Email Field
              if (_isEditing ||
                  (widget.credential.email?.isNotEmpty ?? false)) ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildEditableField(
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.email),
                            labelText: 'Email',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(48),
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value?.isEmpty ?? true) return null;
                            if (!RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            ).hasMatch(value!)) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.copy, color: Theme.of(context).colorScheme.primary),
                      iconSize: 20,
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: _emailController.text),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Center(child: Text('Copied!'))),
                        );
                      },
                    ),
                  ],
                ),
                const CustomDivider(),
              ],

              // Username Field
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildEditableField(
                          TextFormField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              labelText: 'Username',
                              hintText: 'Required',
                              prefixIcon: Icon(Icons.person),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(48),
                              ),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.copy, color: Theme.of(context).colorScheme.primary,),
                        iconSize: 20,
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: widget.credential.username),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Center(child: Text('Copied!'))),
                          );
                        },
                      ),
                    ],
                  ),
                  const CustomDivider(),
                ],
              ),

              // Password Field
              Column(
                children: [
                  if (_isEditing) ...[
                    PasswordManager(controller: _passwordController),
                    const SizedBox(height: 16),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            readOnly: true,
                            obscureText: _obscurePassword,
                            controller: _passwordController,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.key),
                              hintText: 'Required',
                              labelText: 'Password',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(48),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            color: Theme.of(context).colorScheme.primary,
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        IconButton(
                          icon: Icon(Icons.copy, color: Theme.of(context).colorScheme.primary,),
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: widget.credential.password),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Password copied')),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                  const CustomDivider(),
                ],
              ),
              if (_isEditing) ...[
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final updatedCredential = Credential(
                        id: widget.credential.id,
                        title: _titleController.text,
                        website: _websiteController.text.isNotEmpty
                            ? _websiteController.text
                            : null,
                        email: _emailController.text,
                        username: _usernameController.text,
                        password: _passwordController.text,
                      );

                      final provider = Provider.of<CredentialProvider>(
                        context,
                        listen: false,
                      );
                      await provider.updateCredential(updatedCredential);
                      setState(() => _isEditing = false); // Exit edit mode
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Update'),
                ),
              ],
            ],
          ),
        ),
      ),
      floatingActionButton: _isEditing
          ? null
          : FloatingActionButton(
            heroTag: 'editbutton',
        backgroundColor: Theme.of(context).colorScheme.primary,
        onPressed: () {
          setState(() => _isEditing = true);
        },
        child: const Icon(Icons.edit),
      ),
    );
  }
}