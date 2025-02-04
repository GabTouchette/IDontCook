import 'package:freezed_annotation/freezed_annotation.dart';
import 'user.dart';

part 'follow.freezed.dart';
part 'follow.g.dart';

@freezed
class Follow with _$Follow {
  factory Follow({
    required int id,
    required User user,
    required User followed_user,
    DateTime? created_at
  }) = _Follow;

  factory Follow.fromJson(Map<String, dynamic> json) => _$FollowFromJson(json);
}
