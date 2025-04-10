import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';

// Model class for your credential data
class Credential {
  final int index;
  final String title;
  final String website;
  final String email;
  final String username;
  final String password;

  Credential({
    required this.index,
    required this.title,
    required this.website,
    required this.email,
    required this.username,
    required this.password,
  });
}

// Hardcoded dummy data
final List<Credential> dummyCredentials = [
  Credential(
    index: 0,
    title: "Work Email",
    website: "companyportal.com",
    email: "user@company.com",
    username: "user_123",
    password: "SecurePass!123",
  ),
  Credential(
    index: 1,
    title: "Netflix",
    website: "netflix.com",
    email: "myemail@gmail.com",
    username: "movie_lover",
    password: "Stream2023",
  ),
  Credential(
    index: 2,
    title: "GitHub",
    website: "github.com",
    email: "dev@example.com",
    username: "supercoder",
    password: "GitHubPass!",
  ),
];

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
            if (widget.credential.website.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text('Website: ${widget.credential.website}'),
              ),
            if (widget.credential.email.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text('Email: ${widget.credential.email}'),
              ),
            if (widget.credential.username.isNotEmpty)
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
                    icon: Icon(Icons.copy),
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
              builder:
                  (context) => CredentialDetail(credential: widget.credential),
            ),
          );
        },
      ),
    );
  }
}

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
      appBar: AppBar(title: Text(widget.credential.title)),
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
                  icon: Icon(Icons.copy),
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
      floatingActionButton: FloatingActionButton(onPressed: () {},
          backgroundColor: Colors.amber,
          child: Icon(Icons.edit)),
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

// Database Service Example (Implement according to your database)
class CredentialDatabaseService {
  // Example method - implement according to your database
  Future<List<Credential>> getCredentials() async {
    // Replace with actual database call
    return [];
  }
}

class CredentialsWidget extends StatelessWidget {
  final List<Credential> credentials;

  const CredentialsWidget({super.key, required this.credentials});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: credentials.length,
        itemBuilder: (context, index) {
          final credential = credentials[index];
          return CredentialItem(credential: credential);
        },
      ),
    );
  }
}
