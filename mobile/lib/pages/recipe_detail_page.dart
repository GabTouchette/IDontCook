import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/enums/recipe_view_mode.dart';
import 'package:i_cant_cook/enums/toast_type.dart';
import 'package:i_cant_cook/widgets/dialogs/recipe_chat_dialog.dart';
import 'package:i_cant_cook/utils/recipe_submit_utils.dart';
import 'package:image_picker/image_picker.dart';
import 'package:i_cant_cook/api/recipe_api.dart';
import 'package:i_cant_cook/models/recipe/recipe.dart';
import 'package:i_cant_cook/widgets/recipe_detail/additional_section_widget.dart';
import 'package:i_cant_cook/widgets/recipe_detail/recipe_detail_skeleton.dart';
import 'package:i_cant_cook/widgets/recipe_detail/recipe_image_widget.dart';
import 'package:i_cant_cook/widgets/recipe_detail/recipe_info_widget.dart';
import 'package:i_cant_cook/providers/recipe_detail_provider.dart';
import 'package:i_cant_cook/widgets/dialogs/confirmation_dialog.dart';
import 'package:i_cant_cook/pages/update_recipe_page.dart';
import 'package:i_cant_cook/widgets/toasts/information_toast.dart';
import 'package:i_cant_cook/widgets/dialogs/user_post_dialog.dart';
import 'package:provider/provider.dart';

class RecipeDetailPage extends StatefulWidget {
  final Recipe? recipe;
  final int? recipeId;
  final RecipeViewMode viewMode;
  final Set<String>? updatedFields;

  const RecipeDetailPage({
    Key? key,
    this.recipe,
    this.recipeId,
    this.viewMode = const RecipeViewMode.normal(),
    this.updatedFields,
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

  @override
  Widget build(BuildContext context) {
    final updatedFields = widget.updatedFields ?? {};

    return Consumer<RecipeDetailProvider>(builder: (context, provider, child) {
      if (provider.isLoading) {
        return RecipeDetailSkeleton();
      }

      if (provider.recipe == null) {
        return Center(child: Text("Recipe not found"));
      }

      final recipe = provider.recipe!;

      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          centerTitle: true,
          leading: IconButton(
            padding: const EdgeInsets.only(left: 16.0),
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.chevron_left,
              color: Theme.of(context).colorScheme.primary,
              size: 40,
            ),
          ),
          title: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              widget.viewMode.when(
                normal: () => "Recipe Details",
                preview: () => "Recipe Preview",
              ),
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w900,
                fontSize: 28,
                letterSpacing: -0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          actions: [
            if (recipe.is_saved == true) ...[
              widget.viewMode.when(
                // CASE: NORMAL
                normal: () => PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: Theme.of(context).colorScheme.primary,
                    size: 32,
                  ),
                  color: Theme.of(context).colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case 'share':
                        showDialog(
                          context: context,
                          builder: (_) => PostDialog(
                            recipe: recipe,
                            onPostSuccess: () {},
                          ),
                        );
                        break;
                      case 'favorite':
                        provider.toggleFavorite(context);
                        break;
                      case 'edit':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                UpdateRecipePage(recipeId: recipe.id),
                          ),
                        ).then((_) {
                          provider.initializeRecipe(
                            recipe: widget.recipe,
                            recipeId: widget.recipeId,
                          );
                        });
                        break;
                      case 'delete':
                        showDialog(
                          context: context,
                          builder: (_) => ConfirmationDialog(
                            message:
                                "Are you sure you want to delete this recipe?",
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
                                type: success
                                    ? ToastType.success
                                    : ToastType.error,
                              );
                            },
                            onCancel: () => Navigator.pop(context),
                          ),
                        );
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    _popupItem(
                      value: 'share',
                      icon: FontAwesomeIcons.shareNodes,
                      label: "Share",
                    ),
                    _popupItem(
                      value: 'favorite',
                      icon: recipe.is_favorite ?? false
                          ? FontAwesomeIcons.solidHeart
                          : FontAwesomeIcons.heart,
                      iconColor: recipe.is_favorite ?? false
                          ? Colors.red
                          : Theme.of(context).colorScheme.onSurface,
                      label: recipe.is_favorite ?? false
                          ? "Unfavorite"
                          : "Favorite",
                    ),
                    _popupItem(
                      value: 'edit',
                      icon: FontAwesomeIcons.penToSquare,
                      label: "Edit",
                    ),
                    _popupItem(
                      value: 'delete',
                      icon: FontAwesomeIcons.trash,
                      label: "Delete",
                      iconColor: Theme.of(context).colorScheme.error,
                      textColor: Theme.of(context).colorScheme.error,
                    ),
                  ],
                ),
                // CASE: PREVIEW
                preview: () => PopupMenuButton<String>(
                  icon: Container(
                    padding: const EdgeInsets.only(right: 16),
                    child: FaIcon(
                      FontAwesomeIcons.floppyDisk,
                      size: 32,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  color: Theme.of(context).colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case 'save':
                        _onSave(context);
                        break;
                      case 'save_as_new':
                        _onSaveAsNew(context);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    _popupItem(
                      value: 'save',
                      icon: FontAwesomeIcons.floppyDisk,
                      label: "Save",
                    ),
                    _popupItem(
                      value: 'save_as_new',
                      icon: FontAwesomeIcons.fileCirclePlus,
                      label: "Save as New",
                    ),
                  ],
                ),
              ),
            ] else ...[
              // If not saved, show floppy save icon or loading indicator
              Consumer<RecipeDetailProvider>(
                builder: (context, provider, child) {
                  return IconButton(
                    onPressed: provider.isSaving
                        ? null
                        : () => provider.saveRecipe(context),
                    icon: Container(
                      padding: const EdgeInsets.only(right: 16),
                      child: provider.isSaving
                          ? SizedBox(
                              width: 32,
                              height: 32,
                              child: CircularProgressIndicator(
                                color: Theme.of(context).colorScheme.primary,
                                strokeWidth: 2.5,
                              ),
                            )
                          : FaIcon(
                              FontAwesomeIcons.floppyDisk,
                              color: Theme.of(context).colorScheme.primary,
                              size: 32,
                            ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RecipeImage(
                    imageUrl: recipe.image_url ?? "",
                    onImagePick: widget.viewMode == RecipeViewMode.preview()
                        ? () {}
                        : _pickImage,
                  ),
                  const SizedBox(height: 16),
                  RecipeInfo(
                    recipe: recipe,
                    servings: provider.servings,
                    incrementServings: provider.incrementServings,
                    decrementServings: provider.decrementServings,
                    completedInstructions: provider.completedInstructions,
                    onCompletedInstructions:
                        provider.toggleInstructionCompletion,
                    updatedFields: updatedFields,
                  ),
                  const SizedBox(height: 16),
                  AdditionalSections(
                    tags: recipe.tags,
                    description: recipe.description,
                    notes: recipe.notes,
                    updatedFields: updatedFields,
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),

            // Floating Action Button for Chat
            if (recipe.is_saved == true &&
                widget.viewMode == RecipeViewMode.normal())
              Positioned(
                bottom: 24,
                right: 24,
                child: FloatingActionButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => Container(
                        height: MediaQuery.of(context).size.height,
                        child: RecipeChatDialog(recipe: recipe),
                      ),
                    );
                  },
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100)),
                  child: Icon(Icons.chat,
                      color: Theme.of(context).colorScheme.onPrimary, size: 28),
                ),
              ),
          ],
        ),
      );
    });
  }

  void _onSave(BuildContext context) {
    final recipeData = buildRecipeDataFromRecipe(widget.recipe!);
    submitRecipe(
      context: context,
      recipeData: recipeData,
      isUpdate: true,
      recipeId: widget.recipe!.id,
      shouldNavigate: false,
    );
  }

  void _onSaveAsNew(BuildContext context) {
    final recipeData = buildRecipeDataFromRecipe(widget.recipe!);
    submitRecipe(
      context: context,
      recipeData: recipeData,
      isUpdate: false,
      shouldNavigate: true,
    );
    Navigator.pop(context);
    Navigator.pop(context);
  }

  PopupMenuItem<String> _popupItem({
    required String value,
    required IconData icon,
    required String label,
    Color? iconColor,
    Color? textColor,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          FaIcon(icon,
              size: 18,
              color: iconColor ?? Theme.of(context).colorScheme.onSurface),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: textColor ?? Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  void _pickImage() async {
    final provider = context.read<RecipeDetailProvider>();
    final recipe = provider.recipe;
    if (recipe == null || recipe.is_saved != true) return;

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
          type: success ? ToastType.success : ToastType.error,
        );
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
        type: ToastType.error,
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
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.5),
                        size: 80,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
