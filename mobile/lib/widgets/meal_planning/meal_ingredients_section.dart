import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (ctx) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const lime = Color(0xFFCAFF00);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Text(
            'INGREDIENTS',
            style: GoogleFonts.spaceGrotesk(
              color: theme.colorScheme.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Container(width: 28, height: 2, color: lime),
          const SizedBox(height: 12),
          // Existing ingredients rendered as flat rows with delete
          ...List.generate(widget.ingredients.length, (i) {
            final ing = widget.ingredients[i];
            return Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.12),
                    width: 1,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      color: lime,
                      alignment: Alignment.center,
                      child: Text(
                        '${i + 1}',
                        style: GoogleFonts.spaceGrotesk(
                          color: const Color(0xFF0A0A0A),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        ing.toString(),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() => widget.ingredients.removeAt(i));
                        widget.onChanged(widget.ingredients);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 4),
                        child: Icon(Icons.close,
                            size: 16,
                            color:
                                theme.colorScheme.error.withOpacity(0.7)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 10),
          // Add ingredient button — lime fill, black text
          GestureDetector(
            onTap: _openAddDrawer,
            child: Container(
              height: 44,
              color: lime,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add, size: 16, color: Color(0xFF0A0A0A)),
                  const SizedBox(width: 8),
                  Text(
                    'ADD INGREDIENT',
                    style: GoogleFonts.spaceGrotesk(
                      color: const Color(0xFF0A0A0A),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
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
  final _nameFocus = FocusNode();

  final _api = RecipeApi();
  List<Map<String, dynamic>> _suggestions = [];
  bool _loading = false;

  static const _lime = Color(0xFFCAFF00);
  static const _btnFg = Color(0xFF0A0A0A);
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
    _nameFocus.dispose();
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
    _nameFocus.unfocus();
  }

  void _handleSave({required bool addAnother}) {
    final ing = MealIngredient(
      quantity: _qty.text,
      unit: _unit,
      name: _name.text.trim(),
      description: _desc.text,
      canonicalId: _canonicalId,
    );
    if (ing.name.isEmpty) return;
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

  InputDecoration _flatDecoration(BuildContext context, {String? hint}) {
    final theme = Theme.of(context);
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.spaceGrotesk(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
        fontSize: 14,
      ),
      isDense: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.25),
            width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.25),
            width: 1.5),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: _lime, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              'ADD INGREDIENT',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Container(width: 28, height: 2, color: _lime),
            const SizedBox(height: 16),
            // Qty + Unit
            Row(
              children: [
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: _qty,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: GoogleFonts.spaceGrotesk(
                      color: theme.colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: _flatDecoration(context, hint: 'Qty'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _units.contains(_unit) ? _unit : '',
                    style: GoogleFonts.spaceGrotesk(
                      color: theme.colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: _flatDecoration(context, hint: 'Unit'),
                    isDense: true,
                    items: _units
                        .map((u) => DropdownMenuItem(
                              value: u,
                              child: Text(u.isEmpty ? '—' : u,
                                  style:
                                      GoogleFonts.spaceGrotesk(fontSize: 14)),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _unit = v ?? ''),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Name field
            TextField(
              controller: _name,
              focusNode: _nameFocus,
              onChanged: _onNameChanged,
              onTapOutside: (_) {
                _nameFocus.unfocus();
                Future.delayed(const Duration(milliseconds: 150), () {
                  if (mounted) setState(() => _suggestions = []);
                });
              },
              style: GoogleFonts.spaceGrotesk(
                color: theme.colorScheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              decoration: _flatDecoration(context, hint: 'Ingredient name')
                  .copyWith(
                prefixIcon: Icon(
                  Icons.search_outlined,
                  size: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                suffixIcon: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(10.0),
                        child: SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
            ),
            // Inline suggestions — part of scroll, no overlay needed
            if (_suggestions.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 1),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: _suggestions.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final s = entry.value;
                    final en = (s['canonical_name_en'] ?? '').toString();
                    final fr = (s['canonical_name_fr'] ?? '').toString();
                    return Column(
                      children: [
                        if (idx > 0)
                          Divider(
                            height: 1,
                            thickness: 0.5,
                            color: theme.colorScheme.outline
                                .withValues(alpha: 0.1),
                          ),
                        InkWell(
                          onTap: () => _selectSuggestion(s),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            child: Row(
                              children: [
                                Icon(Icons.north_west,
                                    size: 12, color: _lime),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    fr.isNotEmpty ? '$en  •  $fr' : en,
                                    style: GoogleFonts.spaceGrotesk(
                                      color: theme.colorScheme.onSurface,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 10),
            // Description
            TextField(
              controller: _desc,
              style: GoogleFonts.spaceGrotesk(
                color: theme.colorScheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              decoration:
                  _flatDecoration(context, hint: 'Description (optional)'),
            ),
            const SizedBox(height: 16),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _handleSave(addAnother: false),
                    child: Container(
                      height: 48,
                      color: _lime,
                      alignment: Alignment.center,
                      child: Text(
                        'SAVE',
                        style: GoogleFonts.spaceGrotesk(
                          color: _btnFg,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _handleSave(addAnother: true),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: theme.colorScheme.outline
                              .withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'SAVE & ADD MORE',
                        style: GoogleFonts.spaceGrotesk(
                          color: theme.colorScheme.onSurface,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
