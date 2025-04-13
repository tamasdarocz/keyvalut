import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'credential_model.dart';
import 'credential_detail.dart';

class CredentialItem extends StatefulWidget {
  final Credential credential;
  const CredentialItem({super.key, required this.credential});

  @override
  State<CredentialItem> createState() => _CredentialItemState();
}

class _CredentialItemState extends State<CredentialItem> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: ListTile(
        title: Text(widget.credential.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((widget.credential.website ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text('Website: ${widget.credential.website}'),
              ),
            if ((widget.credential.email ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text('Email: ${widget.credential.email}'),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text('Username: ${widget.credential.username}'),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Row(
                children: [
                  const Text('Password: '),
                  Text(
                    _obscurePassword ? '••••••••' : widget.credential.password,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: Icon(
                      color: Colors.amber,
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  IconButton(
                    iconSize: 20,
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      if (widget.credential.password.isNotEmpty) {
                        Clipboard.setData(
                          ClipboardData(text: widget.credential.password),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Center(child: Text('Copied!')),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CredentialDetail(credential: widget.credential),
            ),
          );
        },
      ),
    );
  }
}