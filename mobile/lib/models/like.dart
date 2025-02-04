import 'package:freezed_annotation/freezed_annotation.dart';
import 'user.dart';
import 'post.dart';
import 'comment.dart';

part 'like.freezed.dart';
part 'like.g.dart';

@freezed
class Like with _$Like {
  factory Like({
    required int id,
    required User user,
    Post? post,
    Comment? comment,
    DateTime? created_at
  }) = _Like;

  factory Like.fromJson(Map<String, dynamic> json) => _$LikeFromJson(json);
}
