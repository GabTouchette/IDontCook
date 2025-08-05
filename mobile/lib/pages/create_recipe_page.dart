import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
// Removed nutrition_service import - no longer needed
import 'package:i_cant_cook/utils/recipe_submit_utils.dart';
import 'package:i_cant_cook/widgets/recipes/camera_capture.dart';
import 'package:i_cant_cook/widgets/recipes/recipe_form_extra_section.dart';
import 'package:i_cant_cook/widgets/recipes/recipe_form_ingredients_section.dart';
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

  void _openCamera(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CameraCaptureWidget(),
    );
  }

  void _submitRecipe() {
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
      isUpdate: false,
    );
  }

  void _onIngredientsChanged(List<IngredientField> ingredients) {
    setState(() {
      _ingredients = ingredients;
    });

    // Removed nutrition preview calculation - handled on backend after save
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
        scrolledUnderElevation: 4,
        shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            'Create Recipe',
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w900,
              fontSize: 24,
              color: Theme.of(context).colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
          ),
        ),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(
              Icons.chevron_left,
              size: 28,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              onPressed: () => _openCamera(context),
              icon: FaIcon(
                FontAwesomeIcons.camera,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
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
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _submitRecipe,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 18.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 24,
              ),
              const SizedBox(width: 12.0),
              Text(
                "Create Recipe",
                style: GoogleFonts.nunito(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
