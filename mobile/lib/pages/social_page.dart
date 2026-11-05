import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/models/user/user.dart';
import 'package:i_cant_cook/services/haptic_service.dart';
import 'package:i_cant_cook/theme/avatars.dart';
import 'package:i_cant_cook/widgets/appbar/appbar_user_menu.dart';

import 'package:i_cant_cook/providers/social_provider.dart';
import 'package:i_cant_cook/pages/user_profile_page.dart';
import 'package:i_cant_cook/widgets/social/user_post_card.dart';
import 'package:i_cant_cook/widgets/dialogs/user_post_dialog.dart';
import 'package:provider/provider.dart';

class SocialPage extends StatefulWidget {
  const SocialPage({super.key});

  @override
  State<SocialPage> createState() => _SocialPageState();
}

class _SocialPageState extends State<SocialPage> {
  @override
  void dispose() {
    // Reset the user search when leaving so a stale query doesn't linger on the
    // next visit. The provider outlives this page, so clear it explicitly.
    Provider.of<SocialProvider>(context, listen: false).resetSearch();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        centerTitle: true,
        leading: IconButton(
          padding: const EdgeInsets.only(left: 16.0),
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return PostDialog(
                  recipe: null,
                  onPostSuccess: () {
                    Provider.of<SocialProvider>(context, listen: false)
                        .refresh();
                  },
                );
              },
            );
          },
          icon: Container(
            padding: const EdgeInsets.all(16),
            child: FaIcon(
              FontAwesomeIcons.squarePlus,
              color: Theme.of(context).colorScheme.primary,
              size: 26,
            ),
          ),
        ),
        title: Text(
          'SOCIAL',
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            letterSpacing: 2.5,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        actions: [UserMenuWidget()],
      ),
      body: Consumer<SocialProvider>(
        builder: (context, provider, child) {
          return Stack(
            children: [
              Positioned.fill(
                child: Container(color: Theme.of(context).scaffoldBackgroundColor),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 0.0),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.25),
                            width: 1.5,
                          ),
                        ),
                        child: TextField(
                          controller: provider.searchController,
                          style: GoogleFonts.spaceGrotesk(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                          decoration: InputDecoration(
                            icon: Icon(Icons.search,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                                size: 20),
                            hintText: 'Search for a user',
                            hintStyle: GoogleFonts.spaceGrotesk(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
                              fontSize: 15,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 14.0, horizontal: 8.0),
                            // Clear button — only shown while the field has text.
                            suffixIcon: ValueListenableBuilder<TextEditingValue>(
                              valueListenable: provider.searchController,
                              builder: (context, value, _) {
                                if (value.text.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                return IconButton(
                                  tooltip: 'Clear',
                                  onPressed: () {
                                    HapticService.lightImpact();
                                    provider.resetSearch();
                                  },
                                  icon: Icon(
                                    Icons.close,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.5),
                                    size: 20,
                                  ),
                                );
                              },
                            ),
                          ),
                          onChanged: (query) => provider.onSearchChanged(
                              query, provider.fetchUsers),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildTab(context, 'All', 0, provider),
                        _buildTab(context, 'Trending', 1, provider),
                        _buildTab(context, 'Following', 2, provider),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Container(
                        height: 1,
                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    Expanded(
                      child: provider.posts.isEmpty
                          ? Center(
                              child: Text(
                                'No posts available at the moment.',
                                style: GoogleFonts.spaceGrotesk(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: provider.scrollController,
                              padding: EdgeInsets.zero,
                              itemCount: provider.posts.length + 1,
                              itemBuilder: (context, index) {
                                if (index == provider.posts.length) {
                                  return provider.isFetching
                                      ? SizedBox(
                                          height: 100,
                                          child: Center(
                                              child: CircularProgressIndicator(
                                            color: Theme.of(context).colorScheme.primary,
                                          )))
                                      : SizedBox(height: 100);
                                }
                                return UserPostCard(
                                  post: provider.posts[index],
                                  provider: provider,
                                ).animate(
                                  delay: (index < 8 ? index * 40 : 0).ms,
                                ).fadeIn(duration: 200.ms)
                                 .slideY(begin: 0.05, curve: Curves.easeOut, duration: 200.ms);
                              },
                            ),
                    ),
                  ],
                ),
              ),
              if (provider.showDropdown && provider.searchResults.isNotEmpty)
                Positioned(
                  top: 180,
                  left: 16,
                  right: 16,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxHeight: 300,
                        ),
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shrinkWrap: true,
                          itemCount: provider.searchResults.length,
                          itemBuilder: (context, index) {
                            final user = provider.searchResults[index];
                            return ListTile(
                              leading: Container(
                                width: 36,
                                height: 36,
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                child: Center(child: Avatars.getAvatarIcon(user.avatar_icon, size: 22)),
                              ),
                              title: Text(
                                "@${user.username}",
                                style: GoogleFonts.spaceGrotesk(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              onTap: () {
                                User selectedUser =
                                    provider.searchResults[index];
                                provider.onUserTap(context, selectedUser);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        UserProfilePage(user: selectedUser),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTab(BuildContext context, String title, int index, SocialProvider provider) {
    bool isSelected = provider.tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticService.selectionClick();
          provider.onTabTapped(index);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: isSelected
              ? Container(
                  color: Theme.of(context).colorScheme.secondary,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Text(
                    title.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceGrotesk(
                      color: Theme.of(context).colorScheme.onSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: 1.2,
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Text(
                    title.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceGrotesk(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
