import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mobile/api_service.dart';
import 'package:mobile/theme/colors.dart';

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

  List<_IngredientField> _ingredients = [
    _IngredientField(
        controller: TextEditingController(), focusNode: FocusNode())
  ];

  List<_InstructionField> _instructions = [
    _InstructionField(
        controller: TextEditingController(), focusNode: FocusNode())
  ];

  List<String> _selectedTags = [];
  String? _selectedTag;
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
          // Case 1: If it doesn't start with a number, treat the whole thing as the ingredient name
          if (!_isNumber(parts[0])) {
            return {
              "quantity": "1", // Default quantity
              "unit_of_measure": "", // Default unit
              "name": parts.join(" "), // Treat all parts as the ingredient name
            };
          }

          // Case 2: If there are exactly two parts, the first one is the quantity and the second one is the ingredient name
          if (parts.length == 2) {
            return {
              "quantity": parts[0],
              "unit_of_measure": "unit", // Default unit
              "name": parts[1],
            };
          }

          // Case 3: If there are three or more parts, assume the first is the quantity, the second is the unit, and the rest is the ingredient name
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
        .where((instruction) =>
            instruction.isNotEmpty)
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

    print("Submitting Recipe: $recipeData");

    bool success = await ApiService().createRecipe(recipeData);

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
                  _buildTitleSection(),
                  _buildIngredientsSection(),
                  _buildInstructionsSection(),
                  _buildTimeSection(),
                  _buildTagsSection(),
                  _buildExtraSection(),
                  _buildCreateButton(),
                  SizedBox(height: 32.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Title",
            style: TextStyle(
              color: ColorPalette.offWhite,
              fontWeight: FontWeight.w300,
              fontSize: 24,
            ),
          ),
          SizedBox(height: 8.0),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            decoration: BoxDecoration(
              color: ColorPalette.lightgray,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: _titleController,
              style: TextStyle(
                color: ColorPalette.offBlack,
              ),
              decoration: InputDecoration(
                hintText: 'Recipe title',
                hintStyle: TextStyle(
                  color: ColorPalette.placeholdergray,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Ingredients",
            style: TextStyle(
              color: ColorPalette.offWhite,
              fontWeight: FontWeight.w300,
              fontSize: 24,
            ),
          ),
          SizedBox(height: 8.0),
          ..._buildIngredientsInputFields(),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              "Enter in format: Qty Unit Ingredient (e.g., 100 g sugar)",
              style: TextStyle(
                color: ColorPalette.offWhite.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildIngredientsInputFields() {
    List<Widget> inputFields = [];

    for (int i = 0; i < _ingredients.length; i++) {
      inputFields.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            children: [
              Text(
                "${i + 1}.",
                style: TextStyle(
                  color: ColorPalette.offWhite,
                  fontSize: 18,
                ),
              ),
              SizedBox(width: 8.0),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  decoration: BoxDecoration(
                    color: ColorPalette.lightgray,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _ingredients[i].controller,
                    focusNode: _ingredients[i].focusNode,
                    style: TextStyle(
                      color: ColorPalette.offBlack,
                    ),
                    onChanged: (text) {
                      if (i == _ingredients.length - 1 && text.isNotEmpty) {
                        setState(() {
                          _ingredients.add(_IngredientField(
                              controller: TextEditingController(),
                              focusNode: FocusNode()));
                        });
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Ingredient (e.g., 100 g sugar)',
                      hintStyle: TextStyle(
                        color: ColorPalette.placeholdergray,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12.0),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete, color: ColorPalette.offWhite),
                onPressed: _ingredients.length > 1
                    ? () {
                        setState(() {
                          _ingredients.removeAt(i);
                        });
                      }
                    : null,
              ),
            ],
          ),
        ),
      );
    }

    return inputFields;
  }

  Widget _buildInstructionsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Instructions",
            style: TextStyle(
              color: ColorPalette.offWhite,
              fontWeight: FontWeight.w300,
              fontSize: 24,
            ),
          ),
          SizedBox(height: 8.0),
          ..._buildInstructionsInputFields(),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              "Enter each instruction step by step.",
              style: TextStyle(
                color: ColorPalette.offWhite.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildInstructionsInputFields() {
    List<Widget> inputFields = [];

    for (int i = 0; i < _instructions.length; i++) {
      inputFields.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            children: [
              Text(
                "${i + 1}.",
                style: TextStyle(
                  color: ColorPalette.offWhite,
                  fontSize: 18,
                ),
              ),
              SizedBox(width: 8.0),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  decoration: BoxDecoration(
                    color: ColorPalette.lightgray,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _instructions[i].controller,
                    focusNode: _instructions[i].focusNode,
                    maxLines: 4,
                    style: TextStyle(
                      color: ColorPalette.offBlack,
                    ),
                    onChanged: (text) {
                      if (i == _instructions.length - 1 && text.isNotEmpty) {
                        setState(() {
                          _instructions.add(_InstructionField(
                              controller: TextEditingController(),
                              focusNode: FocusNode()));
                        });
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Instruction',
                      hintStyle: TextStyle(
                        color: ColorPalette.placeholdergray,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12.0),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete, color: ColorPalette.offWhite),
                onPressed: _instructions.length > 1
                    ? () {
                        setState(() {
                          _instructions.removeAt(i);
                        });
                      }
                    : null,
              ),
            ],
          ),
        ),
      );
    }

    return inputFields;
  }

  Widget _buildTimeSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Time",
            style: TextStyle(
              color: ColorPalette.offWhite,
              fontWeight: FontWeight.w300,
              fontSize: 24,
            ),
          ),
          SizedBox(height: 8.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  decoration: BoxDecoration(
                    color: ColorPalette.lightgray,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _preptimeController,
                    style: TextStyle(
                      color: ColorPalette.offBlack,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Prep Time (min)',
                      hintStyle: TextStyle(
                        color: ColorPalette.placeholdergray,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12.0),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ),
              SizedBox(width: 16.0),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  decoration: BoxDecoration(
                    color: ColorPalette.lightgray,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _cooktimeController,
                    style: TextStyle(
                      color: ColorPalette.offBlack,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Cook Time (min)',
                      hintStyle: TextStyle(
                        color: ColorPalette.placeholdergray,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12.0),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Tags",
            style: TextStyle(
              color: ColorPalette.offWhite,
              fontWeight: FontWeight.w300,
              fontSize: 24,
            ),
          ),
          SizedBox(height: 8.0),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              filled: true,
              fillColor: ColorPalette.lightgray,
              contentPadding:
                  EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            hint: Text('Select tags'),
            value: _selectedTag,
            onChanged: (String? newValue) {
              setState(() {
                _selectedTag = newValue;
                if (_selectedTag != null &&
                    !_selectedTags.contains(_selectedTag)) {
                  _selectedTags.add(_selectedTag!);
                }
              });
            },
            items: _tagOptions.map((String tag) {
              return DropdownMenuItem<String>(
                value: tag,
                child: Text(tag),
              );
            }).toList(),
          ),
          SizedBox(height: 16.0),
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: _selectedTags.map((tag) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTags.remove(tag);
                  });
                },
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                  decoration: BoxDecoration(
                    color: ColorPalette.darkgray,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tag,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(width: 6.0),
                      Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildExtraSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Extra",
            style: TextStyle(
              color: ColorPalette.offWhite,
              fontWeight: FontWeight.w300,
              fontSize: 24,
            ),
          ),
          SizedBox(height: 8.0),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            decoration: BoxDecoration(
              color: ColorPalette.lightgray,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: _descriptionController,
              style: TextStyle(
                color: ColorPalette.offBlack,
              ),
              decoration: InputDecoration(
                hintText: 'Description',
                hintStyle: TextStyle(
                  color: ColorPalette.placeholdergray,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12.0),
              ),
            ),
          ),
          SizedBox(height: 32.0),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            decoration: BoxDecoration(
              color: ColorPalette.lightgray,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: _notesController,
              style: TextStyle(
                color: ColorPalette.offBlack,
              ),
              decoration: InputDecoration(
                hintText: 'Notes',
                hintStyle: TextStyle(
                  color: ColorPalette.placeholdergray,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12.0),
              ),
            ),
          ),
          SizedBox(height: 16.0),
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

class _IngredientField {
  TextEditingController controller;
  FocusNode focusNode;

  _IngredientField({required this.controller, required this.focusNode});
}

class _InstructionField {
  TextEditingController controller;
  FocusNode focusNode;

  _InstructionField({required this.controller, required this.focusNode});
}
