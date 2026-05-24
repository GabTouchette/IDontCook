import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/api/settings_api.dart';
import 'package:i_cant_cook/enums/toast_type.dart';
import 'package:i_cant_cook/services/haptic_service.dart';
import 'package:i_cant_cook/widgets/toasts/information_toast.dart';

class PersonalInfoPage extends StatefulWidget {
  const PersonalInfoPage({super.key});

  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  static const _lime = Color(0xFFCAFF00);
  static const _btnFg = Color(0xFF0A0A0A);

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _ageController = TextEditingController();

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

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final data = await SettingsApi().getPersonalInfo();
    if (!mounted) return;
    if (data != null) {
      setState(() {
        _firstNameController.text = data['first_name'] ?? '';
        _lastNameController.text = data['last_name'] ?? '';
        _ageController.text = data['age']?.toString() ?? '';
        _gender = (data['gender'] as String?)?.isNotEmpty == true
            ? data['gender'] as String
            : null;
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
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final payload = <String, dynamic>{
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
    payload.removeWhere((_, v) => v == null);

    final success = await SettingsApi().updatePersonalInfo(payload);
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (success) {
      Navigator.of(context).pop();
    } else {
      InformationToast.show(
        context: context,
        message: 'Failed to save settings',
        type: ToastType.error,
      );
    }
  }

  void _clearAll() {
    setState(() {
      _firstNameController.clear();
      _lastNameController.clear();
      _ageController.clear();
      _gender = null;
      _isVegan = false;
      _isVegetarian = false;
      _isGlutenFree = false;
      _isLactoseIntolerant = false;
      _hasPeanutAllergy = false;
      _hasTreeNutAllergy = false;
      _hasShellfishAllergy = false;
      _hasEggAllergy = false;
      _hasMilkAllergy = false;
      _hasSoyAllergy = false;
      _hasWheatAllergy = false;
      _hasFishAllergy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        leading: IconButton(
          padding: const EdgeInsets.only(left: 16.0),
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.chevron_left,
            size: 32,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          'PERSONAL INFO',
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            letterSpacing: 2.5,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.15),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        Text(
                          'Optional — helps personalize your recipe suggestions.',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.45),
                          ),
                        ),
                        const SizedBox(height: 28),

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
                                    onTap: () =>
                                        setState(() => _gender = g),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 28),

                        // ── Restrictions ──
                        _buildSectionLabel(context, 'RESTRICTIONS'),
                        const SizedBox(height: 14),

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
                                onTap: () => setState(() =>
                                    _isLactoseIntolerant =
                                        !_isLactoseIntolerant)),
                          ],
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
                                onTap: () => setState(() =>
                                    _hasShellfishAllergy =
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
                                onTap: () => setState(() =>
                                    _hasWheatAllergy = !_hasWheatAllergy)),
                            _buildChip(context,
                                label: 'Fish',
                                selected: _hasFishAllergy,
                                onTap: () => setState(
                                    () => _hasFishAllergy = !_hasFishAllergy)),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Clear all
                        GestureDetector(
                          onTap: _clearAll,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context).colorScheme.error,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.delete_outline,
                                    size: 18,
                                    color: Theme.of(context).colorScheme.error),
                                const SizedBox(width: 8),
                                Text(
                                  'CLEAR ALL',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.5,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                // Save button pinned at bottom
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.15),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                  child: GestureDetector(
                    onTap: _isSaving
                        ? null
                        : () {
                            HapticService.mediumImpact();
                            _save();
                          },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      color: Theme.of(context).colorScheme.primary,
                      child: _isSaving
                          ? Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                  strokeWidth: 2.5,
                                ),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check,
                                    size: 18,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary),
                                const SizedBox(width: 8),
                                Text(
                                  'SAVE CHANGES',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 2.0,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
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
        color:
            Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
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
          color:
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Icon(
          icon,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
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
        focusedBorder: const OutlineInputBorder(
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
                : Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Text(
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
      ),
    );
  }
}
