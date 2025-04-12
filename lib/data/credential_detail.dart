import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../views/Widgets/create_element_form.dart';
import 'credential_model.dart';
import 'database_helper.dart';

class CredentialDetail extends StatefulWidget {
  final Credential credential;

  const CredentialDetail({super.key, required this.credential});

  @override
  State<CredentialDetail> createState() => _CredentialDetailState();
}

class _CredentialDetailState extends State<CredentialDetail> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.credential.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
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
                await DatabaseHelper.instance.deleteCredential(widget.credential.id!);
                Navigator.pop(context); // Return to list screen
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailItem('Website', widget.credential.website),
            _buildDetailItem('Email', widget.credential.email),
            _buildDetailItem('Username', widget.credential.username),
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    'Password',
                    _obscurePassword ? '••••••••' : widget.credential.password,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    color: Colors.amber,
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                IconButton(
                  iconSize: 20,
                  color: Colors.amber,
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    if (widget.credential.password.isNotEmpty) {
                      Clipboard.setData(
                        ClipboardData(text: widget.credential.password),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Center(child: Text('Copied!'))),
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateElementForm(
                credential: widget.credential,
                dbHelper: DatabaseHelper.instance,
              ),
            ),
          );
        },
        backgroundColor: Colors.amber,
        child: const Icon(Icons.edit),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 20, color: Colors.black),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}