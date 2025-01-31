import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mobile/api_service.dart';
import 'package:mobile/components/navbar.dart';
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
  int _selectedIndex = 0;
  int _tabIndex = 0;

  Future<List<Recipe>>? _recipes;

  @override
  void initState() {
    super.initState();

    _recipes = ApiService().fetchRecipes();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onTabTapped(int index) {
    setState(() {
      _tabIndex = index;
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
                      border: Border.all(color: ColorPalette.offWhite),
                    ),
                    child: TextField(
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
                          color: ColorPalette.offWhite,
                        ),
                        border: InputBorder.none,
                      ),
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
                  child: FutureBuilder<List<Recipe>>(
                    future: _recipes,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(child: Text('No recipes available.'));
                      } else {
                        return ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            final recipe = snapshot.data![index];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RecipeTile(
                                  title: recipe.title ?? "",
                                  imageUrl: recipe.image_url ?? "",
                                  preparationTime: recipe.preparation_time,
                                  cookingTime: recipe.cooking_time,
                                  ingredients: recipe.ingredients,
                                  instructions: recipe.instructions,
                                ),
                              ],
                            );
                          },
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
      bottomNavigationBar: Navbar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
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
