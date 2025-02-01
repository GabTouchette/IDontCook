import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mobile/api/recipe_api.dart';
import 'package:mobile/components/recipe_form/recipe_form_extra_section.dart';
import 'package:mobile/components/recipe_form/recipe_form_ingredients_section.dart';
import 'package:mobile/components/recipe_form/recipe_form_instructions_section.dart';
import 'package:mobile/components/recipe_form/recipe_form_tags_section.dart';
import 'package:mobile/components/recipe_form/recipe_form_time_section.dart';
import 'package:mobile/components/recipe_form/recipe_form_title_section.dart';
import 'package:mobile/theme/colors.dart';
import 'package:mobile/models/recipe_form_fields.dart';

class CreateRecipePage extends StatefulWidget {
  const CreateRecipePage({super.key});

  @override
  _CreateRecipePageState createState() => _CreateRecipePageState();
}

class _CreateRecipePageState extends State<CreateRecipePage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _preptimeController = TextEditingController();
  final TextEditingController _cooktimeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  List<IngredientField> _ingredients = [
    IngredientField(controller: TextEditingController(), focusNode: FocusNode())
  ];

  List<InstructionField> _instructions = [
    InstructionField(
        controller: TextEditingController(), focusNode: FocusNode())
  ];

  List<String> _selectedTags = [];
  List<String> _tagOptions = [
    'Vegetarian',
    'Gluten-Free',
    'Quick',
    'Low Carb',
    'Vegan',
    'Keto',
    'Dairy-Free',
    'Paleo',
    'High Protein',
    'Nut-Free',
    'Sugar-Free',
    'Healthy',
    'Low Fat',
    'High Fiber',
    'Meal Prep',
  ];

  @override
  void dispose() {
    for (var ingredient in _ingredients) {
      ingredient.controller.dispose();
      ingredient.focusNode.dispose();
    }

    for (var instruction in _instructions) {
      instruction.controller.dispose();
      instruction.focusNode.dispose();
    }

    super.dispose();
  }

  bool _isNumber(String str) {
    return double.tryParse(str) != null;
  }

  void _submitRecipe() async {
    String title = _titleController.text;
    List<Map<String, String>> ingredients = _ingredients
        .map((field) {
          List<String> parts = field.controller.text.split(" ");

          if (parts.isEmpty) {
            return {};
          }

          if (!_isNumber(parts[0])) {
            return {
              "quantity": "1",
              "unit_of_measure": "",
              "name": parts.join(" "),
            };
          }

          if (parts.length == 2) {
            return {
              "quantity": parts[0],
              "unit_of_measure": "unit",
              "name": parts[1],
            };
          }

          if (parts.length >= 3) {
            return {
              "quantity": parts[0],
              "unit_of_measure": parts[1],
              "name": parts.sublist(2).join(" "),
            };
          }

          return {};
        })
        .where((ingredient) => ingredient.isNotEmpty)
        .cast<Map<String, String>>()
        .toList();

    List<String> instructions = _instructions
        .map((field) => field.controller.text)
        .where((instruction) => instruction.isNotEmpty)
        .toList();

    int prepTime = int.tryParse(_preptimeController.text) ?? 0;
    int cookTime = int.tryParse(_cooktimeController.text) ?? 0;
    String desc = _descriptionController.text;
    String notes = _notesController.text;

    Map<String, dynamic> recipeData = {
      "title": title,
      "ingredients": ingredients,
      "instructions": instructions,
      "preparation_time": prepTime,
      "cooking_time": cookTime,
      "description": desc,
      "notes": notes,
      "tags": _selectedTags,
    };

    bool success = await RecipeApi().createRecipe(recipeData);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(success ? 'Recipe Submitted' : 'Submission Failed'),
        content: Text(success
            ? 'Your recipe has been successfully submitted!'
            : 'There was an error submitting your recipe.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (success) Navigator.pop(context);
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _onIngredientsChanged(List<IngredientField> ingredients) {
    setState(() {
      _ingredients = ingredients;
    });
  }

  void _onInstructionsChanged(List<InstructionField> instructions) {
    setState(() {
      _instructions = instructions;
    });
  }

  void _onTagsChanged(List<String> selectedTags) {
    setState(() {
      _selectedTags = selectedTags;
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
          'Create Recipe',
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
              'assets/images/create_recipe_page_background.png',
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 120.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TitleSection(titleController: _titleController),
                  IngredientsSection(
                    ingredients: _ingredients,
                    onIngredientsChanged: _onIngredientsChanged,
                  ),
                  InstructionsSection(
                    instructions: _instructions,
                    onInstructionsChanged: _onInstructionsChanged,
                  ),
                  TimeSection(
                    prepTimeController: _preptimeController,
                    cookTimeController: _cooktimeController,
                  ),
                  TagsSection(
                    selectedTags: _selectedTags,
                    tagOptions: _tagOptions,
                    onTagsChanged: _onTagsChanged,
                  ),
                  ExtraSection(
                    descriptionController: _descriptionController,
                    notesController: _notesController,
                  ),
                  _buildCreateButton(),
                  SizedBox(height: 32.0),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Container(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _submitRecipe,
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorPalette.darkgray,
            padding: EdgeInsets.symmetric(vertical: 12.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add,
                color: ColorPalette.offWhite,
                size: 24,
              ),
              SizedBox(width: 8.0),
              Text(
                "Create",
                style: TextStyle(
                  color: ColorPalette.offWhite,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
