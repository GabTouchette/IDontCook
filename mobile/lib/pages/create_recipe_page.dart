import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// Removed nutrition_service import - no longer needed
import 'package:i_cant_cook/utils/recipe_submit_utils.dart';
import 'package:i_cant_cook/widgets/recipes/camera_capture.dart';
import 'package:i_cant_cook/widgets/recipes/recipe_form_extra_section.dart';
import 'package:i_cant_cook/widgets/meal_planning/meal_ingredients_section.dart';
import 'package:i_cant_cook/widgets/recipes/recipe_form_instructions_section.dart';
import 'package:i_cant_cook/widgets/recipes/recipe_form_tags_section.dart';
import 'package:i_cant_cook/widgets/recipes/recipe_form_time_section.dart';
import 'package:i_cant_cook/widgets/recipes/recipe_form_title_section.dart';
import 'package:i_cant_cook/models/recipe_form_fields/recipe_form_fields.dart';
// Removed provider import - no longer using NutritionProvider

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

  void _openCamera(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CameraCaptureWidget(),
    );
  }

  void _submitRecipe() {
    // Build payload using MealIngredientsSection state
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
      isUpdate: false,
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
      resizeToAvoidBottomInset: false,
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
          'CREATE RECIPE',
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
              onTap: () => _openCamera(context),
              child: Container(
                width: 40,
                height: 40,
                color: const Color(0xFF0A0A0A),
                child: const Icon(
                  Icons.camera_alt,
                  size: 20,
                  color: Color(0xFFCAFF00),
                ),
              ),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        return Stack(
          children: [
            Positioned.fill(
              child:
                  Container(color: Theme.of(context).scaffoldBackgroundColor),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
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
                    // Removed nutrition preview section - nutrition calculated on backend after save
                    TagsSection(
                      selectedTags: _selectedTags,
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
        );
      }),
    );
  }

  // Removed _buildNutritionPreviewSection - nutrition calculated on backend after save

  Widget _buildCreateButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: GestureDetector(
        onTap: _submitRecipe,
        child: Container(
          width: double.infinity,
          height: 52,
          color: const Color(0xFFCAFF00),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check, color: Color(0xFF0A0A0A), size: 20),
              const SizedBox(width: 10),
              Text(
                'CREATE RECIPE',
                style: GoogleFonts.spaceGrotesk(
                  color: const Color(0xFF0A0A0A),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
