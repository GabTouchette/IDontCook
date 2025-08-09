import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/api/recipe_api.dart';
import 'package:i_cant_cook/models/recipe/recipe.dart';
import 'package:i_cant_cook/utils/recipe_submit_utils.dart';
import 'package:i_cant_cook/widgets/recipes/recipe_form_extra_section.dart';
import 'package:i_cant_cook/widgets/recipes/recipe_form_ingredients_section.dart';
import 'package:i_cant_cook/widgets/recipes/recipe_form_instructions_section.dart';
import 'package:i_cant_cook/widgets/recipes/recipe_form_tags_section.dart';
import 'package:i_cant_cook/widgets/recipes/recipe_form_time_section.dart';
import 'package:i_cant_cook/widgets/recipes/recipe_form_title_section.dart';
import 'package:i_cant_cook/models/recipe_form_fields/recipe_form_fields.dart';
import 'package:i_cant_cook/theme/theme.dart';

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

  void _submitUpdatedRecipe() {
    final recipeData = buildRecipeDataFromForm(
      titleController: _titleController,
      instructionControllers: _instructions.map((f) => f.controller).toList(),
      ingredientFields: _ingredients,
      prepTimeController: _preptimeController,
      cookTimeController: _cooktimeController,
      descriptionController: _descriptionController,
      notesController: _notesController,
      selectedTags: _selectedTags,
    );

    submitRecipe(
      context: context,
      recipeData: recipeData,
      isUpdate: true,
      recipeId: widget.recipeId,
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Update Recipe',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w900,
            fontSize: 24,
            color: Theme.of(context).colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(
            Icons.chevron_left,
            size: 36,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              onPressed: _submitUpdatedRecipe,
              icon: Icon(
                Icons.check_box_outlined,
                size: 36,
                color: Theme.of(context).colorScheme.success,
              ),
              tooltip: 'Save',
            ),
          ),
        ],
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
              const SizedBox(height: 32.0),
            ],
          ),
        ),
      ),
    );
  }
}
