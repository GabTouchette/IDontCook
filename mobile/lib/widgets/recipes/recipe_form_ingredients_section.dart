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
          padding: const EdgeInsets.only(bottom: 10.0),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            // Number badge - smaller and lighter
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  "${i + 1}",
                  style: GoogleFonts.nunito(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10.0),
            // Text field - expanded to take more space
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withOpacity(0.7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color:
                        Theme.of(context).colorScheme.outline.withOpacity(0.15),
                  ),
                ),
                child: TextField(
                  controller: widget.ingredients[i].controller,
                  focusNode: widget.ingredients[i].focusNode,
                  style: GoogleFonts.nunito(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
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
                    hintText: 'e.g., 2 cups flour',
                    hintStyle: GoogleFonts.nunito(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withOpacity(0.7),
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 14.0),
                  ),
                ),
              ),
            ),
            // Delete button - smaller and more subtle, no extra padding
            SizedBox(
              width: 32,
              height: 24,
              child: IconButton(
                padding: const EdgeInsets.only(bottom: 4.0, left: 12.0),
                iconSize: 24,
                constraints: const BoxConstraints(),
                icon: Icon(
                  Icons.delete,
                  color: Theme.of(context).colorScheme.error.withOpacity(0.8),
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
          ]),
        ),
      );
    }

    return inputFields;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Container(
        padding: const EdgeInsets.all(18.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.restaurant_menu,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  "Ingredients",
                  style: GoogleFonts.nunito(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14.0),
            ..._buildIngredientsInputFields(),
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text(
                "Format: quantity unit ingredient (e.g., 2 cups flour, 1 tbsp salt)",
                style: GoogleFonts.nunito(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withOpacity(0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
