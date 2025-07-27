import 'package:flutter/material.dart';
import 'package:i_cant_cook/models/recipe_form_fields/recipe_form_fields.dart';
import 'package:google_fonts/google_fonts.dart';

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
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    "${i + 1}",
                    style: GoogleFonts.nunito(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  child: TextField(
                    controller: widget.ingredients[i].controller,
                    focusNode: widget.ingredients[i].focusNode,
                    style: GoogleFonts.nunito(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    onChanged: (text) {
                      if (i == widget.ingredients.length - 1 &&
                          text.isNotEmpty) {
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
                      hintStyle: GoogleFonts.nunito(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16.0),
                    ),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.error.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.delete,
                    color: Theme.of(context).colorScheme.error,
                    size: 20,
                  ),
                  onPressed: widget.ingredients.length > 1
                      ? () {
                          setState(() {
                            widget.ingredients.removeAt(i);
                          });
                          widget.onIngredientsChanged(widget.ingredients);
                        }
                      : null,
                ),
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
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Ingredients",
              style: GoogleFonts.nunito(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 20,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 16.0),
            ..._buildIngredientsInputFields(),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                "Enter in format: Qty Unit Ingredient (e.g., 100 g sugar, 1.75 cups flour)",
                style: GoogleFonts.nunito(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
