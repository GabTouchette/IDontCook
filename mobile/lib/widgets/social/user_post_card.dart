import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/api/auth_api.dart';
import 'package:i_cant_cook/api/social_api.dart';
import 'package:i_cant_cook/enums/toast_type.dart';
import 'package:i_cant_cook/models/post/post.dart';
import 'package:i_cant_cook/models/user/user.dart';
import 'package:i_cant_cook/pages/recipe_detail_page.dart';
import 'package:i_cant_cook/pages/user_profile_page.dart';
import 'package:i_cant_cook/mixins/post_mixin.dart';
import 'package:i_cant_cook/theme/avatars.dart';
import 'package:i_cant_cook/theme/theme.dart';
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

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
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
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Avatars.getAvatarIcon(widget.post.user.avatar_icon),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "@${widget.post.user.username}",
                      style: GoogleFonts.nunito(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      "shared a recipe",
                      style: GoogleFonts.nunito(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
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
        style: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface),
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
          _buildRecipeImage(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.post.recipe_title ??
                            "${widget.post.user.username}'s Recipe",
                        style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                            color: Theme.of(context).colorScheme.onSurface),
                      ),
                    ),
                    _buildRecipeRatingButtons(provider),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.post.recipe_description?.isNotEmpty == true
                      ? widget.post.recipe_description!
                      : "No description available.",
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontWeight: FontWeight.w300,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeRatingButtons(PostMixin provider) {
    final post = widget.post;
    final userVote = post.user_recipe_vote ?? 0;
    final isThumbsUp = userVote == 1;
    final isThumbsDown = userVote == -1;
    final thumbsUpCount = post.recipe_thumbs_up_count ?? 0;
    final thumbsDownCount = post.recipe_thumbs_down_count ?? 0;
    final netRating = thumbsUpCount - thumbsDownCount;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: FaIcon(
            isThumbsUp ? FontAwesomeIcons.solidThumbsUp : FontAwesomeIcons.thumbsUp,
            color: isThumbsUp
                ? Theme.of(context).colorScheme.success
                : Theme.of(context).colorScheme.outline,
            size: 20,
          ),
          onPressed: () {
            if (post.recipe_id != null) {
              provider.handleRecipeVote(post.id, post.recipe_id!, 1);
            }
          },
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          padding: EdgeInsets.zero,
        ),
        Text(
          "$netRating",
          style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface),
        ),
        IconButton(
          icon: FaIcon(
            isThumbsDown ? FontAwesomeIcons.solidThumbsDown : FontAwesomeIcons.thumbsDown,
            color: isThumbsDown
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.outline,
            size: 20,
          ),
          onPressed: () {
            if (post.recipe_id != null) {
              provider.handleRecipeVote(post.id, post.recipe_id!, -1);
            }
          },
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildActionButtons(PostMixin provider) {
    final post = widget.post;
    final commentCount = post.comment_count;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
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
              icon: FaIcon(
                FontAwesomeIcons.comment,
                color: Theme.of(context).colorScheme.onSurface,
                size: 28,
              ),
            ),
            Text(
              "$commentCount",
              style: GoogleFonts.nunito(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w600,
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
      type: result ? ToastType.success : ToastType.error,
    );
  }
}
