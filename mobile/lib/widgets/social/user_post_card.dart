import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:i_cant_cook/api/auth_api.dart';
import 'package:i_cant_cook/api/social_api.dart';
import 'package:i_cant_cook/models/post/post.dart';
import 'package:i_cant_cook/models/user/user.dart';
import 'package:i_cant_cook/pages/recipe_detail_page.dart';
import 'package:i_cant_cook/pages/user_profile_page.dart';
import 'package:i_cant_cook/mixins/post_mixin.dart';
import 'package:i_cant_cook/theme/avatars.dart';
import 'package:i_cant_cook/theme/colors.dart';
import 'package:i_cant_cook/widgets/dialogs/confirmation_dialog.dart';
import 'package:i_cant_cook/widgets/dialogs/post_comments_dialog.dart';
import 'package:i_cant_cook/widgets/recipes/placeholder_image.dart';
import 'package:i_cant_cook/widgets/toasts/information_toast.dart';

class UserPostCard extends StatefulWidget {
  final Post post;
  final PostMixin provider;

  const UserPostCard({super.key, required this.post, required this.provider});

  @override
  _UserPostCardState createState() => _UserPostCardState();
}

class _UserPostCardState extends State<UserPostCard>
    with AutomaticKeepAliveClientMixin {
  late Future<User?> _currentUser;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _currentUser = _fetchUser();
  }

  Future<User?> _fetchUser() async {
    return await AuthApi.getUser();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final provider = widget.provider;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      color: ColorPalette.darkgray,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(provider),
            if (widget.post.content != null) _buildContent(),
            _buildPostDetails(provider),
            _buildActionButtons(provider),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(PostMixin provider) {
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

  Widget _buildPostDetails(PostMixin provider) {
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
          _buildVoteButtons(provider),
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

  Widget _buildVoteButtons(PostMixin provider) {
    final post = widget.post;
    final isUpvoted = post.user_vote == 1;
    final isDownvoted = post.user_vote == -1;
    final voteCount = post.upvote_count - post.downvote_count;

    return Column(
      children: [
        IconButton(
          icon: Icon(Icons.keyboard_arrow_up,
              color: isUpvoted ? Colors.green : ColorPalette.gray),
          iconSize: 50,
          onPressed: () => provider.handleVote(post.id, 1),
        ),
        Text(
          "$voteCount",
          style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: ColorPalette.offWhite),
        ),
        IconButton(
          icon: Icon(Icons.keyboard_arrow_down,
              color: isDownvoted ? Colors.red : ColorPalette.gray),
          iconSize: 50,
          onPressed: () => provider.handleVote(post.id, -1),
        ),
      ],
    );
  }

  Widget _buildActionButtons(PostMixin provider) {
    final post = widget.post;
    final isLiked = post.user_liked;
    final likeCount = post.like_count;
    final commentCount = post.comment_count;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => provider.toggleLike(post.user.id, post.id),
              icon: FaIcon(
                isLiked ? FontAwesomeIcons.solidHeart : FontAwesomeIcons.heart,
                color: isLiked ? Colors.red : ColorPalette.offWhite,
                size: 28,
              ),
            ),
            Text(
              "$likeCount",
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
                      post: post,
                      onCommentAdded: () {
                        provider.incrementCommentCount(post.id);
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
              "$commentCount",
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
      child: widget.post.recipe_thumbnail_url != null &&
              widget.post.recipe_thumbnail_url!.isNotEmpty
          ? Image.network(
              widget.post.recipe_thumbnail_url!,
              height: 120,
              width: 120,
              fit: BoxFit.cover,
            )
          : PlaceholderImageWidget(recipeId: widget.post.recipe_id ?? 1),
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

  Future<void> _deletePost() async {
    final result = await SocialApi().deletePost(widget.post.id);

    Navigator.pop(context);
    widget.provider.refresh();

    InformationToast.show(
      context: context,
      message: result ? "Post deleted successfully!" : "Failed to delete post.",
      textColor: result ? ColorPalette.green : ColorPalette.red,
    );
  }
}
