import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mobile/api/social_api.dart';
import 'package:mobile/models/post.dart';
import 'package:mobile/models/user.dart';
import 'package:mobile/pages/user_profile_page.dart';
import 'package:mobile/theme/colors.dart';
import 'package:mobile/widgets/dialogs/user_post_dialog.dart';
import 'package:mobile/widgets/explore/user_post_card.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  _ExplorePageState createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  int _tabIndex = 0;
  List<Post> _posts = [];
  Timer? _debounceTimer;
  final TextEditingController _searchController = TextEditingController();
  List<User> _searchResults = [];
  bool _showDropdown = false;
  final SocialApi _socialApi = SocialApi();

  @override
  void initState() {
    super.initState();
    _fetchSocials();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _tabIndex = index;
    });
    _refresh();
  }

  Future<void> _refresh() async {
    await _fetchSocials();
  }

  Future<void> _fetchSocials() async {
    List<Post> posts = await _socialApi.fetchPosts();
    setState(() {
      _posts = posts;
    });
  }

  Future<void> _fetchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _showDropdown = false;
      });
      return;
    }

    try {
      final users = await SocialApi().searchUsers(query);
      setState(() {
        _searchResults = users;
        _showDropdown = true;
      });
    } catch (e) {
      print('Error fetching users: $e');
    }
  }

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer?.cancel();
    }

    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      _fetchUsers(query);
    });
  }

  void _onUserTap(BuildContext context, User selectedUser) {
    _searchController.text = selectedUser.username;
    setState(() {
      _showDropdown = false;
    });
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfilePage(user: selectedUser),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Explore',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 32,
            color: ColorPalette.offWhite,
          ),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.chevron_left,
            size: 32,
            color: ColorPalette.offWhite,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return PostDialog(
                    recipe: null,
                  );
                },
              );
            },
            icon: const FaIcon(
              FontAwesomeIcons.squarePlus,
              color: ColorPalette.offWhite,
            ),
          ),
          const Padding(padding: EdgeInsets.only(right: 16.0)),
        ],
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
                      controller: _searchController,
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
                      onChanged: _onSearchChanged,
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTab('Charts', 0),
                    _buildTab('Latest', 1),
                    _buildTab('Friends', 2),
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
                  child: _posts.isEmpty
                      ? const Center(
                          child: Text('No posts available.',
                              style: TextStyle(color: ColorPalette.offWhite)))
                      : ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: _posts.length,
                          itemBuilder: (context, index) {
                            final post = _posts[index];
                            return UserPostCard(
                              post: post,
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          if (_showDropdown && _searchResults.length > 0)
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
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final user = _searchResults[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: ColorPalette.lightgray,
                            child: Text(user.username[0]),
                          ),
                          title: Text(
                            "@${user.username}",
                            style:
                                const TextStyle(color: ColorPalette.offWhite),
                          ),
                          onTap: () {
                            User selectedUser = _searchResults[
                                index]; // Assuming you're iterating through _searchResults
                            _onUserTap(context, selectedUser);
                          },
                        );
                      },
                    ),
                  ),
                ),
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
