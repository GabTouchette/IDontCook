import 'package:freezed_annotation/freezed_annotation.dart';
import '../user/user.dart';

part 'comment.freezed.dart';
part 'comment.g.dart';

@freezed
class Comment with _$Comment {
  factory Comment({
    required int id,
    required User user,
    required int post_id,
    required String content,
    required DateTime created_at,
  }) = _Comment;

  factory Comment.fromJson(Map<String, dynamic> json) => _$CommentFromJson(json);
}
