import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mobile/api/social_api.dart';
import 'package:mobile/models/paginated_posts/paginated_posts.dart';
import 'package:mobile/models/post/post.dart';
import 'package:mobile/models/user/user.dart';
import 'package:mobile/pages/user_profile_page.dart';
import 'package:mobile/theme/avatars.dart';
import 'package:mobile/theme/colors.dart';
import 'package:mobile/widgets/appbar/appbar_user_menu.dart';
import 'package:mobile/widgets/dialogs/user_post_dialog.dart';
import 'package:mobile/widgets/explore/user_post_card.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  _ExplorePageState createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  int _tabIndex = 0;
  List<Post> _posts = [];
  Timer? _debounceTimer;
  List<User> _searchResults = [];
  bool _showDropdown = false;
  int _currentPage = 1;
  String? _nextPageUrl;
  bool _isFetching = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _fetchPosts();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _tabIndex = index;
    });
    _refresh();
  }

  Future<void> _refresh() async {
    _currentPage = 1;
    _posts.clear();
    await _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    if (_isFetching) return;
    setState(() {
      _isFetching = true;
    });
    PaginatedPosts paginatedPosts = await SocialApi()
        .fetchPosts(page: _currentPage, category: _getCategoryFilter());
    setState(() {
      _nextPageUrl = paginatedPosts.next;
      _posts.addAll(paginatedPosts.results);
      _isFetching = false;
    });
  }

  String _getCategoryFilter() {
    switch (_tabIndex) {
      case 0:
        return "all";
      case 1:
        return "trending";
      case 2:
        return "following";
      default:
        return "all";
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (_nextPageUrl != null) {
        _currentPage++;
        _fetchPosts();
      }
    }
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
          'Explore',
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
                    _buildTab('All', 0),
                    _buildTab('Trending', 1),
                    _buildTab('Following', 2),
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
                          controller: _scrollController,
                          padding: EdgeInsets.zero,
                          itemCount: _posts.length + 1,
                          itemBuilder: (context, index) {
                            if (index == _posts.length) {
                              return _isFetching
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
                              post: _posts[index],
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
                            child: Avatars.getAvatarIcon(user.avatar_icon),
                          ),
                          title: Text(
                            "@${user.username}",
                            style:
                                const TextStyle(color: ColorPalette.offWhite),
                          ),
                          onTap: () {
                            User selectedUser = _searchResults[index];
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
