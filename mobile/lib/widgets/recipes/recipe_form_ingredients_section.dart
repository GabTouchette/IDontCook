
import 'package:flutter/material.dart';
import 'package:mobile/models/recipe_form_fields/recipe_form_fields.dart';
import 'package:mobile/theme/colors.dart';

class IngredientsSection extends StatefulWidget {
  final List<IngredientField> ingredients;
  final ValueChanged<List<IngredientField>> onIngredientsChanged;

  const IngredientsSection({
    Key? key,
    required this.ingredients,
    required this.onIngredientsChanged,
  }) : super(key: key);

  @override
  _IngredientsSectionState createState() => _IngredientsSectionState();
}

class _IngredientsSectionState extends State<IngredientsSection> {
  List<Widget> _buildIngredientsInputFields() {
    List<Widget> inputFields = [];

    for (int i = 0; i < widget.ingredients.length; i++) {
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
                    controller: widget.ingredients[i].controller,
                    focusNode: widget.ingredients[i].focusNode,
                    style: TextStyle(
                      color: ColorPalette.offBlack,
                    ),
                    onChanged: (text) {
                      if (i == widget.ingredients.length - 1 && text.isNotEmpty) {
                        setState(() {
                          widget.ingredients.add(IngredientField(
                              controller: TextEditingController(),
                              focusNode: FocusNode()));
                        });
                        widget.onIngredientsChanged(widget.ingredients);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Ingredient',
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
                onPressed: widget.ingredients.length > 1
                    ? () {
                        setState(() {
                          widget.ingredients.removeAt(i);
                        });
                        widget.onIngredientsChanged(widget.ingredients);
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

  @override
  Widget build(BuildContext context) {
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
              "Enter in format: Qty Unit Ingredient (e.g., 100 g sugar, 1.75 cups flour)",
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
}