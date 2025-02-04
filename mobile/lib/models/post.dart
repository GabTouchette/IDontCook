import 'package:freezed_annotation/freezed_annotation.dart';
import 'user.dart';

part 'post.freezed.dart';
part 'post.g.dart';

@freezed
class Post with _$Post {
  factory Post({
    required int id,
    required User user,
    int? recipe_id,
    String? recipe_title,
    String? recipe_description,
    String? recipe_image_url,
    String? content,
    DateTime? created_at,
    DateTime? updated_at,
    @Default(0) int upvote_count,
    @Default(0) int downvote_count,
  }) = _Post;

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
}
