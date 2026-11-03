class UserModel {
  final int? id;
  final String name;
  final String email;
  final String studentId;
  final String password;

  UserModel({
    this.id,
    required this.name,
    required this.email,
    required this.studentId,
    required this.password,
  });

  // Convert UserModel to Map for SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'student_id': studentId,
      'password': password,
    };
  }

  // Create UserModel from SQLite Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      studentId: map['student_id'] ?? '',
      password: map['password'] ?? '',
    );
  }
}

