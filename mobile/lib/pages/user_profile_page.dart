import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:i_cant_cook/models/recipe_preview/recipe_preview.dart';
import 'package:i_cant_cook/models/user/user.dart';
import 'package:i_cant_cook/pages/settings_page.dart';
import 'package:i_cant_cook/providers/user_profile_provider.dart';
import 'package:i_cant_cook/services/haptic_service.dart';
import 'package:i_cant_cook/theme/avatars.dart';
import 'package:i_cant_cook/widgets/recipes/recipe_tile.dart';
import 'package:i_cant_cook/widgets/social/user_post_card.dart';

class UserProfilePage extends StatelessWidget {
  final User user;

  const UserProfilePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserProfileProvider(user: user),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          elevation: 0,
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
          title: Text(
            'PROFILE',
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.w700,
              fontSize: 22,
              letterSpacing: 2.5,
              color: Theme.of(context).colorScheme.onSurface,
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
                  child: Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
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
                              child: Avatars.getAvatarIcon(
                                user.avatar_icon,
                                size: 50,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '@${user.username}',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color:
                                    Theme.of(context).colorScheme.onSurface,
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
                              context, 'Followers', provider.followerCount),
                          _buildStat(
                              context, 'Recipes', provider.recipes.length),
                          _buildStat(
                              context, 'Posts', provider.posts.length),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (!provider.isCurrentUser)
                        ElevatedButton.icon(
                          onPressed: () {
                            HapticService.mediumImpact();
                            provider.toggleFollowUser();
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 100),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            backgroundColor: provider.isFollowing
                                ? Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                : Theme.of(context).colorScheme.primary,
                            foregroundColor: provider.isFollowing
                                ? Theme.of(context).colorScheme.onSurface
                                : Theme.of(context).colorScheme.onPrimary,
                            elevation: 0,
                          ),
                          icon: Icon(
                            provider.isFollowing ? Icons.check : Icons.add,
                            size: 20,
                            color: provider.isFollowing
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onPrimary,
                          ),
                          label: Text(
                            provider.isFollowing ? 'Following' : 'Follow',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
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
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withOpacity(0.3),
                        ),
                      ),
                      Expanded(
                        child: provider.isLoading
                            ? Center(
                                child: CircularProgressIndicator(
                                  color:
                                      Theme.of(context).colorScheme.primary,
                                ),
                              )
                            : provider.tabIndex == 0
                                ? _buildRecipesList(context, provider)
                                : _buildPostsList(context, provider),
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

  Widget _buildRecipesList(
      BuildContext context, UserProfileProvider provider) {
    if (provider.recipes.isEmpty) {
      return Center(
        child: Text(
          'No recipes available.',
          style: GoogleFonts.spaceGrotesk(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: provider.recipes.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Text(
              'Showing ${provider.recipes.length} recipes',
              style: GoogleFonts.spaceGrotesk(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }

        return RecipeTile(
          recipe: RecipePreview.fromRecipe(
            provider.recipes[index - 1],
          ),
        );
      },
    );
  }

  Widget _buildPostsList(BuildContext context, UserProfileProvider provider) {
    if (provider.posts.isEmpty) {
      return Center(
        child: Text(
          'No posts available.',
          style: GoogleFonts.spaceGrotesk(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: provider.posts.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Text(
              'Showing ${provider.posts.length} posts',
              style: GoogleFonts.spaceGrotesk(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }

        return UserPostCard(
          post: provider.posts[index - 1],
          provider: provider,
        );
      },
    );
  }

  Widget _buildTab(
      BuildContext context, String title, int index, UserProfileProvider provider) {
    final isSelected = provider.tabIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticService.selectionClick();
          provider.setTabIndex(index);
        },
        child: Container(
          decoration: isSelected
              ? BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2.0,
                    ),
                  ),
                )
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 12.0),
            child: Column(
              children: [
                Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
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
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
