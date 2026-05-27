import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:i_cant_cook/api/ai_chatbot_api.dart';
import 'package:i_cant_cook/enums/toast_type.dart';
import 'package:i_cant_cook/utils/recipe_submit_utils.dart';
import 'package:i_cant_cook/widgets/recipes/recipe_form_extra_section.dart';
import 'package:i_cant_cook/widgets/meal_planning/meal_ingredients_section.dart';
import 'package:i_cant_cook/widgets/recipes/recipe_form_instructions_section.dart';
import 'package:i_cant_cook/widgets/recipes/recipe_form_tags_section.dart';
import 'package:i_cant_cook/widgets/recipes/recipe_form_time_section.dart';
import 'package:i_cant_cook/widgets/recipes/recipe_form_title_section.dart';
import 'package:i_cant_cook/models/recipe_form_fields/recipe_form_fields.dart';
import 'package:i_cant_cook/widgets/toasts/information_toast.dart';

class CreateRecipePage extends StatefulWidget {
  const CreateRecipePage({super.key});

  @override
  _CreateRecipePageState createState() => _CreateRecipePageState();
}

class _CreateRecipePageState extends State<CreateRecipePage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _preptimeController = TextEditingController();
  final TextEditingController _cooktimeController = TextEditingController();
  final TextEditingController _servingsController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  List<MealIngredient> _mealIngredients = [];
  List<InstructionField> _instructions = [
    InstructionField(controller: TextEditingController(), focusNode: FocusNode())
  ];
  List<String> _selectedTags = [];
  List<File> _pendingImages = [];
  bool _isDigitizing = false;

  @override
  void dispose() {
    for (var instruction in _instructions) {
      instruction.controller.dispose();
      instruction.focusNode.dispose();
    }
    super.dispose();
  }

  void _showPhotoSourcePicker() {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(height: 1, color: cs.outlineVariant),
            ListTile(
              leading: Icon(Icons.camera_alt, color: cs.primary),
              title: Text('Take a photo',
                  style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                _pickImages(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: cs.primary),
              title: Text('Choose from gallery',
                  style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600)),
              subtitle: Text('Select multiple photos for multi-page recipes',
                  style: GoogleFonts.spaceGrotesk(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
              onTap: () {
                Navigator.pop(ctx);
                _pickImages(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImages(ImageSource source) async {
    try {
      if (source == ImageSource.gallery) {
        final picked = await _picker.pickMultiImage(
          maxWidth: 1568,
          maxHeight: 1568,
          imageQuality: 85,
        );
        if (picked.isNotEmpty) {
          setState(() => _pendingImages.addAll(picked.map((x) => File(x.path))));
        }
      } else {
        final picked = await _picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1568,
          maxHeight: 1568,
          imageQuality: 85,
        );
        if (picked != null) {
          setState(() => _pendingImages.add(File(picked.path)));
        }
      }
    } catch (e) {
      if (mounted) {
        InformationToast.show(
          context: context,
          message: "Could not open ${source == ImageSource.camera ? 'camera' : 'gallery'}. Please try again.",
          type: ToastType.error,
        );
      }
    }
  }

  Future<void> _digitize() async {
    if (_pendingImages.isEmpty) return;
    setState(() => _isDigitizing = true);
    try {
      final result = await AiChatbotApi().uploadRecipeImages(_pendingImages);
      if (result == null) throw Exception('Server error — please try again.');
      if (result['error'] != null) throw Exception(result['error'].toString());
      final responseStr = result['response'] as String?;
      if (responseStr == null) throw Exception('Invalid response from server.');
      _prefillFromDigitizedRecipe(jsonDecode(responseStr) as Map<String, dynamic>);
      if (mounted) setState(() => _pendingImages = []);
    } catch (e) {
      if (mounted) {
        InformationToast.show(
          context: context,
          message: e.toString().replaceFirst('Exception: ', ''),
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isDigitizing = false);
    }
  }

  void _prefillFromDigitizedRecipe(Map<String, dynamic> data) {
    for (final f in _instructions) {
      f.controller.dispose();
      f.focusNode.dispose();
    }
    setState(() {
      if (data['title'] != null) _titleController.text = data['title'].toString();
      if (data['description'] != null) _descriptionController.text = data['description'].toString();
      if (data['notes'] != null) _notesController.text = data['notes'].toString();
      if (data['preparation_time'] != null) _preptimeController.text = data['preparation_time'].toString();
      if (data['cooking_time'] != null) _cooktimeController.text = data['cooking_time'].toString();
      if (data['servings'] != null) _servingsController.text = data['servings'].toString();

      if (data['instructions'] is List && (data['instructions'] as List).isNotEmpty) {
        _instructions = (data['instructions'] as List)
            .map((step) => InstructionField(
                  controller: TextEditingController(text: step.toString()),
                  focusNode: FocusNode(),
                ))
            .toList();
      }

      if (data['tags'] is List) {
        _selectedTags = List<String>.from(data['tags']);
      }

      if (data['ingredients'] is List) {
        _mealIngredients = (data['ingredients'] as List).map((ing) {
          final raw = ing['quantity'];
          final quantity = raw != null && raw.toString() != 'null' ? raw.toString() : '';
          return MealIngredient(
            quantity: quantity,
            unit: (ing['unit'] ?? '').toString(),
            name: (ing['name'] ?? '').toString(),
            description: (ing['preparation'] ?? '').toString(),
          );
        }).toList();
      }
    });
  }

  void _submitRecipe() {
    // Build payload using MealIngredientsSection state
    final ingredients = _mealIngredients.map((ing) {
      final m = <String, dynamic>{
        if (ing.quantity.trim().isNotEmpty) 'quantity': ing.quantity.trim(),
        'unit': ing.unit,
        'name': ing.name,
        if (ing.description.trim().isNotEmpty)
          'preparation': ing.description.trim(),
      };
      if (ing.canonicalId != null) m['canonical_id'] = ing.canonicalId;
      return m;
    }).toList();

    final instructions = _instructions
        .map((f) => f.controller.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final recipeData = {
      'title': _titleController.text.trim(),
      'ingredients': ingredients,
      'instructions': instructions,
      'preparation_time': int.tryParse(_preptimeController.text) ?? 0,
      'cooking_time': int.tryParse(_cooktimeController.text) ?? 0,
      'servings': int.tryParse(_servingsController.text) ?? 1,
      'description': _descriptionController.text.trim(),
      'notes': _notesController.text.trim(),
      'tags': _selectedTags,
    };

    submitRecipe(
      context: context,
      recipeData: recipeData,
      isUpdate: false,
    );
  }

  void _onMealIngredientsChanged(List<MealIngredient> ingredients) {
    setState(() => _mealIngredients = List.of(ingredients));
  }

  void _onInstructionsChanged(List<InstructionField> instructions) {
    setState(() {
      _instructions = instructions;
    });
  }

  void _onTagsChanged(List<String> selectedTags) {
    setState(() {
      _selectedTags = selectedTags;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.close,
            size: 28,
            color: cs.onSurface,
          ),
        ),
        title: Text(
          'NEW RECIPE',
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: 2,
          ),
        ),
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        return Stack(
          children: [
            Positioned.fill(child: Container(color: Theme.of(context).scaffoldBackgroundColor)),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  children: [
                    // Photo section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: _buildPhotoSection(),
                    ),
                    // OR divider
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      child: Row(
                        children: [
                          Expanded(child: Container(height: 1, color: cs.outlineVariant)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              'OR',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                                color: cs.onSurface.withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                          Expanded(child: Container(height: 1, color: cs.outlineVariant)),
                        ],
                      ),
                    ),
                    TitleSection(titleController: _titleController),
                    Divider(
                      color: cs.outline.withValues(alpha: 0.12),
                      thickness: 1,
                      height: 1,
                    ),
                    MealIngredientsSection(
                      label: 'Ingredient',
                      ingredients: _mealIngredients,
                      onChanged: _onMealIngredientsChanged,
                    ),
                    const SizedBox(height: 8),
                    InstructionsSection(
                      instructions: _instructions,
                      onInstructionsChanged: _onInstructionsChanged,
                    ),
                    TimeSection(
                      prepTimeController: _preptimeController,
                      cookTimeController: _cooktimeController,
                      servingsController: _servingsController,
                    ),
                    TagsSection(
                      selectedTags: _selectedTags,
                      onTagsChanged: _onTagsChanged,
                    ),
                    ExtraSection(
                      descriptionController: _descriptionController,
                      notesController: _notesController,
                    ),
                    _buildCreateButton(),
                    const SizedBox(height: 32.0),
                  ],
                ),
              ),
            )
          ],
        );
      }),
    );
  }

  Widget _buildPhotoSection() {
    final cs = Theme.of(context).colorScheme;

    if (_isDigitizing) {
      return Container(
        width: double.infinity,
        height: 52,
        color: const Color(0xFF0A0A0A),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              color: Color(0xFFCAFF00),
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }

    if (_pendingImages.isEmpty) {
      return GestureDetector(
        onTap: _showPhotoSourcePicker,
        child: Container(
          width: double.infinity,
          height: 52,
          color: const Color(0xFF0A0A0A),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt, color: Color(0xFFCAFF00), size: 18),
              const SizedBox(width: 10),
              Text(
                'NEW FROM PHOTO',
                style: GoogleFonts.spaceGrotesk(
                  color: const Color(0xFFCAFF00),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Has pending images — show thumbnails + action buttons
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _pendingImages.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) => Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.file(
                    _pendingImages[i],
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 2,
                  right: 2,
                  child: GestureDetector(
                    onTap: () => setState(() => _pendingImages.removeAt(i)),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 12, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _showPhotoSourcePicker,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    border: Border.all(color: cs.outline, width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo, size: 16, color: cs.onSurface),
                      const SizedBox(width: 8),
                      Text(
                        'ADD MORE',
                        style: GoogleFonts.spaceGrotesk(
                          color: cs.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: _digitize,
                child: Container(
                  height: 48,
                  color: const Color(0xFF0A0A0A),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.auto_fix_high, size: 16, color: Color(0xFFCAFF00)),
                      const SizedBox(width: 8),
                      Text(
                        'DIGITIZE  (${_pendingImages.length})',
                        style: GoogleFonts.spaceGrotesk(
                          color: const Color(0xFFCAFF00),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCreateButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: GestureDetector(
        onTap: _submitRecipe,
        child: Container(
          width: double.infinity,
          height: 52,
          color: const Color(0xFFCAFF00),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check, color: Color(0xFF0A0A0A), size: 20),
              const SizedBox(width: 10),
              Text(
                'CREATE RECIPE',
                style: GoogleFonts.spaceGrotesk(
                  color: const Color(0xFF0A0A0A),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
