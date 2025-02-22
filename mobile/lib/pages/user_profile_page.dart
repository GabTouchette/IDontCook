import 'package:flutter/material.dart';
import 'package:mobile/models/recipe_preview/recipe_preview.dart';
import 'package:mobile/models/user/user.dart';
import 'package:mobile/theme/avatars.dart';
import 'package:mobile/theme/colors.dart';
import 'package:provider/provider.dart';
import 'package:mobile/providers/user_profile_provider.dart';
import 'package:mobile/widgets/explore/user_post_card.dart';
import 'package:mobile/widgets/recipes/recipe_tile.dart';

class UserProfilePage extends StatelessWidget {
  final User user;

  const UserProfilePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserProfileProvider(user: user),
      child: Scaffold(
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
        body: Consumer<UserProfileProvider>(
          builder: (context, provider, child) {
            return Stack(
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
                              child: Avatars.getAvatarIcon(user.avatar_icon,
                                  size: 50),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "@${user.username}",
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
                          _buildStat("Followers", provider.followerCount),
                          _buildStat("Recipes", provider.recipes.length),
                          _buildStat("Posts", provider.posts.length),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (!provider.isCurrentUser)
                        ElevatedButton.icon(
                          onPressed: provider.toggleFollowUser,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 100),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            backgroundColor: provider.isFollowing
                                ? ColorPalette.darkgray
                                : ColorPalette.blue,
                          ),
                          icon: provider.isFollowing
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
                            provider.isFollowing ? "Following" : "Follow",
                            style: const TextStyle(
                                color: ColorPalette.offWhite, fontSize: 16),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildTab('Recipes', 0, provider),
                          _buildTab('Posts', 1, provider),
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
                        child: provider.isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: ColorPalette.offWhite,
                                ),
                              )
                            : provider.tabIndex == 0
                                ? provider.recipes.isEmpty
                                    ? const Center(
                                        child: Text(
                                          "No recipes available.",
                                          style: TextStyle(
                                              color: ColorPalette.offWhite),
                                        ),
                                      )
                                    : ListView.builder(
                                        padding: EdgeInsets.zero,
                                        itemCount: provider.recipes.length + 1,
                                        itemBuilder: (context, index) {
                                          if (index == 0) {
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 8.0,
                                                      horizontal: 16.0),
                                              child: Text(
                                                'Showing ${provider.recipes.length} recipes',
                                                style: TextStyle(
                                                  color: ColorPalette.offWhite,
                                                  fontSize: 18,
                                                ),
                                              ),
                                            );
                                          } else {
                                            return RecipeTile(
                                              recipe: RecipePreview.fromRecipe(
                                                provider.recipes[index - 1],
                                              ),
                                            );
                                          }
                                        },
                                      )
                                : provider.posts.isEmpty
                                    ? const Center(
                                        child: Text(
                                          "No posts available.",
                                          style: TextStyle(
                                              color: ColorPalette.offWhite),
                                        ),
                                      )
                                    : ListView.builder(
                                        padding: EdgeInsets.zero,
                                        itemCount: provider.posts.length + 1,
                                        itemBuilder: (context, index) {
                                          if (index == 0) {
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 8.0,
                                                      horizontal: 16.0),
                                              child: Text(
                                                'Showing ${provider.posts.length} posts',
                                                style: TextStyle(
                                                  color: ColorPalette.offWhite,
                                                  fontSize: 18,
                                                ),
                                              ),
                                            );
                                          } else {
                                            return UserPostCard(
                                              post: provider.posts[index - 1],
                                              provider: provider,
                                            );
                                          }
                                        },
                                      ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTab(String title, int index, UserProfileProvider provider) {
    bool isSelected = provider.tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => provider.setTabIndex(index),
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
