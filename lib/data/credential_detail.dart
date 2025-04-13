import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
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
  }

  @override
  void dispose() {
    _titleController.dispose();
    _websiteController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _launchWebsite() async {
    String url = _websiteController.text;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not launch website')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
        title: Text(widget.credential.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, size: 44, color: Colors.black,),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder:
                    (context) => AlertDialog(
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
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.copy, color: Colors.amber),
                    iconSize: 20,
                    onPressed: () {
                      if (widget.credential.username.isNotEmpty ?? false) { // Use widget.controller
                        Clipboard.setData(
                          ClipboardData(text: widget.credential.username),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Center(child: Text('Copied!')),
                          ),
                        );
                      }
                    },
                  ),
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
              const SizedBox(height: 20),
              if (widget.credential.website?.isNotEmpty ?? false)
                TextFormField(
                  controller: _websiteController,
                  decoration: InputDecoration(
                    labelText: 'Website',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(48)),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.copy, color: Colors.amber),
                          iconSize: 20,
                          onPressed: () {
                            if (widget.credential.username.isNotEmpty ?? false) { // Use widget.controller
                              Clipboard.setData(
                                ClipboardData(text: widget.credential.username),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Center(child: Text('Copied!')),
                                ),
                              );
                            }
                          },
                        ),
                        IconButton(
                      icon: const Icon(Icons.open_in_browser, color: Colors.amber,),
                      onPressed: _launchWebsite,
                    ),

      ],
                    )),
                  readOnly: true,
                  onTap: _launchWebsite,
                ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.copy, color: Colors.amber),
                    iconSize: 20,
                    onPressed: () {
                      if (widget.credential.email?.isNotEmpty ?? false) { // Use widget.controller
                        Clipboard.setData(
                          ClipboardData(text: _emailController.text),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                           SnackBar(
                            content: Center(child: Text('Copied!')),
                          ),
                        );
                      }
                    },
                  ),
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
              const SizedBox(height: 20),
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.copy, color: Colors.amber),
                    iconSize: 20,
                    onPressed: () {
                      if (widget.credential.username.isNotEmpty ?? false) { // Use widget.controller
                        Clipboard.setData(
                          ClipboardData(text: widget.credential.username),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Center(child: Text('Copied!')),
                          ),
                        );
                      }
                    },
                  ),
                  labelText: 'Username',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(48),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      readOnly: true,
                      obscureText: _obscurePassword,
                      controller: TextEditingController(
                        text: widget.credential.password,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(48),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      color: Colors.amber,
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed:
                        () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Colors.amber,),
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
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.amber,
        onPressed: () async {
          if (_formKey.currentState!.validate()) {
            final updatedCredential = Credential(
              id: widget.credential.id,
              title: _titleController.text,
              website: _websiteController.text,
              email: _emailController.text,
              username: _usernameController.text,
              password: widget.credential.password,
            );

            final provider = Provider.of<CredentialProvider>(
              context,
              listen: false,
            );
            await provider.updateCredential(updatedCredential);
            if (mounted) Navigator.pop(context);
          }
        },
        child: const Icon(Icons.save),
      ),
    );
  }
}
