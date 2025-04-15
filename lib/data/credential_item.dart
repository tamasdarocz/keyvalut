import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/url_service.dart';
import 'credential_model.dart';
import 'credential_detail.dart';
import 'dart:core';

class CredentialItem extends StatefulWidget {
  final Credential credential;
  const CredentialItem({super.key, required this.credential});

  @override
  State<CredentialItem> createState() => _CredentialItemState();
}

class _CredentialItemState extends State<CredentialItem> {
  bool _obscurePassword = true; // Move inside state class

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme
          .of(context)
          .cardColor,
      margin: const EdgeInsets.all(8.0),
      child: ListTile(
        title: Text(widget.credential.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.credential.website?.isNotEmpty ?? false)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: InkWell(
                  onTap: () => UrlService.launchWebsite(
                    context: context,
                    url: widget.credential.website,
                  ),
                  child: Text(
                    style: TextStyle(color: Colors.indigo),
                    'Website: ${widget.credential.website}',
                  ),
                ),
              ),
            if ((widget.credential.email ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('Email: ${widget.credential.email}'),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text('Username: ${widget.credential.username}'),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 0),
                    child: Text('Password: '),
                  ),
                  Expanded(
                    child: Text(
                      _obscurePassword
                          ? '••••••••'
                          : widget.credential.password,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      color:Theme.of(context).colorScheme.secondary,
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                  IconButton(
                    icon: Icon(
                        Icons.copy, size: 20, color:Theme.of(context).colorScheme.secondary),
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: widget.credential.password),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Center(
                            child: Text('Copied!'))),
                      );
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
              builder: (context) =>
                  CredentialDetail(credential: widget.credential),
            ),
          );
        },
      ),
    );
  }
}
