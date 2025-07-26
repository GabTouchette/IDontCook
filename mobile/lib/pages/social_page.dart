import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:i_cant_cook/models/user/user.dart';
import 'package:i_cant_cook/theme/avatars.dart';
import 'package:i_cant_cook/theme/colors.dart';
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          padding: const EdgeInsets.only(left: 16),
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
          icon: const FaIcon(
            FontAwesomeIcons.squarePlus,
            color: ColorPalette.offWhite,
            size: 28,
          ),
        ),
        title: Text(
          'News',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 32,
            color: ColorPalette.offWhite,
          ),
        ),
        actions: [
          UserMenuWidget(),
        ],
      ),
      body: Consumer<SocialProvider>(
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
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        decoration: BoxDecoration(
                          color: ColorPalette.darkergray,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: ColorPalette.darkgray),
                        ),
                        child: TextField(
                          controller: provider.searchController,
                          style: const TextStyle(color: ColorPalette.offWhite),
                          decoration: InputDecoration(
                            icon: const Icon(Icons.search,
                                color: ColorPalette.offWhite),
                            hintText: 'Search for a user',
                            hintStyle: const TextStyle(
                                color: ColorPalette.placeholdergray),
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
                        _buildTab('All', 0, provider),
                        _buildTab('Trending', 1, provider),
                        _buildTab('Following', 2, provider),
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
                      child: provider.posts.isEmpty
                          ? const Center(
                              child: Text('No posts available at the moment.',
                                  style:
                                      TextStyle(color: ColorPalette.offWhite)))
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
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    ColorPalette.offWhite),
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
                        color: ColorPalette.darkergray,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: ColorPalette.darkgray),
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
                                backgroundColor: ColorPalette.lightgray,
                                child: Avatars.getAvatarIcon(user.avatar_icon),
                              ),
                              title: Text(
                                "@${user.username}",
                                style: const TextStyle(
                                    color: ColorPalette.offWhite),
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

  Widget _buildTab(String title, int index, SocialProvider provider) {
    bool isSelected = provider.tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => provider.onTabTapped(index),
        child: Container(
          decoration: BoxDecoration(
            border: isSelected
                ? Border(bottom: BorderSide(color: Colors.white, width: 1.0))
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
}
