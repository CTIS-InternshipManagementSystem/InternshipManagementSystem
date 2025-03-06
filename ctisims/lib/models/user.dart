class User {
  final String id;
  final String name;
  final String email;
  final String bilkentId;
  final String role;
  final String? supervisorId;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.bilkentId,
    required this.role,
    this.supervisorId,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      bilkentId: map['bilkentId'],
      role: map['role'],
      supervisorId: map['supervisorId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'bilkentId': bilkentId,
      'role': role,
      'supervisorId': supervisorId,
    };
  }
}
