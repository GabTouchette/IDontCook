import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mobile/api/recipe_api.dart';
import 'package:mobile/components/recipe_tile.dart';
import 'package:mobile/pages/create_recipe_page.dart';
import 'package:mobile/theme/colors.dart';
import 'package:mobile/models/recipe.dart';

class RecipesPage extends StatefulWidget {
  const RecipesPage({super.key});

  @override
  _RecipesPageState createState() => _RecipesPageState();
}

class _RecipesPageState extends State<RecipesPage> {
  int _tabIndex = 0;

  List<Recipe> _allRecipes = [];
  List<Recipe> _filteredRecipes = [];
  Timer? _debounceTimer;
  final TextEditingController _searchController = TextEditingController();

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
  }

  Future<void> _fetchRecipes() async {
    final recipes = await RecipeApi().fetchRecipes();
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
                  recipe.title!.toLowerCase().contains(query.toLowerCase()) ||
                  recipe.description!
                      .toLowerCase()
                      .contains(query.toLowerCase()))
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
            onPressed: () {},
            icon: const FaIcon(
              FontAwesomeIcons.camera,
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
            padding: const EdgeInsets.only(top: 120.0),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    decoration: BoxDecoration(
                      color: ColorPalette.darkgray,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: ColorPalette.placeholdergray),
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
                      ),
                      onChanged: _onSearchChanged,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildTab('All', 0),
                        _buildTab('Recent', 1),
                        _buildTab('Tags', 2),
                        _buildTab('Categories', 3),
                      ],
                    ),
                  ),
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
                          itemCount: _filteredRecipes.length,
                          itemBuilder: (context, index) {
                            final recipe = _filteredRecipes[index];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RecipeTile(
                                  id: recipe.id ?? 0,
                                  title: recipe.title ?? "",
                                  imageUrl: recipe.image_url ?? "",
                                  preparationTime: recipe.preparation_time,
                                  cookingTime: recipe.cooking_time,
                                  ingredients: recipe.ingredients,
                                  instructions: recipe.instructions,
                                  tags: recipe.tags,
                                ),
                              ],
                            );
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
    return GestureDetector(
      onTap: () => _onTabTapped(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 12.0),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color:
                    isSelected ? ColorPalette.offWhite : ColorPalette.darkgray,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
