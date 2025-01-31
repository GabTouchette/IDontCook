import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
  final TextEditingController _ingredientsController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();

  List<_IngredientField> _ingredientsList = [
    _IngredientField(
        controller: TextEditingController(), focusNode: FocusNode())
  ];

  List<_InstructionField> _instructionsList = [
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
    for (var ingredient in _ingredientsList) {
      ingredient.controller.dispose();
      ingredient.focusNode.dispose();
    }

    for (var instruction in _instructionsList) {
      instruction.controller.dispose();
      instruction.focusNode.dispose();
    }

    super.dispose();
  }

  void _submitRecipe() {
    String title = _titleController.text;
    String ingredients = _ingredientsController.text;
    String instructions = _instructionsController.text;
    String preptime = _preptimeController.text;
    String cooktime = _cooktimeController.text;
    String desc = _descriptionController.text;
    String notes = _notesController.text;

    print("Recipe Title: $title");
    print("Ingredients: $ingredients");
    print("Instructions: $instructions");
    print("Prep Time: $preptime");
    print("Cook Time: $cooktime");
    print("Desc: $desc");
    print("Notes: $notes");
    print("Tags: $_tagOptions");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Recipe Submitted'),
        content: Text('Your recipe has been successfully submitted!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
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

    for (int i = 0; i < _ingredientsList.length; i++) {
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
                    controller: _ingredientsList[i].controller,
                    focusNode: _ingredientsList[i].focusNode,
                    style: TextStyle(
                      color: ColorPalette.offBlack,
                    ),
                    onChanged: (text) {},
                    onEditingComplete: () {
                      if (i == _ingredientsList.length - 1 &&
                          _ingredientsList[i].controller.text.isNotEmpty) {
                        setState(() {
                          _ingredientsList.add(_IngredientField(
                              controller: TextEditingController(),
                              focusNode: FocusNode()));
                        });

                        FocusScope.of(context)
                            .requestFocus(_ingredientsList[i + 1].focusNode);
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
                onPressed: _ingredientsList.length > 1
                    ? () {
                        setState(() {
                          _ingredientsList.removeAt(i);
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

    for (int i = 0; i < _instructionsList.length; i++) {
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
                    controller: _instructionsList[i].controller,
                    focusNode: _instructionsList[i].focusNode,
                    style: TextStyle(
                      color: ColorPalette.offBlack,
                    ),
                    onChanged: (text) {},
                    onEditingComplete: () {
                      if (i == _instructionsList.length - 1 &&
                          _instructionsList[i].controller.text.isNotEmpty) {
                        setState(() {
                          _instructionsList.add(_InstructionField(
                              controller: TextEditingController(),
                              focusNode: FocusNode()));
                        });

                        FocusScope.of(context)
                            .requestFocus(_instructionsList[i + 1].focusNode);
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
                onPressed: _instructionsList.length > 1
                    ? () {
                        setState(() {
                          _instructionsList.removeAt(i);
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
