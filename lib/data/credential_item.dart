import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'credential_model.dart';
import 'credential_detail.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:core';

class CredentialItem extends StatefulWidget {
  final Credential credential;
  const CredentialItem({super.key, required this.credential});

  @override
  State<CredentialItem> createState() => _CredentialItemState();

}

class _CredentialItemState extends State<CredentialItem> {
  bool _obscurePassword = true; // Move inside state class

  Future<void> _launchWebsite(String? url) async {
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Website URL is empty')));
      return;
    }

    String fullUrl = url.trim().toLowerCase();
    if (!fullUrl.startsWith('http://') && !fullUrl.startsWith('https://')) {
      fullUrl = 'https://$fullUrl';
    }

    try {
      final uri = Uri.parse(fullUrl);
      print('Attempting to launch: $fullUrl');

      if (!uri.hasAbsolutePath || uri.host.isEmpty) {
        throw FormatException('Invalid URL');
      }

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Cannot launch: $fullUrl';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to launch URL: ${e.toString()}')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).cardColor,
      margin: const EdgeInsets.all(8.0),
      child: ListTile(
        title: Text(widget.credential.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((widget.credential.website ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: InkWell(
                    onTap: () => _launchWebsite(widget.credential.website),
                    child: Text(
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
                      color: Colors.amber,
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
                    icon: const Icon(Icons.copy, size: 20, color: Colors.amber),
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: widget.credential.password),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Center(child: Text('Copied!'))),
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
              builder:
                  (context) => CredentialDetail(credential: widget.credential),
            ),
          );
        },
      ),
    );
  }
}
