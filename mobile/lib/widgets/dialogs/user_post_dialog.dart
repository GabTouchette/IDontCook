import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/api/recipe_api.dart';
import 'package:i_cant_cook/api/social_api.dart';
import 'package:i_cant_cook/enums/toast_type.dart';
import 'package:i_cant_cook/models/recipe/recipe.dart';
import 'package:i_cant_cook/models/recipe_preview/recipe_preview.dart';
import 'package:i_cant_cook/widgets/toasts/information_toast.dart';

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
                                    .withOpacity(0.25),
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
                                      .withOpacity(0.4),
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
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: recipe.thumbnail_url != null &&
                                                    recipe.thumbnail_url!
                                                        .isNotEmpty
                                                ? Image.network(
                                                    recipe.thumbnail_url!,
                                                    width: 32,
                                                    height: 32,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (_, __, ___) =>
                                                        Container(
                                                          width: 32,
                                                          height: 32,
                                                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                                          child: Icon(Icons.image_not_supported_outlined, size: 18, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
                                                        ),
                                                  )
                                                : Container(
                                                    width: 32,
                                                    height: 32,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .surfaceContainerHighest,
                                                    child: Icon(
                                                      Icons.image,
                                                      size: 18,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurface
                                                          .withOpacity(0.4),
                                                    ),
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
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.35),
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
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
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
                        color: const Color(0xFFCAFF00),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.send_rounded, size: 16, color: Color(0xFF0A0A0A)),
                            const SizedBox(width: 8),
                            Text(
                              'POST',
                              style: GoogleFonts.spaceGrotesk(
                                color: const Color(0xFF0A0A0A),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: imageUrl != null && imageUrl.isNotEmpty
          ? Image.network(
              imageUrl,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 60,
                  ),
                ),
              ),
            )
          : Container(
              height: 150,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  Icons.image,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 60,
                ),
              ),
            ),
    );
  }
}
