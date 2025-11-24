class UserModel {
  final int id;
  final String email;
  final String username;
  final String phone;
  final bool isActive;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    required this.phone,
    this.isActive = true,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      phone: json['phone'] ?? '',
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'phone': phone,
      'is_active': isActive,
    };
  }

  UserModel copyWith({
    int? id,
    String? email,
    String? username,
    String? phone,
    bool? isActive,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      phone: phone ?? this.phone,
      isActive: isActive ?? this.isActive,
    );
  }
}
