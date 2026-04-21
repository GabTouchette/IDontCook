import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/models/user/user.dart';
import 'package:i_cant_cook/theme/avatars.dart';
import 'package:i_cant_cook/widgets/appbar/appbar_user_menu.dart';

import 'package:i_cant_cook/providers/social_provider.dart';
import 'package:i_cant_cook/pages/user_profile_page.dart';
import 'package:i_cant_cook/widgets/social/user_post_card.dart';
import 'package:i_cant_cook/widgets/dialogs/user_post_dialog.dart';
import 'package:provider/provider.dart';

class SocialPage extends StatelessWidget {
  const SocialPage({super.key});

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
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'News',
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w900,
              fontSize: 28,
              letterSpacing: -0.5,
            ),
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
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: provider.searchController,
                          style: GoogleFonts.nunito(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            icon: Icon(Icons.search,
                                color: Theme.of(context).colorScheme.primary),
                            hintText: 'Search for a user',
                            hintStyle: GoogleFonts.nunito(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 16.0, horizontal: 8.0),
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
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                      ),
                    ),
                    Expanded(
                      child: provider.posts.isEmpty
                          ? Center(
                              child: Text(
                                'No posts available at the moment.',
                                style: GoogleFonts.nunito(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
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
                                );
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
                        borderRadius: BorderRadius.circular(16),
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
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                child: Avatars.getAvatarIcon(user.avatar_icon),
                              ),
                              title: Text(
                                "@${user.username}",
                                style: GoogleFonts.nunito(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
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
        onTap: () => provider.onTabTapped(index),
        child: Container(
          decoration: BoxDecoration(
            border: isSelected
                ? Border(bottom: BorderSide(
                    color: Theme.of(context).colorScheme.primary, 
                    width: 2.0
                  ))
                : null,
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 4.0, horizontal: 12.0),
            child: Column(
              children: [
                Text(
                  title,
                  style: GoogleFonts.nunito(
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
}
