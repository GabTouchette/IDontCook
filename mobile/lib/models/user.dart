import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class User with _$User {
  const factory User({
    required int id,
    required String username,
    required String email,
    String? token,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  factory User.fromJsonWithUsername(
      Map<String, dynamic> json, String username) {
    return User(
      id: json['id'],
      username: username,
      email: json['email'] ?? '',
      token: json['key'],
    );
  }
}
