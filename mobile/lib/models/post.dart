import 'package:freezed_annotation/freezed_annotation.dart';
import 'user.dart';

part 'post.freezed.dart';
part 'post.g.dart';

@freezed
class Post with _$Post {
  factory Post({
    required int id,
    required User user,
    required int user_vote,
    required bool user_liked,
    required int upvote_count,
    required int downvote_count,
    required int comment_count,
    required int like_count,
    int? recipe_id,
    String? recipe_title,
    String? recipe_description,
    String? recipe_image_url,
    String? content,
    DateTime? created_at,
    DateTime? updated_at,
  }) = _Post;

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
}
