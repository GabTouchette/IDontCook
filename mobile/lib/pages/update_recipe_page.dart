import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/api/recipe_api.dart';
import 'package:i_cant_cook/models/recipe/recipe.dart';
import 'package:i_cant_cook/utils/recipe_submit_utils.dart';
import 'package:i_cant_cook/widgets/recipes/recipe_form_extra_section.dart';
import 'package:i_cant_cook/widgets/meal_planning/meal_ingredients_section.dart';
import 'package:i_cant_cook/widgets/recipes/recipe_form_instructions_section.dart';
import 'package:i_cant_cook/widgets/recipes/recipe_form_tags_section.dart';
import 'package:i_cant_cook/widgets/recipes/recipe_form_time_section.dart';
import 'package:i_cant_cook/widgets/recipes/recipe_form_title_section.dart';
import 'package:i_cant_cook/models/recipe_form_fields/recipe_form_fields.dart';

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

  // Drawer-style meal ingredient UI entries
  List<MealIngredient> _mealIngredients = [];

  List<InstructionField> _instructions = [
    InstructionField(
        controller: TextEditingController(), focusNode: FocusNode())
  ];

  List<String> _selectedTags = [];

  @override
  void dispose() {
    // No controllers to dispose for MealIngredients list
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

      _mealIngredients = (recipe.ingredients).map<MealIngredient>((ingredient) {
        return MealIngredient(
          quantity: (ingredient.quantity ?? '').toString(),
          unit: ingredient.unit ?? '',
          name: ingredient.name ?? '',
          description: '',
          canonicalId: ingredient.canonical,
        );
      }).toList();

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
    final ingredients = _mealIngredients.map((ing) {
      final m = <String, dynamic>{
        if (ing.quantity.trim().isNotEmpty) 'quantity': ing.quantity.trim(),
        'unit': ing.unit,
        'name': ing.name,
        if (ing.description.trim().isNotEmpty)
          'preparation': ing.description.trim(),
      };
      if (ing.canonicalId != null) m['canonical_id'] = ing.canonicalId;
      return m;
    }).toList();

    final instructions = _instructions
        .map((f) => f.controller.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final recipeData = {
      'title': _titleController.text.trim(),
      'ingredients': ingredients,
      'instructions': instructions,
      'preparation_time': int.tryParse(_preptimeController.text) ?? 0,
      'cooking_time': int.tryParse(_cooktimeController.text) ?? 0,
      'description': _descriptionController.text.trim(),
      'notes': _notesController.text.trim(),
      'tags': _selectedTags,
    };

    submitRecipe(
      context: context,
      recipeData: recipeData,
      isUpdate: true,
      recipeId: widget.recipeId,
    );
  }

  void _onMealIngredientsChanged(List<MealIngredient> ingredients) {
    setState(() => _mealIngredients = List.of(ingredients));
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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.close,
            size: 28,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        title: Text(
          'UPDATE RECIPE',
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: 2,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: GestureDetector(
              onTap: _submitUpdatedRecipe,
              child: Container(
                width: 36,
                height: 36,
                color: const Color(0xFFCAFF00),
                child: const Icon(
                  Icons.check,
                  size: 18,
                  color: Color(0xFF0A0A0A),
                ),
              ),
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
              Divider(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.12),
                thickness: 1,
                height: 1,
              ),
              MealIngredientsSection(
                label: 'Ingredient',
                ingredients: _mealIngredients,
                onChanged: _onMealIngredientsChanged,
              ),
              const SizedBox(height: 8),
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
