class AppUser {
  final String username;
  final String password;
  String role; // 'admin', 'content_manager', 'member'

  AppUser({
    required this.username,
    required this.password,
    required this.role,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'role': role,
    };
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      username: json['username'] as String,
      password: json['password'] as String,
      role: json['role'] as String,
    );
  }
}
