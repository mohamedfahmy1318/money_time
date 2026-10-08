import 'package:mony_time/src/features/auth/domain/entities/user.dart';

/// Data-layer representation of [AppUser] with JSON mapping.
///
/// The domain entity stays free of `fromJson`/`toJson` — only models
/// know about the API shape.
class UserModel extends AppUser {
  const UserModel({
    required super.id,
    required super.email,
    super.name,
    super.photoUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Some endpoints wrap the payload: { "user": { ... } }
    final data = (json['user'] as Map<String, dynamic>?) ?? json;

    return UserModel(
      id: data['id']?.toString() ?? '',
      email: data['email'] as String? ?? '',
      name: data['name'] as String?,
      photoUrl: (data['photo_url'] ?? data['photoUrl']) as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'photo_url': photoUrl,
      };
}
