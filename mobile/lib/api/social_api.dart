import 'package:mobile/api/api_helper.dart';
import 'package:mobile/models/post.dart';
import 'package:mobile/models/comment.dart';
import 'package:mobile/models/like.dart';
import 'package:mobile/models/vote.dart';

class SocialApi {
  final ApiHelper _apiHelper = ApiHelper();

  // Fetch all posts
  Future<List<Post>> fetchPosts() async {
    var data = await _apiHelper.getRequest('social/posts/');
    if (data != null) {
      return (data as List).map((post) => Post.fromJson(post)).toList();
    }
    return [];
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
}
