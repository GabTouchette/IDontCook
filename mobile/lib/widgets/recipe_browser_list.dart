import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:i_cant_cook/models/recipe_preview/recipe_preview.dart';
import 'package:i_cant_cook/pages/recipe_detail_page.dart';
import 'package:i_cant_cook/providers/user_recipes_provider.dart';
import 'package:i_cant_cook/providers/explore_provider.dart';
import 'package:i_cant_cook/api/api_config.dart';

class RecipeBrowserList extends StatefulWidget {
  final String query;
  final bool savedOnly;
  final int? selectedId;
  final List<String>? includeTags;
  final ValueChanged<RecipePreview?> onSelect;
  const RecipeBrowserList(
      {super.key,
      required this.query,
      required this.savedOnly,
      required this.onSelect,
      this.selectedId,
      this.includeTags});

  @override
  State<RecipeBrowserList> createState() => _RecipeBrowserListState();
}

class _RecipeBrowserListState extends State<RecipeBrowserList> {
  bool _requestedUserFetch = false;

  Widget _thumb(BuildContext context, String? url) {
    final placeholder = Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withOpacity(0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(Icons.image_outlined, size: 20),
    );
    if (url == null || url.trim().isEmpty) return placeholder;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.network(
        ApiConfig.resolveImageUrl(url),
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => placeholder,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.query.toLowerCase();

    List<RecipePreview> source = const [];
    bool loading = false;

    if (widget.savedOnly) {
      final urp = context.watch<UserRecipesProvider>();
      source = urp.allRecipes;
      if (source.isEmpty && !_requestedUserFetch) {
        _requestedUserFetch = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<UserRecipesProvider>().fetchRecipes();
        });
      }
      loading = source.isEmpty; // until fetched
    } else {
      final exp = context.watch<ExploreProvider>();
      source = exp.items;
      loading = exp.isLoading && source.isEmpty;
    }

    if (loading) return const Center(child: CircularProgressIndicator());

    final Set<String> tagFilter =
        (widget.includeTags ?? const []).map((e) => e.toLowerCase()).toSet();
    final filtered = source.where((e) {
      if (q.isNotEmpty && !e.title.toLowerCase().contains(q)) return false;
      if (tagFilter.isNotEmpty) {
        final etags = (e.tags ?? const []).map((t) => t.toLowerCase()).toSet();
        if (etags.intersection(tagFilter).isEmpty) return false;
      }
      return true;
    }).toList();
    if (filtered.isEmpty) return const Center(child: Text('No recipes found'));
    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (ctx, i) {
        final r = filtered[i];
        final isSelected =
            widget.selectedId != null && widget.selectedId == r.id;
        return ListTile(
          leading: _thumb(context, r.thumbnail_url),
          title: Text(
            r.title,
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${r.preparation_time ?? 0} + ${r.cooking_time ?? 0} min',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.launch),
                tooltip: 'Open details',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RecipeDetailPage(recipeId: r.id),
                    ),
                  );
                },
              ),
              if (isSelected)
                const Icon(Icons.check_circle, color: Colors.green),
            ],
          ),
          selected: isSelected,
          selectedTileColor: Colors.green.withOpacity(0.08),
          onTap: () => widget.onSelect(isSelected ? null : r),
        );
      },
    );
  }
}
