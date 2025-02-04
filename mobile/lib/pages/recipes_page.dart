import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mobile/api/auth_api.dart';
import 'package:mobile/api/recipe_api.dart';
import 'package:mobile/models/recipe_preview.dart';
import 'package:mobile/widgets/recipe_tile.dart';
import 'package:mobile/pages/create_recipe_page.dart';
import 'package:mobile/theme/colors.dart';

class RecipesPage extends StatefulWidget {
  const RecipesPage({super.key});

  @override
  _RecipesPageState createState() => _RecipesPageState();
}

class _RecipesPageState extends State<RecipesPage> {
  int _tabIndex = 0;

  List<RecipePreview> _allRecipes = [];
  List<RecipePreview> _filteredRecipes = [];
  Timer? _debounceTimer;
  final TextEditingController _searchController = TextEditingController();
  final AuthApi _authApi = AuthApi();

  @override
  void initState() {
    super.initState();
    _fetchRecipes();
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
    _refreshRecipes();
  }

  Future<void> _refreshRecipes() async {
    await _fetchRecipes();
    _applyFilters();
  }

  void _applyFilters() {
    switch (_tabIndex) {
      case 0: // All Recipes
        _filteredRecipes = _allRecipes;
        break;
      case 1: // Recent Recipes
        _filteredRecipes = _allRecipes
            .where((recipe) => recipe.last_visited_at != null)
            .toList()
          ..sort((a, b) => b.last_visited_at!.compareTo(a.last_visited_at!));
        break;
      case 2: // Favorites
        _filteredRecipes =
            _allRecipes.where((recipe) => recipe.is_favorite == true).toList();
        break;
    }
    _filteredRecipes.sort((a, b) => a.title.compareTo(b.title));

    setState(() {});
  }

  Future<void> _fetchRecipes() async {
    final recipes = await RecipeApi().fetchRecipes();
    recipes.sort((a, b) => a.title.compareTo(b.title));

    setState(() {
      _allRecipes = recipes;
      _filteredRecipes = recipes;
    });
  }

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer?.cancel();
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        if (query.isEmpty) {
          _filteredRecipes = _allRecipes;
        } else {
          _filteredRecipes = _allRecipes
              .where((recipe) =>
                  recipe.title.toLowerCase().contains(query.toLowerCase()) ||
                  (recipe.tags ?? []).any(
                      (tag) => tag.toLowerCase().contains(query.toLowerCase())))
              .toList();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Recipes',
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateRecipePage(),
                ),
              );
            },
            icon: const FaIcon(
              FontAwesomeIcons.plus,
              color: ColorPalette.offWhite,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
          ),
          IconButton(
            onPressed: () async {
              await _authApi.logout();
              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.logout,
              size: 32,
              color: ColorPalette.offWhite,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/recipes_page_background.png',
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
                      style: TextStyle(
                        color: ColorPalette.offWhite,
                      ),
                      decoration: InputDecoration(
                        icon: const Icon(
                          Icons.search,
                          color: ColorPalette.offWhite,
                        ),
                        hintText: 'Search for a recipe',
                        hintStyle: TextStyle(
                          color: ColorPalette.placeholdergray,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
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
                    _buildTab('Recent', 1),
                    _buildTab('Favorites', 2),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Container(
                    height: 1,
                    color: Colors.grey[400],
                  ),
                ),
                Expanded(
                  child: _filteredRecipes.isEmpty
                      ? Center(child: Text('No recipes found.'))
                      : ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: _filteredRecipes.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical:8.0, horizontal: 16.0),
                                child: Text(
                                  'Showing ${_filteredRecipes.length} recipes',
                                  style: TextStyle(
                                    color: ColorPalette.offWhite,
                                    fontSize: 18,
                                  ),
                                ),
                              );
                            } else {
                              final recipe = _filteredRecipes[index - 1];
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  RecipeTile(recipe: recipe),
                                ],
                              );
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
                SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
