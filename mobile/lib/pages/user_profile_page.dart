import 'package:flutter/material.dart';
import 'package:i_cant_cook/models/recipe_preview/recipe_preview.dart';
import 'package:i_cant_cook/models/user/user.dart';
import 'package:i_cant_cook/pages/settings_page.dart';
import 'package:i_cant_cook/theme/avatars.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:i_cant_cook/providers/user_profile_provider.dart';
import 'package:i_cant_cook/widgets/social/user_post_card.dart';
import 'package:i_cant_cook/widgets/recipes/recipe_tile.dart';
import 'package:provider/provider.dart';

class UserProfilePage extends StatelessWidget {
  final User user;

  const UserProfilePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserProfileProvider(user: user),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          centerTitle: true,
          leading: IconButton(
            padding: const EdgeInsets.only(left: 16.0),
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.chevron_left,
              color: Theme.of(context).colorScheme.primary,
              size: 32,
            ),
          ),
          title: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Profile',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w900,
                fontSize: 28,
                letterSpacing: -0.5,
              ),
            ),
          ),
          actions: [
            IconButton(
              padding: const EdgeInsets.only(right: 16.0),
              icon: Icon(
                Icons.settings,
                color: Theme.of(context).colorScheme.primary,
                size: 32,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                );
              },
            ),
          ],
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
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Column(
                    children: [
                      Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor:
                                  Theme.of(context).colorScheme.surface,
                              child: Avatars.getAvatarIcon(user.avatar_icon,
                                  size: 50),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "@${user.username}",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStat(
                              context, "Followers", provider.followerCount),
                          _buildStat(
                              context, "Recipes", provider.recipes.length),
                          _buildStat(context, "Posts", provider.posts.length),
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
                                ? Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                : Theme.of(context).colorScheme.primary,
                          ),
                          icon: provider.isFollowing
                              ? Icon(
                                  Icons.check,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 20,
                                )
                              : Icon(
                                  Icons.add,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                  size: 20,
                                ),
                          label: Text(
                            provider.isFollowing ? "Following" : "Follow",
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 16),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildTab(context, 'Recipes', 0, provider),
                          _buildTab(context, 'Posts', 1, provider),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Container(
                          height: 1,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Expanded(
                        child: provider.isLoading
                            ? Center(
                                child: CircularProgressIndicator(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              )
                            : provider.tabIndex == 0
                                ? provider.recipes.isEmpty
                                    ? Center(
                                        child: Text(
                                          "No recipes available.",
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface),
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
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
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
                                    ? Center(
                                        child: Text(
                                          "No posts available.",
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface),
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
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
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

  Widget _buildTab(BuildContext context, String title, int index,
      UserProfileProvider provider) {
    bool isSelected = provider.tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => provider.setTabIndex(index),
        child: Container(
          decoration: BoxDecoration(
            border: isSelected
                ? Border(
                    bottom: BorderSide(
                        color: Theme.of(context).colorScheme.onSurface,
                        width: 1.0))
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
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context).colorScheme.onSurfaceVariant,
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

  Widget _buildStat(BuildContext context, String label, int value) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
