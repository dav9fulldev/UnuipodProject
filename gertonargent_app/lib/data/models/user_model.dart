class UserModel {
  final int id;
  final String? firstName;
  final String email;
  final String username;
  final String phone;
  final bool isActive;

  UserModel({
    required this.id,
    this.firstName,
    required this.email,
    required this.username,
    required this.phone,
    this.isActive = true,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      firstName: json['first_name'] ?? json['firstName'],
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      phone: json['phone'] ?? '',
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'email': email,
      'username': username,
      'phone': phone,
      'is_active': isActive,
    };
  }

  UserModel copyWith({
    int? id,
    String? firstName,
    String? email,
    String? username,
    String? phone,
    bool? isActive,
  }) {
    return UserModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      email: email ?? this.email,
      username: username ?? this.username,
      phone: phone ?? this.phone,
      isActive: isActive ?? this.isActive,
    );
  }
}
