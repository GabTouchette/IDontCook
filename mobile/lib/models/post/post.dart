import 'package:freezed_annotation/freezed_annotation.dart';
import '../user/user.dart';

part 'post.freezed.dart';
part 'post.g.dart';

@freezed
class Post with _$Post {
  factory Post({
    required int id,
    required User user,
    required int user_vote, // Keep for backward compatibility during migration
    required bool user_liked, // Keep for backward compatibility during migration
    required int upvote_count, // Keep for backward compatibility during migration
    required int downvote_count, // Keep for backward compatibility during migration
    required int comment_count,
    required int like_count, // Keep for backward compatibility during migration
    // New recipe rating fields
    int? recipe_thumbs_up_count,
    int? recipe_thumbs_down_count,
    int? user_recipe_vote, // 1 for thumbs up, -1 for thumbs down, 0 for no vote
    int? recipe_id,
    String? recipe_title,
    String? recipe_description,
    String? recipe_thumbnail_url,
    String? content,
    DateTime? created_at,
    DateTime? updated_at,
  }) = _Post;

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
}
