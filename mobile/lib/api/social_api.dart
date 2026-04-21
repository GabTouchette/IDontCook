import 'package:i_cant_cook/api/api_helper.dart';
import 'package:i_cant_cook/models/paginated_posts/paginated_posts.dart';
import 'package:i_cant_cook/models/post/post.dart';
import 'package:i_cant_cook/models/comment/comment.dart';
import 'package:i_cant_cook/models/like/like.dart';
import 'package:i_cant_cook/models/recipe/recipe.dart';
import 'package:i_cant_cook/models/user/user.dart';
import 'package:i_cant_cook/models/vote/vote.dart';

class SocialApi {
  final ApiHelper _apiHelper = ApiHelper();

  // Fetch paginated posts
  Future<PaginatedPosts> fetchPosts(
      {required int page, required String category}) async {
    String url = 'social/posts/?page=$page&category=$category';
    var data = await _apiHelper.getRequest(url);

    if (data != null) {
      return PaginatedPosts.fromJson(data);
    }

    return PaginatedPosts(count: 0, results: []);
  }

  // Create a new post
  Future<bool> createPost(Map<String, dynamic> postData) async {
    var response = await _apiHelper.postRequest('social/posts/', postData);
    return response != null;
  }

  // Get post details by ID
  Future<Post> getPostById(int postId) async {
    var data = await _apiHelper.getRequest('social/posts/$postId/');
    return Post.fromJson(data);
  }

  // Delete a post
  Future<bool> deletePost(int postId) async {
    return await _apiHelper.deleteRequest('social/posts/$postId/');
  }

  // Fetch all comments for a post
  Future<List<Comment>> fetchComments(int postId) async {
    var data = await _apiHelper.getRequest('social/posts/$postId/comments/');
    if (data != null) {
      return (data as List)
          .map((comment) => Comment.fromJson(comment))
          .toList();
    }
    return [];
  }

  // Create a new comment for a post
  Future<bool> createComment(
      Map<String, dynamic> commentData, int postId) async {
    var response = await _apiHelper.postRequest(
        'social/posts/$postId/comments/', commentData);
    return response != null;
  }

  // Delete a comment
  Future<bool> deleteComment(int commentId) async {
    return await _apiHelper.deleteRequest('social/comments/$commentId/');
  }

  // Fetch all likes for a post
  Future<List<Like>> fetchLikes(int postId) async {
    var data = await _apiHelper.getRequest('social/posts/$postId/likes/');
    if (data != null) {
      return (data as List).map((like) => Like.fromJson(like)).toList();
    }
    return [];
  }

  // Create a like for a post
  Future<bool> createLike(Map<String, dynamic> likeData, int postId) async {
    var response =
        await _apiHelper.postRequest('social/posts/$postId/like/', likeData);
    return response != null;
  }

  // Delete a like for a post
  Future<bool> deleteLike(int postId) async {
    return await _apiHelper.deleteRequest('social/posts/$postId/like/delete/');
  }

  // Fetch all votes for a post
  Future<List<Vote>> fetchVotes(int postId) async {
    var data = await _apiHelper.getRequest('social/posts/$postId/votes/');
    if (data != null) {
      return (data as List).map((vote) => Vote.fromJson(vote)).toList();
    }
    return [];
  }

  // Create a vote (upvote/downvote) for a post
  Future<bool> createVote(int postId, Map<String, dynamic> voteData) async {
    var response =
        await _apiHelper.postRequest('social/posts/$postId/vote/', voteData);
    return response != null;
  }

  // Delete a vote for a post
  Future<bool> deleteVote(int postId) async {
    return await _apiHelper.deleteRequest('social/posts/$postId/vote/delete/');
  }

  Future<List<User>> searchUsers(String query) async {
    var data = await _apiHelper.getRequest('social/users/search/?q=$query');

    return data != null
        ? (data as List).map((user) => User.fromJson(user)).toList()
        : [];
  }

  Future<User?> fetchUserInfo(int userId) async {
    var data = await _apiHelper.getRequest('social/users/$userId/');
    if (data != null) {
      return User.fromJson(data);
    }
    return null;
  }

  Future<List<Recipe>> fetchUserRecipes(int userId) async {
    var data = await _apiHelper.getRequest('social/users/$userId/recipes/');
    if (data != null) {
      return (data as List).map((recipe) => Recipe.fromJson(recipe)).toList();
    }
    return [];
  }

  Future<List<Post>> fetchUserPosts(int userId) async {
    var data = await _apiHelper.getRequest('social/users/$userId/posts/');
    if (data != null) {
      return (data as List).map((post) => Post.fromJson(post)).toList();
    }
    return [];
  }

  Future<bool> createFollow(int userId) async {
    var response =
        await _apiHelper.postRequest('social/users/$userId/follow/', {});
    return response != null;
  }

  Future<bool> deleteFollow(int userId) async {
    return await _apiHelper
        .deleteRequest('social/users/$userId/follow/delete/');
  }

  Future<bool> isUserFollowing(int userId) async {
    var response =
        await _apiHelper.getRequest('social/users/$userId/is_following/');
    if (response != null && response.containsKey('is_following')) {
      return response['is_following'];
    }
    return false;
  }

  // Recipe rating methods
  Future<bool> createRecipeRating(int recipeId, Map<String, dynamic> ratingData) async {
    var response = await _apiHelper.postRequest('recipes/$recipeId/rating/', ratingData);
    return response != null;
  }

  Future<bool> deleteRecipeRating(int recipeId) async {
    return await _apiHelper.deleteRequest('recipes/$recipeId/rating/delete/');
  }

  Future<Map<String, dynamic>?> fetchRecipeRating(int recipeId) async {
    var data = await _apiHelper.getRequest('recipes/$recipeId/rating/');
    return data;
  }
}
