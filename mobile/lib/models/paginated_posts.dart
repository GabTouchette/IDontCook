import 'package:freezed_annotation/freezed_annotation.dart';
import 'post.dart';

part 'paginated_posts.freezed.dart';
part 'paginated_posts.g.dart';

@freezed
class PaginatedPosts with _$PaginatedPosts {
  const factory PaginatedPosts({
    required int count,
    required List<Post> results,
    String? next,
  }) = _PaginatedPosts;

  factory PaginatedPosts.fromJson(Map<String, dynamic> json) =>
      _$PaginatedPostsFromJson(json);
}
