import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:i_cant_cook/api/recipe_api.dart';

class MealIngredient {
  final String quantity;
  final String unit;
  final String name;
  final String description;
  final int? canonicalId;

  MealIngredient({
    required this.quantity,
    required this.unit,
    required this.name,
    required this.description,
    this.canonicalId,
  });

  @override
  String toString() {
    final q = quantity.trim();
    final u = unit.trim().toLowerCase();
    final n = name.trim().toLowerCase();
    final d = description.trim();
    final parts = <String>[];
    if (q.isNotEmpty) parts.add(q);
    if (u.isNotEmpty) parts.add(u);
    if (n.isNotEmpty) parts.add(n);
    final main = _sanitize(parts.join(' '));
    return d.isNotEmpty ? '$main — $d' : main;
  }

  static String _sanitize(String line) {
    final tokens = line.trim().split(RegExp(r'\s+'));
    if (tokens.isEmpty) return line;
    final deduped = <String>[];
    for (final token in tokens) {
      if (deduped.isEmpty || token.toLowerCase() != deduped.last.toLowerCase()) {
        deduped.add(token);
      }
    }
    final result = deduped.join(' ');
    if (result.isNotEmpty && !RegExp(r'^[\d½¼¾⅓⅔⅛⅜⅝⅞]').hasMatch(result)) {
      return '1 $result';
    }
    return result;
  }
}

class MealIngredientsSection extends StatefulWidget {
  final String label;
  final List<MealIngredient> ingredients;
  final ValueChanged<List<MealIngredient>> onChanged;

  const MealIngredientsSection({
    super.key,
    required this.label,
    required this.ingredients,
    required this.onChanged,
  });

  @override
  State<MealIngredientsSection> createState() => _MealIngredientsSectionState();
}

class _MealIngredientsSectionState extends State<MealIngredientsSection> {
  void _openAddDrawer({bool keepOpen = false}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: FractionallySizedBox(
            heightFactor: 0.75, // open 3/4 of the screen height
            child: SafeArea(
              top: false,
              child: _AddIngredientSheet(
                onSave: (ing, addAnother) {
                  setState(() {
                    widget.ingredients.add(ing);
                  });
                  widget.onChanged(widget.ingredients);
                  if (!addAnother) Navigator.of(ctx).pop();
                },
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 12.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.06),
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
                  color: theme.colorScheme.primary.withOpacity(0.8),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  "Ingredients",
                  style: GoogleFonts.nunito(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14.0),
            // Existing ingredients rendered as non-editable rows with delete
            ...List.generate(widget.ingredients.length, (i) {
              final ing = widget.ingredients[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        ing.toString(),
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete,
                          color: theme.colorScheme.error.withOpacity(0.9)),
                      tooltip: 'Remove',
                      onPressed: () {
                        setState(() => widget.ingredients.removeAt(i));
                        widget.onChanged(widget.ingredients);
                      },
                    ),
                  ],
                ),
              );
            }),
            // Placeholder to add a new ingredient (mirrors MealSlot empty style)
            GestureDetector(
              onTap: _openAddDrawer,
              child: DottedBorder(
                color: theme.colorScheme.outline,
                strokeWidth: 1.5,
                dashPattern: const [6, 4],
                borderType: BorderType.RRect,
                radius: const Radius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.outline.withOpacity(0.6),
                            width: 1,
                          ),
                        ),
                        child: Icon(Icons.add,
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  widget.label,
                                  style: GoogleFonts.nunito(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Tap to add an ingredient',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.nunito(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddIngredientSheet extends StatefulWidget {
  final void Function(MealIngredient ing, bool addAnother) onSave;
  const _AddIngredientSheet({required this.onSave});

  @override
  State<_AddIngredientSheet> createState() => _AddIngredientSheetState();
}

class _AddIngredientSheetState extends State<_AddIngredientSheet> {
  final _qty = TextEditingController();
  String _unit = '';
  final _name = TextEditingController();
  final _desc = TextEditingController();
  int? _canonicalId;

  final _api = RecipeApi();
  List<Map<String, dynamic>> _suggestions = [];
  bool _loading = false;

  static const _units = [
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
  void dispose() {
    _qty.dispose();
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _onNameChanged(String text) async {
    if (text.trim().isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    setState(() => _loading = true);
    final res = await _api.autocompleteCanonicalIngredients(text, limit: 5);
    if (!mounted) return;
    setState(() {
      _suggestions = res;
      _loading = false;
    });
  }

  void _selectSuggestion(Map<String, dynamic> item) {
    final en = (item['canonical_name_en'] ?? '').toString();
    setState(() {
      _name.text = en;
      _name.selection = TextSelection.collapsed(offset: _name.text.length);
      _canonicalId = item['id'] as int?;
      _suggestions = [];
    });
    // Optionally collapse the keyboard focus to mimic typical search completion
    // while keeping the field content intact.
    FocusScope.of(context).unfocus();
  }

  void _handleSave({required bool addAnother}) {
    final ing = MealIngredient(
      quantity: _qty.text,
      unit: _unit,
      name: _name.text.trim(),
      description: _desc.text,
      canonicalId: _canonicalId,
    );
    if (ing.name.isEmpty) return; // do nothing if no name
    widget.onSave(ing, addAnother);
    if (addAnother) {
      setState(() {
        _qty.clear();
        _unit = '';
        _name.clear();
        _desc.clear();
        _canonicalId = null;
        _suggestions = [];
      });
    }
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    String? hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    final theme = Theme.of(context);
    return InputDecoration(
      hintText: hint,
      isDense: true,
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            BorderSide(color: theme.colorScheme.outline.withOpacity(0.15)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
      ),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final suggestionHeight = _suggestions.isEmpty
        ? 0.0
        : (math.min(_suggestions.length, 5) * 44.0 + 8.0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withOpacity(0.5),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Add ingredient',
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 90,
                        child: TextField(
                          controller: _qty,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: _inputDecoration(context, hint: 'Qty'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _units.contains(_unit) ? _unit : '',
                          decoration: _inputDecoration(context, hint: 'Unit'),
                          isDense: true,
                          items: _units
                              .map((u) => DropdownMenuItem(
                                  value: u, child: Text(u.isEmpty ? '—' : u)))
                              .toList(),
                          onChanged: (v) => setState(() => _unit = v ?? ''),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Name with typeahead (expand stack height so dropdown is inside hit test)
                  SizedBox(
                    height: 52 + suggestionHeight,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        TextField(
                          controller: _name,
                          onChanged: _onNameChanged,
                          decoration: _inputDecoration(
                            context,
                            hint: 'Ingredient name',
                            prefixIcon:
                                const Icon(Icons.search_outlined, size: 18),
                            suffixIcon: _loading
                                ? Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        if (_suggestions.isNotEmpty)
                          Positioned(
                            left: 0,
                            right: 0,
                            top: 52,
                            child: Material(
                              elevation: 4,
                              borderRadius: BorderRadius.circular(8),
                              color: theme.colorScheme.surface,
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxHeight: 220),
                                child: ListView.separated(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  shrinkWrap: true,
                                  itemCount: _suggestions.length,
                                  separatorBuilder: (_, __) => Divider(
                                    height: 1,
                                    thickness: 0.5,
                                    color: theme.colorScheme.outline
                                        .withOpacity(0.1),
                                  ),
                                  itemBuilder: (context, index) {
                                    final s = _suggestions[index];
                                    final en = (s['canonical_name_en'] ?? '')
                                        .toString();
                                    final fr = (s['canonical_name_fr'] ?? '')
                                        .toString();
                                    return InkWell(
                                      onTap: () => _selectSuggestion(s),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12.0, vertical: 10.0),
                                        child: Row(
                                          children: [
                                            Icon(Icons.search,
                                                size: 16,
                                                color: theme.colorScheme
                                                    .onSurfaceVariant),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                fr.isNotEmpty
                                                    ? '$en  •  $fr'
                                                    : en,
                                                style: GoogleFonts.nunito(
                                                  color: theme
                                                      .colorScheme.onSurface,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
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
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _desc,
                    decoration: _inputDecoration(context,
                        hint: 'Description (optional)'),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          // Bottom action bar
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _handleSave(addAnother: false),
                      style: OutlinedButton.styleFrom(
                        textStyle: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Save'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _handleSave(addAnother: true),
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Save & add another'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
