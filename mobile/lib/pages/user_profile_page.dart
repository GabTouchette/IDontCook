import 'package:flutter/material.dart';
import 'package:mobile/api/auth_api.dart';
import 'package:mobile/api/social_api.dart';
import 'package:mobile/models/post.dart';
import 'package:mobile/models/recipe.dart';
import 'package:mobile/models/recipe_preview.dart';
import 'package:mobile/models/user.dart';
import 'package:mobile/theme/avatars.dart';
import 'package:mobile/theme/colors.dart';
import 'package:mobile/widgets/explore/user_post_card.dart';
import 'package:mobile/widgets/recipe_tile.dart';

class UserProfilePage extends StatefulWidget {
  final User user;

  const UserProfilePage({super.key, required this.user});

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  int _tabIndex = 0;
  List<Recipe> _recipes = [];
  List<Post> _posts = [];
  bool _isFollowing = false;
  bool _isCurrentUser = false;
  int _follower_count = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchConnectedUser();
    _follower_count = widget.user.follower_count ?? 0;
  }

  Future<void> _fetchConnectedUser() async {
    final currentUser = await AuthApi.getUser();
    if (currentUser != null) {
      setState(() {
        _isCurrentUser = currentUser.id == widget.user.id;
      });
      bool followingStatus = await SocialApi().isUserFollowing(widget.user.id);
      setState(() {
        _isFollowing = followingStatus;
      });
    }
  }

  Future<void> _fetchUserData() async {
    final recipes = await SocialApi().fetchUserRecipes(widget.user.id);
    final posts = await SocialApi().fetchUserPosts(widget.user.id);

    posts.sort((a, b) {
      final aVotes = a.upvote_count - a.downvote_count;
      final bVotes = b.upvote_count - b.downvote_count;
      return bVotes.compareTo(aVotes);
    });

    setState(() {
      _recipes = recipes;
      _posts = posts;
    });
  }

  void _onTabTapped(int index) {
    setState(() {
      _tabIndex = index;
    });
  }

  Future<void> _toggleFollowUser() async {
    bool success;

    if (_isFollowing) {
      success = await SocialApi().deleteFollow(widget.user.id);
    } else {
      success = await SocialApi().createFollow(widget.user.id);
    }

    if (success) {
      setState(() {
        _isFollowing = !_isFollowing;
        _follower_count += _isFollowing ? 1 : -1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.chevron_left,
            size: 32,
            color: ColorPalette.offWhite,
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/explore_page_background.png',
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 100.0),
            child: Column(
              children: [
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: ColorPalette.lightgray,
                        child: Avatars.getAvatarIcon(widget.user.avatar_icon, size: 50),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "@${widget.user.username}",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: ColorPalette.offWhite,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStat("Followers", _follower_count),
                    _buildStat("Recipes", _recipes.length),
                    _buildStat("Posts", _posts.length),
                  ],
                ),
                const SizedBox(height: 16),
                if (!_isCurrentUser)
                  ElevatedButton.icon(
                    onPressed: _toggleFollowUser,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 100),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      backgroundColor: _isFollowing
                          ? ColorPalette.darkgray
                          : ColorPalette.blue,
                    ),
                    icon: _isFollowing
                        ? const Icon(
                            Icons.check,
                            color: ColorPalette.green,
                            size: 20,
                          )
                        : const Icon(
                            Icons.add,
                            color: ColorPalette.offWhite,
                            size: 20,
                          ),
                    label: Text(
                      _isFollowing ? "Following" : "Follow",
                      style: const TextStyle(
                          color: ColorPalette.offWhite, fontSize: 16),
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTab('Recipes', 0),
                    _buildTab('Posts', 1),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Container(
                    height: 1,
                    color: ColorPalette.placeholdergray,
                  ),
                ),
                Expanded(
                  child: _tabIndex == 0
                      ? _recipes.isEmpty
                          ? const Center(
                              child: Text(
                                "No recipes available.",
                                style: TextStyle(color: ColorPalette.offWhite),
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: _recipes.length + 1,
                              itemBuilder: (context, index) {
                                if (index == 0) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8.0, horizontal: 16.0),
                                    child: Text(
                                      'Showing ${_recipes.length} recipes',
                                      style: TextStyle(
                                        color: ColorPalette.offWhite,
                                        fontSize: 18,
                                      ),
                                    ),
                                  );
                                } else {
                                  return RecipeTile(
                                    recipe: RecipePreview.fromRecipe(
                                        _recipes[index - 1]),
                                  );
                                }
                              },
                            )
                      : _posts.isEmpty
                          ? const Center(
                              child: Text(
                                "No posts available.",
                                style: TextStyle(color: ColorPalette.offWhite),
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: _posts.length + 1,
                              itemBuilder: (context, index) {
                                if (index == 0) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8.0, horizontal: 16.0),
                                    child: Text(
                                      'Showing ${_posts.length} posts',
                                      style: TextStyle(
                                        color: ColorPalette.offWhite,
                                        fontSize: 18,
                                      ),
                                    ),
                                  );
                                } else {
                                  return UserPostCard(post: _posts[index - 1]);
                                }
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    bool isSelected = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabTapped(index),
        child: Container(
          decoration: BoxDecoration(
            border: isSelected
                ? Border(
                    bottom:
                        BorderSide(color: ColorPalette.offWhite, width: 1.0))
                : null,
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 4.0, horizontal: 12.0),
            child: Column(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected
                        ? ColorPalette.offWhite
                        : ColorPalette.placeholdergray,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, int value) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: ColorPalette.offWhite,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: ColorPalette.placeholdergray,
          ),
        ),
      ],
    );
  }
}
