class User {
  final String id;
  final String bilkentId;
  final String name;
  final String surname;
  final String email;
  final String password;
  final String role;
  final String createdAt;
  final String updatedAt;

  User({
    required this.id,
    required this.bilkentId,
    required this.name,
    required this.surname,
    required this.email,
    required this.password,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  // Map'e dönüştürme
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bilkent_id': bilkentId,
      'name': name,
      'surname': surname,
      'email': email,
      'password': password,
      'role': role,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  // Map'ten nesneye dönüştürme
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      bilkentId: map['bilkent_id'],
      name: map['name'],
      surname: map['surname'],
      email: map['email'],
      password: map['password'],
      role: map['role'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }
}
