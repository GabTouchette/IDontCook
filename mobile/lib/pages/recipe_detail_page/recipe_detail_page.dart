import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:i_cant_cook/api/recipe_api.dart';
import 'package:i_cant_cook/models/recipe/recipe.dart';
import 'package:i_cant_cook/pages/recipe_detail_page/additional_section_widget.dart';
import 'package:i_cant_cook/pages/recipe_detail_page/recipe_detail_skeleton.dart';
import 'package:i_cant_cook/pages/recipe_detail_page/recipe_image_widget.dart';
import 'package:i_cant_cook/pages/recipe_detail_page/recipe_info_widget.dart';
import 'package:i_cant_cook/providers/recipe_detail_provider.dart';
import 'package:i_cant_cook/widgets/dialogs/confirmation_dialog.dart';
import 'package:i_cant_cook/pages/update_recipe_page.dart';
import 'package:i_cant_cook/theme/colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:i_cant_cook/widgets/toasts/information_toast.dart';
import 'package:i_cant_cook/widgets/dialogs/user_post_dialog.dart';
import 'package:provider/provider.dart';

class RecipeDetailPage extends StatefulWidget {
  final Recipe? recipe;
  final int? recipeId;

  const RecipeDetailPage({
    Key? key,
    this.recipe,
    this.recipeId,
  }) : super(key: key);

  @override
  _RecipeDetailPageState createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  late RecipeDetailProvider recipeDetailProvider;

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<RecipeDetailProvider>(context, listen: false)
          .initializeRecipe(
        recipe: widget.recipe,
        recipeId: widget.recipeId,
      );
    });
  }

  void _pickImage() async {
    final provider = context.read<RecipeDetailProvider>();
    final recipe = provider.recipe;
    if (recipe == null || !provider.isSaved) return;

    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });

      String newImageUrl = await _uploadImageToServer(_imageFile!, recipe.id);
      bool success = newImageUrl.isNotEmpty;
      if (success) {
        provider.image_url = newImageUrl;
        InformationToast.show(
            context: context,
            message: success
                ? "Image uploaded successfully!"
                : "Failed to upload image.",
            textColor: success ? ColorPalette.green : ColorPalette.red);
      }
    }
  }

  Future<String> _uploadImageToServer(File imageFile, int recipeId) async {
    try {
      return await RecipeApi().uploadRecipeImage(recipeId, imageFile);
    } catch (e) {
      InformationToast.show(
        context: context,
        message: "An error occurred while uploading the image.",
        textColor: ColorPalette.red,
      );
      return "";
    }
  }

  Widget getRecipeImage(String? imageUrl) {
    final provider = context.read<RecipeDetailProvider>();
    int imageNumber = ((provider.recipe?.id) ?? 0 % 11) + 1;

    return GestureDetector(
      onTap: () {
        _pickImage();
      },
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        child: imageUrl != null && imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
              )
            : Container(
                height: 250,
                child: Stack(
                  children: [
                    Image.asset(
                      'assets/images/stock_food_$imageNumber.jpg',
                      fit: BoxFit.cover,
                      height: 250,
                      width: double.infinity,
                    ),
                    Positioned.fill(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                        child: Container(),
                      ),
                    ),
                    Center(
                      child: Icon(
                        Icons.image,
                        color: ColorPalette.lightgray,
                        size: 80,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RecipeDetailProvider>(builder: (context, provider, child) {
      if (provider.isLoading) {
        return RecipeDetailSkeleton();
      }

      if (provider.recipe == null) {
        return Center(child: Text("Recipe not found"));
      }

      final recipe = provider.recipe!;

      return Scaffold(
        backgroundColor: ColorPalette.darkergray,
        appBar: AppBar(
          backgroundColor: ColorPalette.darkergray,
          title: Text(
            "Details",
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              fontSize: 28,
              color: ColorPalette.offWhite,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          elevation: 0,
          leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.chevron_left,
              size: 32,
              color: ColorPalette.offWhite,
            ),
          ),
          actions: [
            if (provider.isSaved) ...[
              IconButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return PostDialog(
                        recipe: recipe,
                        onPostSuccess: () {},
                      );
                    },
                  );
                },
                icon: const FaIcon(
                  FontAwesomeIcons.share,
                  color: ColorPalette.offWhite,
                ),
              ),
              IconButton(
                onPressed: () => provider.toggleFavorite(context),
                icon: FaIcon(
                  (recipe.is_favorite ?? false)
                      ? FontAwesomeIcons.solidHeart
                      : FontAwesomeIcons.heart,
                  color: (recipe.is_favorite ?? false)
                      ? Colors.red
                      : ColorPalette.offWhite,
                ),
              ),
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          UpdateRecipePage(recipeId: recipe.id),
                    ),
                  ).then(
                    (_) {
                      provider.initializeRecipe(
                        recipe: widget.recipe,
                        recipeId: widget.recipeId,
                      );
                    },
                  );
                },
                icon: const FaIcon(
                  FontAwesomeIcons.pen,
                  color: ColorPalette.offWhite,
                ),
              ),
              IconButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => ConfirmationDialog(
                      message: "Are you sure you want to delete this recipe?",
                      onConfirm: () async {
                        Navigator.pop(context);
                        bool success =
                            await RecipeApi().deleteRecipe(recipe.id);
                        if (success) Navigator.pop(context);
                        InformationToast.show(
                          context: context,
                          message: success
                              ? "Recipe deleted successfully!"
                              : "There was an error deleting the recipe.",
                          textColor:
                              success ? ColorPalette.green : ColorPalette.red,
                        );
                      },
                      onCancel: () {
                        Navigator.pop(context);
                      },
                    ),
                  );
                },
                icon: const FaIcon(
                  FontAwesomeIcons.trash,
                  color: ColorPalette.red,
                ),
              ),
            ] else ...[
              IconButton(
                onPressed: () =>
                    context.read<RecipeDetailProvider>().saveRecipe(context),
                icon: FaIcon(
                  provider.isSaved
                      ? FontAwesomeIcons.solidBookmark
                      : FontAwesomeIcons.bookmark,
                  color: ColorPalette.offWhite,
                ),
              ),
            ],
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RecipeImage(
                imageUrl: recipe.image_url ?? "",
                onImagePick: _pickImage,
              ),
              const SizedBox(height: 16),
              RecipeInfo(
                recipe: recipe,
                servings: provider.servings,
                incrementServings: provider.incrementServings,
                decrementServings: provider.decrementServings,
                completedInstructions: provider.completedInstructions,
                onCompletedInstructions: provider.toggleInstructionCompletion,
              ),
              const SizedBox(height: 16),
              AdditionalSections(
                tags: recipe.tags,
                description: recipe.description,
                notes: recipe.notes,
              ),
            ],
          ),
        ),
      );
    });
  }
}
