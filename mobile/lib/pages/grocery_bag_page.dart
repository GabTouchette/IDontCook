import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:i_cant_cook/enums/toast_type.dart';
import 'package:i_cant_cook/models/grocery/grocery_models.dart';
import 'package:i_cant_cook/pages/grocery_order_webview_page.dart';
import 'package:i_cant_cook/providers/grocery_bag_provider.dart';
import 'package:i_cant_cook/services/haptic_service.dart';
import 'package:i_cant_cook/widgets/common/pressable.dart';
import 'package:i_cant_cook/widgets/dialogs/confirmation_dialog.dart';
import 'package:i_cant_cook/widgets/toasts/information_toast.dart';

class GroceryBagPage extends StatefulWidget {
  const GroceryBagPage({super.key});

  @override
  State<GroceryBagPage> createState() => _GroceryBagPageState();
}

class _GroceryBagPageState extends State<GroceryBagPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<GroceryBagProvider>().fetchBag(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<GroceryBagProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: theme.colorScheme.surface,
            surfaceTintColor: Colors.transparent,
            automaticallyImplyLeading: false,
            elevation: 0,
            // Hairline under the bar — matches the normalized tab app bars.
            shape: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            centerTitle: true,
            leading: IconButton(
              padding: const EdgeInsets.only(left: 16.0),
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.chevron_left,
                  color: theme.colorScheme.primary, size: 32),
            ),
            title: Text(
              'GROCERY BAG',
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w700,
                fontSize: 22,
                letterSpacing: 2.5,
                color: theme.colorScheme.onSurface,
              ),
            ),
            actions: [
              if (!provider.isEmpty)
                Pressable(
                  haptic: PressHaptic.medium,
                  child: IconButton(
                    tooltip: 'Empty bag',
                    onPressed: () => _confirmEmpty(context, provider),
                    icon: Icon(Icons.delete_outline,
                        color: theme.colorScheme.primary, size: 26),
                  ),
                ),
            ],
          ),
          body: _buildBody(context, provider),
          bottomNavigationBar: provider.isEmpty
              ? null
              : _buildOrderBar(context, provider),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, GroceryBagProvider provider) {
    if (!provider.hasLoaded && provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.isEmpty) {
      return _buildEmptyState(context);
    }
    final toBuy = provider.items.where((l) => !l.inPantry).toList();
    final pantry = provider.items.where((l) => l.inPantry).toList();
    final hidden = provider.hiddenItems;
    final hasHave = pantry.isNotEmpty || hidden.isNotEmpty;

    return RefreshIndicator(
      onRefresh: provider.fetchBag,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _buildRecipesStrip(context, provider),
          const SizedBox(height: 8),
          ...toBuy.map((line) =>
              _buildItemRow(context, provider, line, have: false)),
          if (provider.removedCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Text('${provider.removedCount} removed',
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ),
          if (hasHave) _buildHaveSeparator(context),
          ...pantry.map((line) =>
              _buildItemRow(context, provider, line, have: true)),
          ...hidden.map((line) => _buildItemRow(context, provider, line,
              have: true, alwaysHidden: true)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_bag_outlined,
                size: 64, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'Your grocery bag is empty',
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Add recipes from their detail page to build a shopping list.',
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipesStrip(BuildContext context, GroceryBagProvider provider) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${provider.recipes.length} RECIPE(S) · ${provider.itemCount} ITEM(S)',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: provider.recipes
                .map((r) => _recipeChip(context, provider, r))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _recipeChip(
      BuildContext context, GroceryBagProvider provider, BagRecipe r) {
    final theme = Theme.of(context);
    return InputChip(
      label: Text(
        r.title,
        style: GoogleFonts.spaceGrotesk(
            fontSize: 13, fontWeight: FontWeight.w600),
      ),
      onDeleted: () {
        HapticService.mediumImpact();
        provider.removeRecipe(r.id);
      },
      deleteIcon: const Icon(Icons.close, size: 16),
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    );
  }

  Widget _buildHaveSeparator(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Row(
        children: [
          Text(
            'I HAVE THIS',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Divider(color: theme.dividerColor)),
        ],
      ),
    );
  }

  /// A list row. Swipe left = remove from bag; swipe right = toggle "I have
  /// this" (pantry). [have] styles the row as already-owned; [alwaysHidden]
  /// marks the baked-in staples (salt/pepper/water), which can only be removed.
  Widget _buildItemRow(
    BuildContext context,
    GroceryBagProvider provider,
    ShoppableLine line, {
    required bool have,
    bool alwaysHidden = false,
  }) {
    final theme = Theme.of(context);
    final nameColor =
        have ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.onSurface;

    return Dismissible(
      key: ValueKey(line.key),
      direction: alwaysHidden
          ? DismissDirection.endToStart
          : DismissDirection.horizontal,
      // swipe right → "I have this" (or move back to the buy list)
      background: Container(
        color: theme.colorScheme.secondary,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: Icon(have ? Icons.remove_shopping_cart : Icons.check,
            color: theme.colorScheme.onSecondary),
      ),
      // swipe left → remove from bag
      secondaryBackground: Container(
        color: theme.colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        HapticService.mediumImpact();
        if (direction == DismissDirection.endToStart) {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => ConfirmationDialog(
              message: 'This removes ${line.name} from the bag.',
              onConfirm: () => Navigator.pop(ctx, true),
              onCancel: () => Navigator.pop(ctx, false),
            ),
          );
          if (confirmed == true) {
            provider.removeItem(line.key);
            if (context.mounted) {
              InformationToast.show(
                context: context,
                message: 'Removed ${line.name}',
                type: ToastType.info,
              );
            }
          }
        } else {
          provider.setPantry(line.key, !line.inPantry);
        }
        // The provider rebuilds the list with the item moved/removed, so the
        // Dismissible itself must not also drop the widget.
        return false;
      },
      child: ListTile(
        title: Row(
          children: [
            Flexible(
              child: Text(
                line.name,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: nameColor,
                ),
              ),
            ),
            if (line.needsConfirmation) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _showConfirmSheet(context, provider, line),
                child: Icon(Icons.help_outline,
                    size: 17, color: theme.colorScheme.tertiary),
              ),
            ],
          ],
        ),
        subtitle: line.recipeTitles.isEmpty
            ? null
            : Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  line.recipeTitles.join(' · '),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
        trailing: Text(
          [
            line.displayAmount,
            if (line.displayComponents.isNotEmpty) '+ ${line.displayComponents}'
          ].where((s) => s.isNotEmpty).join('  '),
          style: GoogleFonts.spaceGrotesk(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Future<void> _showConfirmSheet(
      BuildContext context, GroceryBagProvider provider, ShoppableLine line) async {
    final conceptId = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _ConfirmIngredientSheet(provider: provider, line: line),
      ),
    );
    if (conceptId == null || !context.mounted) return;
    await provider.resolveItem(line.key, conceptId);
    if (!context.mounted) return;
    InformationToast.show(
      context: context,
      message: 'Updated ${line.name}',
      type: ToastType.success,
    );
  }

  Widget _buildOrderBar(BuildContext context, GroceryBagProvider provider) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: () => _onOrder(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              foregroundColor: Theme.of(context).colorScheme.onSecondary,
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero),
            ),
            child: Text(
              'ORDER ONLINE',
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onOrder(BuildContext context) {
    // Only order what's actually "to buy" — exclude pantry items ("I have this").
    final items = context
        .read<GroceryBagProvider>()
        .items
        .where((l) => !l.inPantry)
        .toList();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GroceryOrderWebViewPage(items: items),
      ),
    );
  }

  Future<void> _confirmEmpty(
      BuildContext context, GroceryBagProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Empty grocery bag?',
            style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700)),
        content: const Text('This removes all recipes and items from the bag.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Empty')),
        ],
      ),
    );
    if (confirmed == true) {
      await provider.emptyBag();
    }
  }
}

/// Confirm-step picker (§5.3): search canonical ingredients and pop the chosen
/// concept id back to the caller, which commits the resolution.
class _ConfirmIngredientSheet extends StatefulWidget {
  final GroceryBagProvider provider;
  final ShoppableLine line;

  const _ConfirmIngredientSheet({required this.provider, required this.line});

  @override
  State<_ConfirmIngredientSheet> createState() =>
      _ConfirmIngredientSheetState();
}

class _ConfirmIngredientSheetState extends State<_ConfirmIngredientSheet> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.line.name;
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _search(widget.line.name));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(q));
  }

  Future<void> _search(String q) async {
    if (q.trim().length < 2) {
      setState(() => _results = []);
      return;
    }
    setState(() => _loading = true);
    final results = await widget.provider.searchCanonical(q.trim());
    if (!mounted) return;
    setState(() {
      _results = results;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Grab handle.
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'What is this ingredient?',
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'We couldn’t match “${widget.line.name}”. Pick the right one.',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _controller,
              autofocus: true,
              onChanged: _onChanged,
              decoration: InputDecoration(
                hintText: 'Search ingredients…',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(
                    borderRadius: BorderRadius.zero),
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4),
              child: _resultsBody(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultsBody(ThemeData theme) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_controller.text.trim().length < 2) {
      return _emptyState(theme, Icons.search,
          'Type at least 2 letters to search ingredients.');
    }
    if (_results.isEmpty) {
      return _emptyState(theme, Icons.search_off,
          'No ingredients found for “${_controller.text.trim()}”.\nTry a different name.');
    }
    return ListView.builder(
      shrinkWrap: true,
      itemCount: _results.length,
      itemBuilder: (_, i) {
        final r = _results[i];
        return ListTile(
          dense: true,
          title: Text(
            r['name'] as String? ?? '',
            style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600),
          ),
          trailing: Icon(Icons.chevron_right,
              size: 20, color: theme.colorScheme.onSurfaceVariant),
          onTap: () => Navigator.pop(context, r['concept_id'] as int?),
        );
      },
    );
  }

  Widget _emptyState(ThemeData theme, IconData icon, String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
