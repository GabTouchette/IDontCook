import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/api/recipe_api.dart';
import 'package:i_cant_cook/api/social_api.dart';
import 'package:i_cant_cook/enums/toast_type.dart';
import 'package:i_cant_cook/models/recipe/recipe.dart';
import 'package:i_cant_cook/models/recipe_preview/recipe_preview.dart';
import 'package:i_cant_cook/widgets/toasts/information_toast.dart';
import 'package:i_cant_cook/api/api_config.dart';

class PostDialog extends StatefulWidget {
  final Recipe? recipe;
  final VoidCallback onPostSuccess;

  const PostDialog({
    super.key,
    this.recipe,
    required this.onPostSuccess,
  });

  @override
  _PostDialogState createState() => _PostDialogState();
}

class _PostDialogState extends State<PostDialog> {
  final TextEditingController _commentController = TextEditingController();
  String? _errorMessage;
  RecipePreview? _selectedRecipe;
  bool _isLoading = false;
  List<RecipePreview> _recipes = [];

  @override
  void initState() {
    super.initState();
    if (widget.recipe != null) {
      _selectedRecipe = RecipePreview(
        id: widget.recipe!.id,
        title: widget.recipe!.title,
        description: widget.recipe!.description,
        thumbnail_url: widget.recipe!.thumbnail_url,
      );
    }
    _fetchRecipes();
  }

  Future<void> _fetchRecipes() async {
    setState(() {
      _isLoading = true;
    });
    _recipes = await RecipeApi().fetchRecipes();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> handlePost() async {
    final comment = _commentController.text.trim();

    if (comment.isEmpty) {
      setState(() {
        _errorMessage = 'Please add a comment to your post.';
      });
      return;
    }

    if (_selectedRecipe == null) {
      setState(() {
        _errorMessage = 'Please select a recipe for your post.';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
    });

    final postData = {
      'content': comment,
      'recipe_id': _selectedRecipe?.id,
    };

    final success = await SocialApi().createPost(postData);

    if (success) {
      if (mounted) Navigator.pop(context);
      widget.onPostSuccess();
    }

    InformationToast.show(
      context: context,
      message:
          success ? 'Post created successfully!' : 'Failed to create post.',
      type: success ? ToastType.success : ToastType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      surfaceTintColor: Colors.transparent,
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SHARE RECIPE',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                if (widget.recipe != null) ...[
                  getRecipeImage(widget.recipe!.image_url),
                  const SizedBox(height: 8),
                  Text(
                    widget.recipe!.title,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        )
                      : DropdownButtonHideUnderline(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outline
                                    .withValues(alpha: 0.25),
                                width: 1.5,
                              ),
                            ),
                            child: DropdownButton<RecipePreview>(
                              isExpanded: true,
                              value: _selectedRecipe,
                              icon: Icon(
                                Icons.expand_more,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                              hint: Text(
                                'Select a recipe',
                                style: GoogleFonts.spaceGrotesk(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.4),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              onChanged: (RecipePreview? newValue) {
                                setState(() {
                                  _selectedRecipe = newValue;
                                });
                              },
                              items: _recipes
                                  .map(
                                    (recipe) => DropdownMenuItem<RecipePreview>(
                                      value: recipe,
                                      child: Row(
                                        children: [
                                          recipe.thumbnail_url != null &&
                                                  recipe.thumbnail_url!.isNotEmpty
                                              ? Image.network(
                                                  ApiConfig.resolveImageUrl(recipe.thumbnail_url!),
                                                  width: 32,
                                                  height: 32,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) =>
                                                      Container(
                                                        width: 32,
                                                        height: 32,
                                                        color: Theme.of(context).colorScheme.onSecondary,
                                                        child: Icon(Icons.restaurant, size: 18, color: Theme.of(context).colorScheme.secondary),
                                                      ),
                                                )
                                              : Container(
                                                  width: 32,
                                                  height: 32,
                                                  color: Theme.of(context).colorScheme.onSecondary,
                                                  child: Icon(
                                                    Icons.restaurant,
                                                    size: 18,
                                                    color: Theme.of(context).colorScheme.secondary,
                                                  ),
                                                ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              recipe.title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.spaceGrotesk(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ),
                  if (_selectedRecipe != null) ...[
                    const SizedBox(height: 16),
                    getRecipeImage(_selectedRecipe!.thumbnail_url),
                    const SizedBox(height: 8),
                    Text(
                      _selectedRecipe!.title,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: _commentController,
                  maxLines: 5,
                  minLines: 3,
                  style: GoogleFonts.spaceGrotesk(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Add a comment to your post...',
                    hintStyle: GoogleFonts.spaceGrotesk(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
                      fontSize: 14,
                    ),
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.onSurface,
                        width: 1.5,
                      ),
                    ),
                    errorText: _errorMessage,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Text(
                          'CANCEL',
                          style: GoogleFonts.spaceGrotesk(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: handlePost,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        color: Theme.of(context).colorScheme.secondary,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.send_rounded, size: 16, color: Theme.of(context).colorScheme.onSecondary),
                            const SizedBox(width: 8),
                            Text(
                              'POST',
                              style: GoogleFonts.spaceGrotesk(
                                color: Theme.of(context).colorScheme.onSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget getRecipeImage(String? imageUrl) {
    return imageUrl != null && imageUrl.isNotEmpty
        ? Image.network(
            ApiConfig.resolveImageUrl(imageUrl),
            height: 150,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 150,
              color: Theme.of(context).colorScheme.onSecondary,
              child: Center(
                child: Icon(
                  Icons.restaurant,
                  color: Theme.of(context).colorScheme.secondary,
                  size: 48,
                ),
              ),
            ),
          )
        : Container(
            height: 150,
            color: Theme.of(context).colorScheme.onSecondary,
            child: Center(
              child: Icon(
                Icons.restaurant,
                color: Theme.of(context).colorScheme.secondary,
                size: 48,
              ),
            ),
          );
  }
}
