import 'package:freezed_annotation/freezed_annotation.dart';
import 'user.dart';
import 'post.dart';

part 'comment.freezed.dart';
part 'comment.g.dart';

@freezed
class Comment with _$Comment {
  factory Comment({
    required int id,
    required User user,
    required Post post,
    required String content,
    required DateTime createdAt,
  }) = _Comment;

  factory Comment.fromJson(Map<String, dynamic> json) => _$CommentFromJson(json);
}
