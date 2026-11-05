import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/api/settings_api.dart';
import 'package:i_cant_cook/providers/settings_provider.dart';
import 'package:i_cant_cook/widgets/toasts/information_toast.dart';
import 'package:provider/provider.dart';

class PersonalInfoDialog extends StatelessWidget {
  const PersonalInfoDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, provider, _) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.92,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Header row
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 8, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'PERSONAL INFO',
                          style: GoogleFonts.spaceGrotesk(
                            fontWeight: FontWeight.w700,
                            fontSize: 22,
                            letterSpacing: 2.5,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          size: 22,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.5),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color:
                      Theme.of(context).colorScheme.outline.withOpacity(0.15),
                ),
                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        _buildSectionHeader(context, 'GENERAL INFORMATION'),
                        const SizedBox(height: 6),
                        Text(
                          'Optional — helps personalize AI recipe suggestions.',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.45),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          context,
                          'AGE',
                          provider.age?.toString() ?? '',
                          (val) => provider.setAge(int.tryParse(val)),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),
                        _buildDropdown(
                          context,
                          'GENDER',
                          provider.gender,
                          (val) => provider.setGender(val ?? ''),
                          ['Male', 'Female', 'Other'],
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                            context, 'CITY', provider.city, provider.setCity),
                        const SizedBox(height: 12),
                        _buildTextField(context, 'COUNTRY', provider.country,
                            provider.setCountry),
                        const SizedBox(height: 12),
                        _buildTextField(context, 'ETHNICITY',
                            provider.ethnicity, provider.setEthnicity),
                        const SizedBox(height: 28),
                        _buildSectionHeader(context, 'DIETARY PREFERENCES'),
                        const SizedBox(height: 8),
                        _buildSwitchRow(context, 'Vegan', provider.isVegan,
                            provider.toggleVegan),
                        _buildInnerDivider(context),
                        _buildSwitchRow(context, 'Vegetarian',
                            provider.isVegetarian, provider.toggleVegetarian),
                        _buildInnerDivider(context),
                        _buildSwitchRow(context, 'Gluten Free',
                            provider.isGlutenFree, provider.toggleGlutenFree),
                        _buildInnerDivider(context),
                        _buildSwitchRow(
                            context,
                            'Lactose Intolerant',
                            provider.isLactoseIntolerant,
                            provider.toggleLactoseIntolerant),
                        const SizedBox(height: 28),
                        _buildSectionHeader(context, 'ALLERGIES'),
                        const SizedBox(height: 8),
                        _buildSwitchRow(
                            context,
                            'Peanut',
                            provider.hasPeanutAllergy,
                            provider.togglePeanutAllergy),
                        _buildInnerDivider(context),
                        _buildSwitchRow(
                            context,
                            'Tree Nuts',
                            provider.hasTreeNutAllergy,
                            provider.toggleTreeNutAllergy),
                        _buildInnerDivider(context),
                        _buildSwitchRow(
                            context,
                            'Shellfish',
                            provider.hasShellfishAllergy,
                            provider.toggleShellfishAllergy),
                        _buildInnerDivider(context),
                        _buildSwitchRow(context, 'Eggs', provider.hasEggAllergy,
                            provider.toggleEggAllergy),
                        _buildInnerDivider(context),
                        _buildSwitchRow(
                            context,
                            'Milk',
                            provider.hasMilkAllergy,
                            provider.toggleMilkAllergy),
                        _buildInnerDivider(context),
                        _buildSwitchRow(context, 'Soy', provider.hasSoyAllergy,
                            provider.toggleSoyAllergy),
                        _buildInnerDivider(context),
                        _buildSwitchRow(
                            context,
                            'Wheat',
                            provider.hasWheatAllergy,
                            provider.toggleWheatAllergy),
                        _buildInnerDivider(context),
                        _buildSwitchRow(
                            context,
                            'Fish',
                            provider.hasFishAllergy,
                            provider.toggleFishAllergy),
                        const SizedBox(height: 28),
                        // Clear all
                        GestureDetector(
                          onTap: provider.clearPersonalInfo,
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
                  color:
                      Theme.of(context).colorScheme.outline.withOpacity(0.15),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                  child: GestureDetector(
                    onTap: () async {
                      final success = await SettingsApi()
                          .updatePersonalInfo(provider.toJson());
                      if (success && context.mounted) {
                        Navigator.of(context).pop();
                      } else if (context.mounted) {
                        InformationToast.error(context, 'Failed to save settings.');
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      color: Theme.of(context).colorScheme.primary,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check,
                              size: 18,
                              color: Theme.of(context).colorScheme.onPrimary),
                          const SizedBox(width: 8),
                          Text(
                            'SAVE CHANGES',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.0,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final lime = Theme.of(context).colorScheme.secondary;
    return Row(
      children: [
        Container(width: 20, height: 2, color: lime),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
          ),
        ),
      ],
    );
  }

  Widget _buildInnerDivider(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: Theme.of(context).colorScheme.outline.withOpacity(0.08),
    );
  }

  Widget _buildTextField(
    BuildContext context,
    String label,
    String value,
    Function(String) onChanged, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      initialValue: value,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.spaceGrotesk(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.25),
          ),
          borderRadius: BorderRadius.zero,
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.5,
          ),
          borderRadius: BorderRadius.zero,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      style: GoogleFonts.spaceGrotesk(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildDropdown(
    BuildContext context,
    String label,
    String selected,
    ValueChanged<String?> onChanged,
    List<String> items,
  ) {
    return DropdownButtonFormField<String>(
      value: selected.isEmpty ? null : selected,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.spaceGrotesk(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.25),
          ),
          borderRadius: BorderRadius.zero,
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.5,
          ),
          borderRadius: BorderRadius.zero,
        ),
        border: OutlineInputBorder(
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.25),
          ),
          borderRadius: BorderRadius.zero,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      dropdownColor: Theme.of(context).colorScheme.surface,
      style: GoogleFonts.spaceGrotesk(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      icon: Icon(
        Icons.arrow_drop_down,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
      ),
      items: items
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(
                  item,
                  style: GoogleFonts.spaceGrotesk(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildSwitchRow(
    BuildContext context,
    String label,
    bool value,
    Function(bool) onChanged,
  ) {
    final lime = Theme.of(context).colorScheme.secondary;
    return Material(
      color: Colors.transparent,
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        activeColor: lime,
        activeTrackColor: lime.withOpacity(0.35),
        inactiveTrackColor:
            Theme.of(context).colorScheme.outline.withOpacity(0.2),
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}
