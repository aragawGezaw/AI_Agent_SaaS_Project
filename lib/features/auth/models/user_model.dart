class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String preferredLanguage;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.preferredLanguage,
  });

  // Factory constructor to convert JSON from your backend into a UserModel
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? json['_id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? '',
      preferredLanguage: json['preferred_language'] ?? 'am',
    );
  }

  // Convert UserModel back to JSON if needed
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'preferred_language': preferredLanguage,
    };
  }
}
