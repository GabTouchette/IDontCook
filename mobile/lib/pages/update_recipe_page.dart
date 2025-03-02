import 'package:flutter/material.dart';
import 'package:i_cant_cook/api/recipe_api.dart';
import 'package:i_cant_cook/models/recipe/recipe.dart';
import 'package:i_cant_cook/widgets/toasts/information_toast.dart';
import 'package:i_cant_cook/widgets/recipes/recipe_form_extra_section.dart';
import 'package:i_cant_cook/widgets/recipes/recipe_form_ingredients_section.dart';
import 'package:i_cant_cook/widgets/recipes/recipe_form_instructions_section.dart';
import 'package:i_cant_cook/widgets/recipes/recipe_form_tags_section.dart';
import 'package:i_cant_cook/widgets/recipes/recipe_form_time_section.dart';
import 'package:i_cant_cook/widgets/recipes/recipe_form_title_section.dart';
import 'package:i_cant_cook/models/recipe_form_fields/recipe_form_fields.dart';
import 'package:i_cant_cook/theme/colors.dart';

class UpdateRecipePage extends StatefulWidget {
  final int recipeId;

  const UpdateRecipePage({Key? key, required this.recipeId}) : super(key: key);

  @override
  _UpdateRecipePageState createState() => _UpdateRecipePageState();
}

class _UpdateRecipePageState extends State<UpdateRecipePage> {
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

  void _fetchRecipe() async {
    var response = await RecipeApi().getRecipeById(widget.recipeId);
    var recipe = Recipe.fromJson(response);

    setState(() {
      _titleController.text = recipe.title;
      _preptimeController.text = recipe.preparation_time?.toString() ?? '';
      _cooktimeController.text = recipe.cooking_time?.toString() ?? '';
      _descriptionController.text = recipe.description ?? '';
      _notesController.text = recipe.notes ?? '';

      _ingredients = (recipe.ingredients).map<IngredientField>((ingredient) {
        return IngredientField(
          controller: TextEditingController(
              text: "${ingredient.quantity} ${ingredient.name}"),
          focusNode: FocusNode(),
        );
      }).toList();

      _ingredients.add(IngredientField(
        controller: TextEditingController(),
        focusNode: FocusNode(),
      ));

      _instructions =
          (recipe.instructions).map<InstructionField>((instruction) {
        return InstructionField(
          controller: TextEditingController(text: instruction),
          focusNode: FocusNode(),
        );
      }).toList();

      _instructions.add(InstructionField(
        controller: TextEditingController(),
        focusNode: FocusNode(),
      ));

      _selectedTags = List<String>.from(recipe.tags ?? []);
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchRecipe();
  }

  bool _isNumber(String str) {
    return double.tryParse(str) != null;
  }

  void _submitUpdatedRecipe() async {
    String title = _titleController.text;
    List<Map<String, String>> ingredients = _ingredients
        .map((field) {
          String text = field.controller.text.trim();
          if (text.isEmpty) {
            return {};
          }

          List<String> parts = text.split(" ");

          if (!_isNumber(parts[0])) {
            return {
              "quantity": "1",
              "name": parts.join(" "),
            };
          }
          if (parts.length == 2) {
            return {
              "quantity": parts[0],
              "name": parts[1],
            };
          }
          if (parts.length >= 3) {
            return {
              "quantity": parts[0],
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

    bool success = await RecipeApi().updateRecipe(widget.recipeId, recipeData);

    InformationToast.show(
      context: context,
      message: success
          ? 'Your recipe has been successfully updated!'
          : 'There was an error updating your recipe.',
      textColor: success ? ColorPalette.green : ColorPalette.red,
    );

    Navigator.pop(context);
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
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Update Recipe',
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
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        return Stack(
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
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
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
                      onTagsChanged: _onTagsChanged,
                    ),
                    ExtraSection(
                      descriptionController: _descriptionController,
                      notesController: _notesController,
                    ),
                    _buildUpdateButton(),
                    SizedBox(height: 32.0),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildUpdateButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Container(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _submitUpdatedRecipe,
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
                Icons.edit,
                color: ColorPalette.offWhite,
                size: 24,
              ),
              SizedBox(width: 8.0),
              Text(
                "Update",
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
