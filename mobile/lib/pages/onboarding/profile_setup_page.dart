import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/api/settings_api.dart';
import 'package:i_cant_cook/services/haptic_service.dart';
import 'package:i_cant_cook/widgets/toasts/information_toast.dart';

class OnboardingProfileSetupPage extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingProfileSetupPage({super.key, required this.onComplete});

  @override
  State<OnboardingProfileSetupPage> createState() =>
      _OnboardingProfileSetupPageState();
}

class _OnboardingProfileSetupPageState
    extends State<OnboardingProfileSetupPage> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _customDietaryController = TextEditingController();
  final _customAllergyController = TextEditingController();

  final List<String> _customDietary = [];
  final List<String> _customAllergies = [];

  String? _gender;
  bool _isVegan = false;
  bool _isVegetarian = false;
  bool _isGlutenFree = false;
  bool _isLactoseIntolerant = false;
  bool _hasPeanutAllergy = false;
  bool _hasTreeNutAllergy = false;
  bool _hasShellfishAllergy = false;
  bool _hasEggAllergy = false;
  bool _hasMilkAllergy = false;
  bool _hasSoyAllergy = false;
  bool _hasWheatAllergy = false;
  bool _hasFishAllergy = false;

  bool _isSaving = false;

  Color get _lime => Theme.of(context).colorScheme.secondary;
  Color get _btnFg => Theme.of(context).colorScheme.onSecondary;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final data = await SettingsApi().getPersonalInfo();
    if (!mounted || data == null) return;
    setState(() {
      _firstNameController.text = data['first_name'] ?? '';
      _lastNameController.text = data['last_name'] ?? '';
      _ageController.text = data['age']?.toString() ?? '';
      final g = data['gender'] as String?;
      _gender = (g != null && g.isNotEmpty) ? g : null;
      _isVegan = data['is_vegan'] ?? false;
      _isVegetarian = data['is_vegetarian'] ?? false;
      _isGlutenFree = data['is_gluten_free'] ?? false;
      _isLactoseIntolerant = data['is_lactose_intolerant'] ?? false;
      _hasPeanutAllergy = data['has_peanut_allergy'] ?? false;
      _hasTreeNutAllergy = data['has_tree_nut_allergy'] ?? false;
      _hasShellfishAllergy = data['has_shellfish_allergy'] ?? false;
      _hasEggAllergy = data['has_egg_allergy'] ?? false;
      _hasMilkAllergy = data['has_milk_allergy'] ?? false;
      _hasSoyAllergy = data['has_soy_allergy'] ?? false;
      _hasWheatAllergy = data['has_wheat_allergy'] ?? false;
      _hasFishAllergy = data['has_fish_allergy'] ?? false;
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _customDietaryController.dispose();
    _customAllergyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    final data = <String, dynamic>{
      if (_firstNameController.text.trim().isNotEmpty)
        'first_name': _firstNameController.text.trim(),
      if (_lastNameController.text.trim().isNotEmpty)
        'last_name': _lastNameController.text.trim(),
      if (_ageController.text.trim().isNotEmpty)
        'age': int.tryParse(_ageController.text.trim()),
      if (_gender != null) 'gender': _gender,
      'is_vegan': _isVegan,
      'is_vegetarian': _isVegetarian,
      'is_gluten_free': _isGlutenFree,
      'is_lactose_intolerant': _isLactoseIntolerant,
      'has_peanut_allergy': _hasPeanutAllergy,
      'has_tree_nut_allergy': _hasTreeNutAllergy,
      'has_shellfish_allergy': _hasShellfishAllergy,
      'has_egg_allergy': _hasEggAllergy,
      'has_milk_allergy': _hasMilkAllergy,
      'has_soy_allergy': _hasSoyAllergy,
      'has_wheat_allergy': _hasWheatAllergy,
      'has_fish_allergy': _hasFishAllergy,
    };
    data.removeWhere((_, v) => v == null);

    final success = await SettingsApi().updatePersonalInfo(data);

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        widget.onComplete();
      } else {
        InformationToast.warning(context, 'Failed to save settings. Continuing anyway.');
        widget.onComplete();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),

                      // ── Header ──
                      Text(
                        'TELL US ABOUT YOURSELF',
                        style: GoogleFonts.spaceGrotesk(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(width: 40, height: 2, color: _lime),
                      const SizedBox(height: 12),
                      Text(
                        'Optional — helps personalize your recipe suggestions. You can update this anytime in Settings.',
                        style: GoogleFonts.spaceGrotesk(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.45),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ── Name ──
                      _buildSectionLabel(context, 'NAME'),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              context,
                              controller: _firstNameController,
                              hint: 'First name',
                              icon: Icons.person_outline,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              context,
                              controller: _lastNameController,
                              hint: 'Last name',
                              icon: Icons.person_outline,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ── Age ──
                      _buildSectionLabel(context, 'AGE'),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: 140,
                        child: _buildTextField(
                          context,
                          controller: _ageController,
                          hint: '',
                          icon: Icons.cake_outlined,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Gender ──
                      _buildSectionLabel(context, 'GENDER'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: ['Male', 'Female', 'Other']
                            .map((g) => _buildChip(
                                  context,
                                  label: g,
                                  selected: _gender == g,
                                  onTap: () => setState(() => _gender = g),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 24),

                      // ── Restrictions ──
                      _buildSectionLabel(context, 'RESTRICTIONS'),
                      const SizedBox(height: 12),

                      _buildSubLabel(context, 'DIETARY'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildChip(context,
                              label: 'Vegan',
                              selected: _isVegan,
                              onTap: () =>
                                  setState(() => _isVegan = !_isVegan)),
                          _buildChip(context,
                              label: 'Vegetarian',
                              selected: _isVegetarian,
                              onTap: () => setState(
                                  () => _isVegetarian = !_isVegetarian)),
                          _buildChip(context,
                              label: 'Gluten-Free',
                              selected: _isGlutenFree,
                              onTap: () => setState(
                                  () => _isGlutenFree = !_isGlutenFree)),
                          _buildChip(context,
                              label: 'Lactose Intolerant',
                              selected: _isLactoseIntolerant,
                              onTap: () => setState(() => _isLactoseIntolerant =
                                  !_isLactoseIntolerant)),
                          ..._customDietary.map((item) => _buildChip(
                                context,
                                label: item,
                                selected: true,
                                onTap: () =>
                                    setState(() => _customDietary.remove(item)),
                                removable: true,
                              )),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildCustomInput(
                        context,
                        controller: _customDietaryController,
                        hint: 'Add restriction...',
                        onAdd: () {
                          final v = _customDietaryController.text.trim();
                          if (v.isNotEmpty && !_customDietary.contains(v)) {
                            setState(() {
                              _customDietary.add(v);
                              _customDietaryController.clear();
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 20),

                      _buildSubLabel(context, 'ALLERGIES'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildChip(context,
                              label: 'Peanuts',
                              selected: _hasPeanutAllergy,
                              onTap: () => setState(() =>
                                  _hasPeanutAllergy = !_hasPeanutAllergy)),
                          _buildChip(context,
                              label: 'Tree Nuts',
                              selected: _hasTreeNutAllergy,
                              onTap: () => setState(() =>
                                  _hasTreeNutAllergy = !_hasTreeNutAllergy)),
                          _buildChip(context,
                              label: 'Shellfish',
                              selected: _hasShellfishAllergy,
                              onTap: () => setState(() => _hasShellfishAllergy =
                                  !_hasShellfishAllergy)),
                          _buildChip(context,
                              label: 'Eggs',
                              selected: _hasEggAllergy,
                              onTap: () => setState(
                                  () => _hasEggAllergy = !_hasEggAllergy)),
                          _buildChip(context,
                              label: 'Milk',
                              selected: _hasMilkAllergy,
                              onTap: () => setState(
                                  () => _hasMilkAllergy = !_hasMilkAllergy)),
                          _buildChip(context,
                              label: 'Soy',
                              selected: _hasSoyAllergy,
                              onTap: () => setState(
                                  () => _hasSoyAllergy = !_hasSoyAllergy)),
                          _buildChip(context,
                              label: 'Wheat',
                              selected: _hasWheatAllergy,
                              onTap: () => setState(
                                  () => _hasWheatAllergy = !_hasWheatAllergy)),
                          _buildChip(context,
                              label: 'Fish',
                              selected: _hasFishAllergy,
                              onTap: () => setState(
                                  () => _hasFishAllergy = !_hasFishAllergy)),
                          ..._customAllergies.map((item) => _buildChip(
                                context,
                                label: item,
                                selected: true,
                                onTap: () => setState(
                                    () => _customAllergies.remove(item)),
                                removable: true,
                              )),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildCustomInput(
                        context,
                        controller: _customAllergyController,
                        hint: 'Add allergy...',
                        onAdd: () {
                          final v = _customAllergyController.text.trim();
                          if (v.isNotEmpty && !_customAllergies.contains(v)) {
                            setState(() {
                              _customAllergies.add(v);
                              _customAllergyController.clear();
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),

              // ── Bottom actions ──
              Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  8,
                  24,
                  MediaQuery.of(context).viewInsets.bottom > 0 ? 16 : 32,
                ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            GestureDetector(
                              onTap: _isSaving
                                  ? null
                                  : () {
                                      HapticService.mediumImpact();
                                      _save();
                                    },
                              child: Container(
                                height: 52,
                                color: _lime,
                                child: _isSaving
                                    ? Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: _btnFg,
                                            strokeWidth: 2.5,
                                          ),
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.check,
                                              color: _btnFg, size: 18),
                                          const SizedBox(width: 10),
                                          Text(
                                            'SAVE & CONTINUE',
                                            style: GoogleFonts.spaceGrotesk(
                                              color: _btnFg,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 1.5,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            GestureDetector(
                              onTap: _isSaving ? null : widget.onComplete,
                              child: Center(
                                child: Text(
                                  'Skip for now',
                                  style: GoogleFonts.spaceGrotesk(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.4),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        Container(width: 20, height: 2, color: _lime),
      ],
    );
  }

  Widget _buildSubLabel(BuildContext context, String label) {
    return Text(
      label,
      style: GoogleFonts.spaceGrotesk(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.spaceGrotesk(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      cursorColor: _lime,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.spaceGrotesk(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Icon(
          icon,
          color:
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
          size: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(
            color:
                Theme.of(context).colorScheme.outline.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: _lime, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        isDense: true,
      ),
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
    bool removable = false,
  }) {
    return GestureDetector(
      onTap: () {
        HapticService.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? _lime : Colors.transparent,
          borderRadius: BorderRadius.zero,
          border: Border.all(
            color: selected
                ? _lime
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                color: selected
                    ? _btnFg
                    : Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.8),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
            if (removable) ...[
              const SizedBox(width: 6),
              Icon(Icons.close, size: 14, color: _btnFg),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCustomInput(
    BuildContext context, {
    required TextEditingController controller,
    required String hint,
    required VoidCallback onAdd,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            style: GoogleFonts.spaceGrotesk(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            cursorColor: _lime,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onAdd(),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.spaceGrotesk(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.3),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: _lime, width: 1.5),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            height: 44,
            width: 44,
            color: _lime,
            child: Icon(Icons.add, color: _btnFg, size: 20),
          ),
        ),
      ],
    );
  }
}
