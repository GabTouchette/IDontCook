import 'package:freezed_annotation/freezed_annotation.dart';
import 'user.dart';
import 'post.dart';

part 'vote.freezed.dart';
part 'vote.g.dart';

@freezed
class Vote with _$Vote {
  factory Vote({
    required int id,
    required User user,
    required Post post,
    required bool is_upvote,
    DateTime? created_at
  }) = _Vote;

  factory Vote.fromJson(Map<String, dynamic> json) => _$VoteFromJson(json);
}
