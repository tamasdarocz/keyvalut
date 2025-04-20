class Credential {
  final int? id;
  final String title;
  final String? website;
  final String? email;
  final String username;
  final String password;
  final String? totpSecret;
  final bool isArchived;
  final bool isDeleted;
  final String? archivedAt;
  final String? deletedAt;

  Credential({
    this.id,
    required this.title,
    this.website,
    this.email,
    required this.username,
    required this.password,
    this.totpSecret,
    this.isArchived = false,
    this.isDeleted = false,
    this.archivedAt,
    this.deletedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'website': website,
      'email': email,
      'username': username,
      'password': password,
      'totpSecret': totpSecret,
      'is_archived': isArchived ? 1 : 0,
      'is_deleted': isDeleted ? 1 : 0,
      'archived_at': archivedAt,
      'deleted_at': deletedAt,
    };
  }

  factory Credential.fromMap(Map<String, dynamic> map) {
    return Credential(
      id: map['id'],
      title: map['title'],
      website: map['website'],
      email: map['email'],
      username: map['username'],
      password: map['password'],
      totpSecret: map['totpSecret'],
      isArchived: map['is_archived'] == 1,
      isDeleted: map['is_deleted'] == 1,
      archivedAt: map['archived_at'],
      deletedAt: map['deleted_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'website': website,
      'email': email,
      'username': username,
      'password': password,
      'totpSecret': totpSecret,
      'isArchived': isArchived,
      'isDeleted': isDeleted,
      'archivedAt': archivedAt,
      'deletedAt': deletedAt,
    };
  }

  factory Credential.fromJson(Map<String, dynamic> json) {
    return Credential(
      id: json['id'],
      title: json['title'] as String,
      website: json['website'] as String?,
      email: json['email'] as String?,
      username: json['username'] as String,
      password: json['password'] as String,
      totpSecret: json['totpSecret'] as String?,
      isArchived: json['isArchived'] as bool? ?? false,
      isDeleted: json['isDeleted'] as bool? ?? false,
      archivedAt: json['archivedAt'] as String?,
      deletedAt: json['deletedAt'] as String?,
    );
  }

  Map<String, dynamic> toExportJson() {
    return {
      'title': title,
      'website': website,
      'email': email,
      'username': username,
      'password': password,
      'totpSecret': totpSecret,
      'isArchived': isArchived,
      'isDeleted': isDeleted,
      'archivedAt': archivedAt,
      'deletedAt': deletedAt,
    };
  }
}

class CreditCard {
  final int? id;
  final String title;
  final String? bank_name;
  final String ch_name;
  final String card_number;
  final String expiry_date;
  final String cvv;
  final String? card_type;
  final String? billing_address;
  final String? notes;
  final bool isArchived;
  final String? archivedAt;
  final bool isDeleted;
  final String? deletedAt;

  CreditCard({
    this.id,
    required this.title,
    this.bank_name,
    required this.ch_name,
    required this.card_number,
    required this.expiry_date,
    required this.cvv,
    this.card_type,
    this.billing_address,
    this.notes,
    this.isArchived = false,
    this.archivedAt,
    this.isDeleted = false,
    this.deletedAt,
  });

  // Getters to match the names expected by the UI
  String get cardholderName => ch_name;
  String get cardNumber => card_number;
  String get expiryDate => expiry_date;
  String get cardType => card_type ?? '';
  String get billingAddress => billing_address ?? '';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'bank_name': bank_name,
      'ch_name': ch_name,
      'card_number': card_number,
      'expiry_date': expiry_date,
      'cvv': cvv,
      'card_type': card_type,
      'billing_address': billing_address,
      'notes': notes,
      'is_archived': isArchived ? 1 : 0,
      'archived_at': archivedAt,
      'is_deleted': isDeleted ? 1 : 0,
      'deleted_at': deletedAt,
    };
  }

  factory CreditCard.fromMap(Map<String, dynamic> map) {
    return CreditCard(
      id: map['id'],
      title: map['title'],
      bank_name: map['bank_name'],
      ch_name: map['ch_name'],
      card_number: map['card_number'],
      expiry_date: map['expiry_date'],
      cvv: map['cvv'],
      card_type: map['card_type'],
      billing_address: map['billing_address'],
      notes: map['notes'],
      isArchived: map['is_archived'] == 1,
      archivedAt: map['archived_at'],
      isDeleted: map['is_deleted'] == 1,
      deletedAt: map['deleted_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'bank_name': bank_name,
      'ch_name': ch_name,
      'card_number': card_number,
      'expiry_date': expiry_date,
      'cvv': cvv,
      'card_type': card_type,
      'billing_address': billing_address,
      'notes': notes,
      'isArchived': isArchived,
      'archivedAt': archivedAt,
      'isDeleted': isDeleted,
      'deletedAt': deletedAt,
    };
  }

  factory CreditCard.fromJson(Map<String, dynamic> json) {
    return CreditCard(
      id: json['id'],
      title: json['title'] as String,
      bank_name: json['bank_name'] as String?,
      ch_name: json['ch_name'] as String,
      card_number: json['card_number'] as String,
      expiry_date: json['expiry_date'] as String,
      cvv: json['cvv'] as String,
      card_type: json['card_type'] as String?,
      billing_address: json['billing_address'] as String?,
      notes: json['notes'] as String?,
      isArchived: json['isArchived'] as bool? ?? false,
      archivedAt: json['archivedAt'] as String?,
      isDeleted: json['isDeleted'] as bool? ?? false,
      deletedAt: json['deletedAt'] as String?,
    );
  }

  Map<String, dynamic> toExportJson() {
    return {
      'title': title,
      'bank_name': bank_name,
      'ch_name': ch_name,
      'card_number': card_number,
      'expiry_date': expiry_date,
      'cvv': cvv,
      'card_type': card_type,
      'billing_address': billing_address,
      'notes': notes,
      'isArchived': isArchived,
      'archivedAt': archivedAt,
      'isDeleted': isDeleted,
      'deletedAt': deletedAt,
    };
  }
}

class Note {
  final int? id;
  final String title;
  final String content;
  final bool isArchived;
  final String? archivedAt;
  final bool isDeleted;
  final String? deletedAt;

  Note({
    this.id,
    required this.title,
    required this.content,
    this.isArchived = false,
    this.archivedAt,
    this.isDeleted = false,
    this.deletedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'is_archived': isArchived ? 1 : 0,
      'archived_at': archivedAt,
      'is_deleted': isDeleted ? 1 : 0,
      'deleted_at': deletedAt,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      isArchived: map['is_archived'] == 1,
      archivedAt: map['archived_at'],
      isDeleted: map['is_deleted'] == 1,
      deletedAt: map['deleted_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'isArchived': isArchived,
      'archivedAt': archivedAt,
      'isDeleted': isDeleted,
      'deletedAt': deletedAt,
    };
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'],
      title: json['title'] as String,
      content: json['content'] as String,
      isArchived: json['isArchived'] as bool? ?? false,
      archivedAt: json['archivedAt'] as String?,
      isDeleted: json['isDeleted'] as bool? ?? false,
      deletedAt: json['deletedAt'] as String?,
    );
  }

  Map<String, dynamic> toExportJson() {
    return {
      'title': title,
      'content': content,
      'isArchived': isArchived,
      'archivedAt': archivedAt,
      'isDeleted': isDeleted,
      'deletedAt': deletedAt,
    };
  }
}