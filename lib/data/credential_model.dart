
class Credential {
  final int? id;
  final String title;
  final String? website;
  final String? email;
  final String username;
  final String password;

  Credential({
    this.id,
    required this.title,
    this.website,
    this.email,
    required this.username,
    required this.password,
  });

  // Convert a Credential into a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'website': website,
      'email': email,
      'username': username,
      'password': password,
    };
  }

  // Convert a Map into a Credential
  factory Credential.fromMap(Map<String, dynamic> map) {
    return Credential(
      id: map['id'],
      title: map['title'],
      website: map['website'],
      email: map['email'],
      username: map['username'],
      password: map['password'],
    );
  }
}