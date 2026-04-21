import 'package:flutter/material.dart';
import 'package:i_cant_cook/api/social_api.dart';
import 'package:i_cant_cook/models/post/post.dart';

mixin PostMixin on ChangeNotifier {
  List<Post> _posts = [];

  List<Post> get posts => _posts;

  Future<void> handleRecipeVote(int postId, int recipeId, int voteValue) async {
    final postIndex = _posts.indexWhere((post) => post.id == postId);
    if (postIndex == -1) return;

    final post = _posts[postIndex];
    final currentVote = post.user_recipe_vote ?? 0;
    final newVote = currentVote == voteValue ? 0 : voteValue;

    final success = await SocialApi().createRecipeRating(recipeId, {"value": newVote});
    if (success) {
      final currentThumbsUp = post.recipe_thumbs_up_count ?? 0;
      final currentThumbsDown = post.recipe_thumbs_down_count ?? 0;
      
      final updatedPost = post.copyWith(
        user_recipe_vote: newVote,
        recipe_thumbs_up_count: currentThumbsUp +
            (newVote == 1 ? 1 : 0) -
            (currentVote == 1 ? 1 : 0),
        recipe_thumbs_down_count: currentThumbsDown +
            (newVote == -1 ? 1 : 0) -
            (currentVote == -1 ? 1 : 0),
      );

      _posts[postIndex] = updatedPost;
      notifyListeners();
    }
  }

  // Keep old method for backward compatibility during migration
  Future<void> handleVote(int postId, int voteValue) async {
    final postIndex = _posts.indexWhere((post) => post.id == postId);
    if (postIndex == -1) return;

    final post = _posts[postIndex];
    final currentVote = post.user_vote;
    final newVote = currentVote == voteValue ? 0 : voteValue;

    final success = await SocialApi().createVote(postId, {"value": newVote});
    if (success) {
      final updatedPost = post.copyWith(
        user_vote: newVote,
        upvote_count: post.upvote_count +
            (newVote == 1 ? 1 : 0) -
            (currentVote == 1 ? 1 : 0),
        downvote_count: post.downvote_count +
            (newVote == -1 ? 1 : 0) -
            (currentVote == -1 ? 1 : 0),
      );

      _posts[postIndex] = updatedPost;
      notifyListeners();
    }
  }

  Future<void> toggleLike(int userId, int postId) async {
    final postIndex = _posts.indexWhere((post) => post.id == postId);
    if (postIndex == -1) return;

    final post = _posts[postIndex];
    final isLiked = post.user_liked;

    final success = isLiked
        ? await SocialApi().deleteLike(postId)
        : await SocialApi().createLike(
            {"user": userId, "post": postId, "comment": null}, postId);

    if (success) {
      final updatedPost = post.copyWith(
        user_liked: !isLiked,
        like_count: post.like_count + (isLiked ? -1 : 1),
      );

      _posts[postIndex] = updatedPost;
      notifyListeners();
    }
  }

  void incrementCommentCount(int postId) {
    final post = _posts.firstWhere((post) => post.id == postId);
    final updatedPost = post.copyWith(comment_count: post.comment_count + 1);
    _posts[_posts.indexWhere((p) => p.id == postId)] = updatedPost;
    notifyListeners();
  }

  void addPosts(List<Post> newPosts) {
    _posts.addAll(newPosts);
    notifyListeners();
  }

  void clearPosts() {
    _posts.clear();
    notifyListeners();
  }

  void refresh() {}
}
