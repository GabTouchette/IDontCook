import 'package:flutter/material.dart';
import 'package:mobile/api/recipe_api.dart';
import 'package:mobile/api/social_api.dart';
import 'package:mobile/models/recipe/recipe.dart';
import 'package:mobile/models/recipe_preview/recipe_preview.dart';
import 'package:mobile/theme/colors.dart';
import 'package:mobile/widgets/toasts/information_toast.dart';

class PostDialog extends StatefulWidget {
  final Recipe? recipe;

  const PostDialog({
    super.key,
    this.recipe,
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
        image_url: widget.recipe!.image_url,
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

    // Check if a recipe is selected
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

    final result = await SocialApi().createPost(postData);

    if (result) Navigator.pop(context);

    InformationToast.show(
      context: context,
      message: result ? "Post created successfully!" : "Failed to create post.",
      textColor: result ? ColorPalette.green : ColorPalette.red,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      surfaceTintColor: ColorPalette.darkergray,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          // Make the content scrollable
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Share Recipe",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (widget.recipe != null) ...[
                getRecipeImage(widget.recipe!.image_url),
                const SizedBox(height: 8),
                Text(widget.recipe!.title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  widget.recipe!.description?.isNotEmpty == true
                      ? widget.recipe!.description!
                      : "No description available.",
                  style: TextStyle(color: ColorPalette.gray),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
              ] else ...[
                _isLoading
                    ? const CircularProgressIndicator()
                    : DropdownButtonFormField<RecipePreview>(
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.transparent,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 12.0, horizontal: 16.0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        hint: const Text('Select a recipe'),
                        value: _selectedRecipe,
                        onChanged: (RecipePreview? newValue) {
                          setState(() {
                            _selectedRecipe = newValue;
                          });
                        },
                        items: [
                          ..._recipes.map<DropdownMenuItem<RecipePreview>>(
                            (RecipePreview recipe) {
                              return DropdownMenuItem<RecipePreview>(
                                value: recipe,
                                child: Text(recipe.title),
                              );
                            },
                          ).toList(),
                        ],
                      ),
                if (_selectedRecipe != null) ...[
                  const SizedBox(height: 16),
                  getRecipeImage(_selectedRecipe!.image_url),
                  const SizedBox(height: 8),
                  Text(
                    _selectedRecipe!.title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _selectedRecipe!.description?.isNotEmpty == true
                        ? _selectedRecipe!.description!
                        : "No description available.",
                    style: TextStyle(color: ColorPalette.gray),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 16),
              ],
              TextField(
                controller: _commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Add a comment to your post...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  errorText: _errorMessage,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(color: ColorPalette.red),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: handlePost,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: ColorPalette.darkergray,
                      backgroundColor: ColorPalette.offWhite,
                      elevation: 0,
                    ),
                    child: const Text("Post"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget getRecipeImage(String? imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: imageUrl != null && imageUrl.isNotEmpty
          ? Image.network(imageUrl,
              height: 150, width: double.infinity, fit: BoxFit.cover)
          : Container(
              height: 150,
              decoration: BoxDecoration(
                  color: ColorPalette.offWhite,
                  borderRadius: BorderRadius.circular(12)),
              child: const Center(
                child: Icon(Icons.image, color: ColorPalette.gray, size: 60),
              ),
            ),
    );
  }
}
