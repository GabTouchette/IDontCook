import 'package:flutter/material.dart';
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
      margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.12),
            width: 1,
          ),
        ),
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
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.35),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Avatars.getAvatarIcon(widget.post.user.avatar_icon),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "@${widget.post.user.username}",
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      "SHARED A RECIPE",
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.2,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
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
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    onPressed: _showDeleteDialog,
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
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Text(
        '"${widget.post.content}"',
        style: GoogleFonts.spaceGrotesk(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            height: 1.5,
            fontStyle: FontStyle.italic,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
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
                        style: GoogleFonts.spaceGrotesk(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            letterSpacing: -0.2,
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
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
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
          icon: Icon(
            isThumbsUp ? Icons.thumb_up : Icons.thumb_up_outlined,
            color: isThumbsUp
                ? Theme.of(context).colorScheme.success
                : Theme.of(context).colorScheme.outline,
            size: 18,
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
          style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface),
        ),
        IconButton(
          icon: Icon(
            isThumbsDown ? Icons.thumb_down : Icons.thumb_down_outlined,
            color: isThumbsDown
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.outline,
            size: 18,
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
              icon: const Icon(
                Icons.chat_bubble_outline,
                size: 22,
              ),
            ),
            Text(
              "$commentCount",
              style: GoogleFonts.spaceGrotesk(
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
    return widget.post.recipe_thumbnail_url != null &&
            widget.post.recipe_thumbnail_url!.isNotEmpty
        ? Image.network(
            widget.post.recipe_thumbnail_url!,
            height: 100,
            width: 100,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                PlaceholderImageWidget(recipeId: widget.post.recipe_id ?? 1),
          )
        : PlaceholderImageWidget(recipeId: widget.post.recipe_id ?? 1);
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
