import 'package:flutter/material.dart';
import 'package:i_cant_cook/models/recipe_form_fields/recipe_form_fields.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/api/recipe_api.dart';

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
              child: _IngredientRow(
                field: widget.ingredients[i],
                onNewRowNeeded: () {
                  if (i == widget.ingredients.length - 1) {
                    setState(() {
                      widget.ingredients.add(IngredientField(
                        controller: TextEditingController(),
                        focusNode: FocusNode(),
                      ));
                    });
                    widget.onIngredientsChanged(widget.ingredients);
                  }
                },
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
                "Quantity • Unit • Name • Description",
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

class _IngredientTypeaheadField extends StatefulWidget {
  final IngredientField field;
  final VoidCallback onNewRowNeeded;

  const _IngredientTypeaheadField(
      {required this.field, required this.onNewRowNeeded});

  @override
  State<_IngredientTypeaheadField> createState() =>
      _IngredientTypeaheadFieldState();
}

class _IngredientTypeaheadFieldState extends State<_IngredientTypeaheadField> {
  final RecipeApi _api = RecipeApi();
  List<Map<String, dynamic>> _suggestions = [];
  bool _loading = false;

  void _onChanged(String text) async {
    // Trigger adding a new row on first non-empty text
    if (text.isNotEmpty) {
      widget.onNewRowNeeded();
    }
    if (text.trim().isEmpty) {
      setState(() {
        _suggestions = [];
      });
      return;
    }
    setState(() {
      _loading = true;
    });
    final res = await _api.autocompleteCanonicalIngredients(text, limit: 5);
    if (mounted) {
      setState(() {
        _suggestions = res;
        _loading = false;
      });
    }
  }

  void _select(Map<String, dynamic> item) {
    final en = (item['canonical_name_en'] ?? '').toString();
    widget.field.controller.text = en;
    widget.field.nameController.text = en;
    widget.field.canonicalId = item['id'] as int?;
    widget.field.canonicalName = en;
    setState(() {
      _suggestions = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        TextField(
          controller: widget.field.controller,
          focusNode: widget.field.focusNode,
          style: GoogleFonts.nunito(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          onChanged: _onChanged,
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
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14.0),
            suffixIcon: _loading
                ? Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : null,
          ),
        ),
        if (_suggestions.isNotEmpty)
          Positioned(
            left: 0,
            right: 0,
            top: 50,
            child: Material(
              elevation: 3,
              borderRadius: BorderRadius.circular(8),
              color: Theme.of(context).colorScheme.surface,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  final s = _suggestions[index];
                  final en = (s['canonical_name_en'] ?? '').toString();
                  final fr = (s['canonical_name_fr'] ?? '').toString();
                  return InkWell(
                    onTap: () => _select(s),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12.0, vertical: 10.0),
                      child: Row(
                        children: [
                          Icon(Icons.search,
                              size: 16,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              fr.isNotEmpty ? '$en  •  $fr' : en,
                              style: GoogleFonts.nunito(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _IngredientRow extends StatelessWidget {
  final IngredientField field;
  final VoidCallback onNewRowNeeded;

  const _IngredientRow({required this.field, required this.onNewRowNeeded});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 72,
              child: TextField(
                controller: field.qtyController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: 'Qty',
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _UnitDropdown(
              value: field.unit,
              onChanged: (v) => field.unit = v ?? '',
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withOpacity(0.7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.15)),
                ),
                child: _IngredientTypeaheadField(
                  field: field,
                  onNewRowNeeded: onNewRowNeeded,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: field.descController,
          decoration: InputDecoration(
            hintText: 'Description (e.g., chopped, room temp, for garnish)',
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }
}

class _UnitDropdown extends StatefulWidget {
  final String value;
  final ValueChanged<String?> onChanged;
  const _UnitDropdown({required this.value, required this.onChanged});

  @override
  State<_UnitDropdown> createState() => _UnitDropdownState();
}

class _UnitDropdownState extends State<_UnitDropdown> {
  static const units = [
    '',
    'piece',
    'clove',
    'slice',
    'tsp',
    'tbsp',
    'cup',
    'oz',
    'lb',
    'g',
    'kg',
    'ml',
    'l'
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.15)),
      ),
      child: DropdownButton<String>(
        value: units.contains(widget.value) ? widget.value : '',
        underline: const SizedBox.shrink(),
        isDense: true,
        items: units
            .map((u) => DropdownMenuItem(
                  value: u,
                  child: Text(u.isEmpty ? '—' : u),
                ))
            .toList(),
        onChanged: (v) => setState(() => widget.onChanged(v)),
      ),
    );
  }
}
