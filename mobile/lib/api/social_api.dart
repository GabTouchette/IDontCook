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

  // Fetch all comments
  Future<List<Comment>> fetchComments() async {
    var data = await _apiHelper.getRequest('social/comments/');
    if (data != null) {
      return (data as List).map((comment) => Comment.fromJson(comment)).toList();
    }
    return [];
  }

  // Create a new comment
  Future<bool> createComment(Map<String, dynamic> commentData) async {
    var response = await _apiHelper.postRequest('social/comments/', commentData);
    return response != null;
  }

  // Delete a comment
  Future<bool> deleteComment(int commentId) async {
    return await _apiHelper.deleteRequest('social/comments/$commentId/');
  }

  // Fetch all likes
  Future<List<Like>> fetchLikes() async {
    var data = await _apiHelper.getRequest('social/likes/');
    if (data != null) {
      return (data as List).map((like) => Like.fromJson(like)).toList();
    }
    return [];
  }

  // Create a like
  Future<bool> createLike(Map<String, dynamic> likeData) async {
    var response = await _apiHelper.postRequest('social/likes/', likeData);
    return response != null;
  }

  // Fetch all votes
  Future<List<Vote>> fetchVotes(int postId) async {
    var data = await _apiHelper.getRequest('social/posts/$postId/vote/');
    if (data != null) {
      return (data as List).map((vote) => Vote.fromJson(vote)).toList();
    }
    return [];
  }

  // Create a vote (upvote/downvote)
  Future<bool> createVote(int postId, Map<String, dynamic> voteData) async {
    var response = await _apiHelper.postRequest('social/posts/$postId/vote/', voteData);
    return response != null;
  }

  // Delete a vote
  Future<bool> deleteVote(int postId) async {
    return await _apiHelper.deleteRequest('social/posts/$postId/vote/delete/');
  }
}