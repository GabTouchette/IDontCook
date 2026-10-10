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
import 'package:i_cant_cook/providers/user_recipes_provider.dart';
import 'package:i_cant_cook/widgets/dialogs/confirmation_dialog.dart';
import 'package:i_cant_cook/pages/update_recipe_page.dart';
import 'package:i_cant_cook/widgets/toasts/information_toast.dart';
import 'package:i_cant_cook/widgets/dialogs/user_post_dialog.dart';
import 'package:i_cant_cook/widgets/recipes/placeholder_image.dart';
import 'package:provider/provider.dart';
import 'package:i_cant_cook/api/api_config.dart';

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

  Future<void> _showSaveDialog() async {
    final provider = Provider.of<RecipeDetailProvider>(context, listen: false);

    try {
      await provider.saveRecipeOnly(context);

      if (context.mounted) {
        Provider.of<UserRecipesProvider>(context, listen: false).fetchRecipes();
      }

      // Show success toast
      InformationToast.show(
        context: context,
        message: 'Recipe saved successfully!',
        type: ToastType.success,
      );
    } catch (e) {
      // Show error toast
      InformationToast.show(
        context: context,
        message: 'Failed to save recipe',
        type: ToastType.error,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final recipeProvider =
          Provider.of<RecipeDetailProvider>(context, listen: false);

      recipeProvider.initializeRecipe(
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
        extendBodyBehindAppBar: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          elevation: 0,
          leading: IconButton(
            padding: const EdgeInsets.only(left: 8.0),
            onPressed: () => Navigator.pop(context),
            icon: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          actions: [
            if (recipe.is_saved == true) ...[
              widget.viewMode.when(
                // CASE: NORMAL
                normal: () => PopupMenuButton<String>(
                  icon: Container(
                    padding: const EdgeInsets.only(right: 12),
                    child: Container(
                      width: 42,
                      height: 42,
                      color: const Color(0xFFCAFF00),
                      child: const Icon(
                        Icons.more_vert,
                        color: Color(0xFF0A0A0A),
                        size: 22,
                      ),
                    ),
                  ),
                  color: Theme.of(context).colorScheme.surface,
                  elevation: 2,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
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
                      case 'digitalize':
                        _digitalizeRecipe();
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
                      value: 'digitalize',
                      icon: FontAwesomeIcons.cameraRetro,
                      label: "Digitalize from photo",
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
                // Preview mode save button
                preview: () => PopupMenuButton<String>(
                  icon: Container(
                    padding: const EdgeInsets.only(right: 12),
                    child: Container(
                      width: 36,
                      height: 36,
                      color: const Color(0xFFCAFF00),
                      child: const Icon(
                        Icons.save,
                        color: Color(0xFF0A0A0A),
                        size: 18,
                      ),
                    ),
                  ),
                  color: Theme.of(context).colorScheme.surface,
                  elevation: 2,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
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
                    onPressed: provider.isSaving ? null : _showSaveDialog,
                    icon: Container(
                      padding: const EdgeInsets.only(right: 12),
                      child: provider.isSaving
                          ? SizedBox(
                              width: 32,
                              height: 32,
                              child: CircularProgressIndicator(
                                color: const Color(0xFFCAFF00),
                                strokeWidth: 2.5,
                              ),
                            )
                          : Container(
                              width: 36,
                              height: 36,
                              color: const Color(0xFFCAFF00),
                              child: const Icon(
                                Icons.save,
                                color: Color(0xFF0A0A0A),
                                size: 18,
                              ),
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
                    title: recipe.title,
                    recipeId: recipe.id,
                    onImagePick: widget.viewMode == RecipeViewMode.preview()
                        ? () {}
                        : _pickImage,
                  ),
                  RecipeInfo(
                    recipe: recipe,
                    servings: provider.servings,
                    incrementServings: provider.incrementServings,
                    decrementServings: provider.decrementServings,
                    completedInstructions: provider.completedInstructions,
                    completedIngredients: provider.completedIngredients,
                    onCompletedInstructions:
                        provider.toggleInstructionCompletion,
                    onCompletedIngredient: provider.toggleIngredientCompletion,
                    updatedFields: updatedFields,
                    ingredientCalories: provider.ingredientCalories,
                    isNutritionCalculating: provider.isNutritionCalculating,
                    // Ingredient long-press → chat is only wired when the recipe
                    // chat is actually available (same gate as the chat FAB).
                    onAskAboutIngredient: (recipe.is_saved == true &&
                            widget.viewMode == RecipeViewMode.normal())
                        ? (question) =>
                            _openRecipeChat(recipe, initialQuery: question)
                        : null,
                    // Show the reformat banner for saved recipes whose
                    // ingredients haven't been through the LLM format pass.
                    showFormatBanner: recipe.is_formatted == false &&
                        recipe.is_saved == true &&
                        widget.viewMode == RecipeViewMode.normal(),
                    isReformatting: provider.isReformatting,
                    onReformat: () => provider.reformatRecipe(context),
                  ),
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
                child: GestureDetector(
                  onTap: () => _openRecipeChat(recipe),
                  child: Container(
                    width: 56,
                    height: 56,
                    color: const Color(0xFFCAFF00),
                    child: const Icon(
                      Icons.chat_bubble_outline,
                      color: Color(0xFF0A0A0A),
                      size: 24,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  /// Opens the recipe chat bottom sheet. When [initialQuery] is provided (e.g.
  /// from an ingredient long-press action), the dialog auto-sends it on open.
  void _openRecipeChat(Recipe recipe, {String? initialQuery}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => RecipeChatDialog(
        recipe: recipe,
        initialQuery: initialQuery,
      ),
    );
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
    required FaIconData icon,
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
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
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

    final source = await _showImageSourceSheet();
    if (source == null) return;

    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() => _imageFile = File(image.path));
        final newImageUrl =
            await _uploadImageToServer(_imageFile!, recipe.id);
        if (newImageUrl.isNotEmpty) {
          provider.image_url = newImageUrl;
          InformationToast.show(
            context: context,
            message: "Photo saved!",
            type: ToastType.success,
          );
        } else {
          InformationToast.show(
            context: context,
            message: "Failed to upload photo.",
            type: ToastType.error,
          );
        }
      }
    } on Exception catch (e) {
      final msg = e.toString();
      if (msg.contains('camera_access_denied') ||
          msg.contains('photo_access_denied')) {
        _showCameraPermissionDialog();
      } else {
        InformationToast.show(
          context: context,
          message: "Could not open camera.",
          type: ToastType.error,
        );
      }
    }
  }

  Future<ImageSource?> _showImageSourceSheet() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt,
                  color: Theme.of(context).colorScheme.primary),
              title: Text('Take a photo',
                  style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.photo_library,
                  color: Theme.of(context).colorScheme.primary),
              title: Text('Choose from library',
                  style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showCameraPermissionDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text('Camera access required',
            style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700)),
        content: Text(
          'Please allow camera and photo library access in Settings → Privacy → Camera.',
          style: GoogleFonts.spaceGrotesk(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK',
                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _digitalizeRecipe() async {
    final provider = context.read<RecipeDetailProvider>();
    final recipe = provider.recipe;
    if (recipe == null) return;

    ImageSource? source;
    try {
      source = await _showImageSourceSheet();
    } catch (_) {}
    if (source == null) return;

    XFile? image;
    try {
      image = await _picker.pickImage(source: source);
    } on Exception catch (e) {
      final msg = e.toString();
      if (msg.contains('camera_access_denied') ||
          msg.contains('photo_access_denied')) {
        _showCameraPermissionDialog();
      }
      return;
    }
    if (image == null) return;

    // Show loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _DigitalizeLoadingDialog(),
    );

    final data =
        await RecipeApi().digitalizeFromImage(File(image.path));

    if (!mounted) return;
    Navigator.pop(context); // dismiss loading

    if (data == null) {
      InformationToast.show(
        context: context,
        message: "Could not read the recipe. Try a clearer photo.",
        type: ToastType.error,
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UpdateRecipePage(
          recipeId: recipe.id,
          initialData: data,
        ),
      ),
    ).then((_) {
      provider.initializeRecipe(
        recipe: widget.recipe,
        recipeId: widget.recipeId,
      );
    });
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

  Widget _buildImagePlaceholder() {
    final provider = context.read<RecipeDetailProvider>();
    final int recipeId = (provider.recipe?.id) ?? 0;
    return Stack(
      children: [
        PlaceholderImageWidget(recipeId: recipeId, height: 250),
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              'Tap to add photo',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget getRecipeImage(String? imageUrl) {
    return GestureDetector(
      onTap: _pickImage,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        child: imageUrl != null && imageUrl.isNotEmpty
            ? Image.network(
                ApiConfig.resolveImageUrl(imageUrl),
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
              )
            : _buildImagePlaceholder(),
      ),
    );
  }
}

class _DigitalizeLoadingDialog extends StatelessWidget {
  const _DigitalizeLoadingDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: Color(0xFFCAFF00),
              strokeWidth: 3,
            ),
            const SizedBox(height: 20),
            Text(
              'Reading recipe...',
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
