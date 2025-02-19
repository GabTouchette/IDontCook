import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mobile/api/auth_api.dart';
import 'package:mobile/api/social_api.dart';
import 'package:mobile/models/post/post.dart';
import 'package:mobile/models/user/user.dart';
import 'package:mobile/pages/recipe_detail_page/recipe_detail_page.dart';
import 'package:mobile/pages/user_profile_page.dart';
import 'package:mobile/theme/avatars.dart';
import 'package:mobile/theme/colors.dart';
import 'package:mobile/widgets/dialogs/confirmation_dialog.dart';
import 'package:mobile/widgets/dialogs/post_comments_dialog.dart';
import 'package:mobile/widgets/recipes/placeholder_image.dart';
import 'package:mobile/widgets/toasts/information_toast.dart';

class UserPostCard extends StatefulWidget {
  final Post post;

  const UserPostCard({super.key, required this.post});

  @override
  _UserPostCardState createState() => _UserPostCardState();
}

class _UserPostCardState extends State<UserPostCard> {
  late int _currentVoteCount;
  late int _currentCommentCount;
  late int _currentLikeCount;
  late int _userVote;
  late bool _userLiked;
  late Future<User?> _currentUser;

  @override
  void initState() {
    super.initState();
    _currentVoteCount = widget.post.upvote_count - widget.post.downvote_count;
    _userVote = widget.post.user_vote;
    _userLiked = widget.post.user_liked;
    _currentCommentCount = widget.post.comment_count;
    _currentLikeCount = widget.post.like_count;
    _currentUser = _fetchUser();
  }

  Future<User?> _fetchUser() async {
    return await AuthApi.getUser();
  }

  Future<void> _handleVote(int voteValue) async {
    if (_userVote == voteValue) {
      bool success = await SocialApi().deleteVote(widget.post.id);
      if (success) {
        setState(() {
          _currentVoteCount -= voteValue;
          _userVote = 0;
        });
      }
    } else {
      Map<String, dynamic> voteData = {"value": voteValue};
      bool success = await SocialApi().createVote(widget.post.id, voteData);
      if (success) {
        setState(() {
          _currentVoteCount += (voteValue - _userVote);
          _userVote = voteValue;
        });
      }
    }
  }

  Future<void> _toggleLike() async {
    Map<String, dynamic> likeData = {
      "user": widget.post.user.id,
      "post": widget.post.id,
      "comment": null,
    };

    bool success;
    if (_userLiked) {
      success = await SocialApi().deleteLike(widget.post.id);
    } else {
      success = await SocialApi().createLike(likeData, widget.post.id);
    }

    if (success) {
      setState(() {
        _userLiked = !_userLiked;
        _currentLikeCount += _userLiked ? 1 : -1;
      });
    }
  }

  Future<void> _deletePost() async {
    final result = await SocialApi().deletePost(widget.post.id);

    InformationToast.show(
      context: context,
      message: result ? "Post deleted successfully!" : "Failed to delete post.",
      textColor: result ? ColorPalette.green : ColorPalette.red,
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return ConfirmationDialog(
          message: 'Are you sure you want to delete this post?',
          onConfirm: () {
            _deletePost();
          },
          onCancel: () {
            Navigator.pop(context);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      color: ColorPalette.darkgray,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            if (widget.post.content != null) _buildContent(),
            _buildPostDetails(),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserProfilePage(user: widget.post.user),
                ),
              );
            },
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: ColorPalette.lightgray,
                  child: Avatars.getAvatarIcon(widget.post.user.avatar_icon),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "@${widget.post.user.username}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w300,
                        color: ColorPalette.offWhite,
                      ),
                    ),
                    const Text(
                      "shared a recipe",
                      style: TextStyle(color: ColorPalette.placeholdergray),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          FutureBuilder<User?>(
            future: _currentUser,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return const Icon(Icons.error, color: Colors.red);
              } else if (snapshot.hasData) {
                final currentUser = snapshot.data;
                if (currentUser != null &&
                    currentUser.username == widget.post.user.username) {
                  return IconButton(
                    icon: FaIcon(FontAwesomeIcons.trash, color: Colors.red),
                    onPressed: _showDeleteDialog,
                    iconSize: 24,
                  );
                }
              }
              return Container();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 0, 8),
      child: Text(
        '"${widget.post.content}"',
        style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: ColorPalette.offWhite),
      ),
    );
  }

  Widget _buildPostDetails() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailPage(
              recipeId: widget.post.recipe_id,
            ),
          ),
        );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildVoteButtons(),
          _buildRecipeImage(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.post.recipe_title ??
                      "${widget.post.user.username}'s Recipe",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: ColorPalette.offWhite),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.post.recipe_description?.isNotEmpty == true
                      ? widget.post.recipe_description!
                      : "No description available.",
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontWeight: FontWeight.w300, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoteButtons() {
    return Column(
      children: [
        IconButton(
          icon: Icon(Icons.keyboard_arrow_up,
              color: _userVote == 1 ? Colors.green : ColorPalette.gray),
          iconSize: 50,
          onPressed: () => _handleVote(1),
        ),
        Text(
          "$_currentVoteCount",
          style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: ColorPalette.offWhite),
        ),
        IconButton(
          icon: Icon(Icons.keyboard_arrow_down,
              color: _userVote == -1 ? Colors.red : ColorPalette.gray),
          iconSize: 50,
          onPressed: () => _handleVote(-1),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: _toggleLike,
              icon: FaIcon(
                _userLiked
                    ? FontAwesomeIcons.solidHeart
                    : FontAwesomeIcons.heart,
                color: _userLiked ? Colors.red : ColorPalette.offWhite,
                size: 28,
              ),
            ),
            Text(
              _currentLikeCount.toString(),
              style: const TextStyle(
                color: ColorPalette.offWhite,
                fontSize: 12,
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => CommentDrawer(
                      post: widget.post,
                      onCommentAdded: () {
                        setState(() {
                          _currentCommentCount++;
                        });
                      }),
                );
              },
              icon: const FaIcon(
                FontAwesomeIcons.comment,
                color: ColorPalette.offWhite,
                size: 28,
              ),
            ),
            Text(
              _currentCommentCount.toString(),
              style: const TextStyle(
                color: ColorPalette.offWhite,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecipeImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: widget.post.recipe_image_url != null &&
              widget.post.recipe_image_url!.isNotEmpty
          ? Image.network(
              widget.post.recipe_image_url!,
              height: 120,
              width: 120,
              fit: BoxFit.cover,
            )
          : PlaceholderImageWidget(recipeId: widget.post.recipe_id ?? 1),
    );
  }
}
