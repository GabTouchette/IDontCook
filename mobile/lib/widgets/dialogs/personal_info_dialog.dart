import 'package:flutter/material.dart';
import 'package:i_cant_cook/api/settings_api.dart';
import 'package:i_cant_cook/providers/settings_provider.dart';
import 'package:i_cant_cook/theme/colors.dart';
import 'package:provider/provider.dart';

class PersonalInfoDialog extends StatelessWidget {
  const PersonalInfoDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ColorPalette.darkgray,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.3),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SafeArea(
        child: Consumer<SettingsProvider>(
          builder: (context, provider, child) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.85,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
                child: Column(
                  children: [
                    // App bar row with X and Save
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: ColorPalette.darkgray.withOpacity(0.7),
                            ),
                            child: const Icon(Icons.close,
                                color: ColorPalette.offWhite, size: 32),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          splashRadius: 32,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0, top: 8),
                          child: Center(
                            child: Text(
                              "Personal Info",
                              style: TextStyle(
                                color: ColorPalette.offWhite,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: ColorPalette.green.withOpacity(0.2),
                            ),
                            child: const Icon(Icons.check,
                                color: ColorPalette.green, size: 32),
                          ),
                          onPressed: () async {
                            final success = await SettingsApi()
                                .updatePersonalInfo(provider.toJson());
                            if (success && context.mounted) {
                              Navigator.of(context).pop();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text("Failed to save settings")),
                              );
                            }
                          },
                          splashRadius: 32,
                        ),
                      ],
                    ),

                    // Scrollable content
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 16, bottom: 8),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  "GENERAL INFORMATION",
                                  style: TextStyle(
                                    color:
                                        ColorPalette.offWhite.withOpacity(0.8),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            ),
                            _buildNumberField(
                                "Age", provider.age, provider.setAge),
                            _buildDropdown(
                                "Gender",
                                provider.gender,
                                (val) => provider.setGender(val ?? ''),
                                ['Male', 'Female', 'Non-Binary', 'Other']),
                            _buildTextField(
                                "City", provider.city, provider.setCity),
                            _buildTextField("Country", provider.country,
                                provider.setCountry),
                            _buildTextField("Ethnicity", provider.ethnicity,
                                provider.setEthnicity),

                            // Dietary Preferences Section
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 16, bottom: 8),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  "DIETARY PREFERENCES",
                                  style: TextStyle(
                                    color:
                                        ColorPalette.offWhite.withOpacity(0.8),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            ),
                            _buildSwitch("Vegan", provider.isVegan,
                                provider.toggleVegan),
                            _buildSwitch("Vegetarian", provider.isVegetarian,
                                provider.toggleVegetarian),
                            _buildSwitch("Gluten Free", provider.isGlutenFree,
                                provider.toggleGlutenFree),
                            _buildSwitch(
                                "Lactose Intolerant",
                                provider.isLactoseIntolerant,
                                provider.toggleLactoseIntolerant),

                            // Allergies Section
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 16, bottom: 8),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  "ALLERGIES",
                                  style: TextStyle(
                                    color:
                                        ColorPalette.offWhite.withOpacity(0.8),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            ),
                            _buildSwitch("Peanut", provider.hasPeanutAllergy,
                                provider.togglePeanutAllergy),
                            _buildSwitch(
                                "Tree Nuts",
                                provider.hasTreeNutAllergy,
                                provider.toggleTreeNutAllergy),
                            _buildSwitch(
                                "Shellfish",
                                provider.hasShellfishAllergy,
                                provider.toggleShellfishAllergy),
                            _buildSwitch("Eggs", provider.hasEggAllergy,
                                provider.toggleEggAllergy),
                            _buildSwitch("Milk", provider.hasMilkAllergy,
                                provider.toggleMilkAllergy),
                            _buildSwitch("Soy", provider.hasSoyAllergy,
                                provider.toggleSoyAllergy),
                            _buildSwitch("Wheat", provider.hasWheatAllergy,
                                provider.toggleWheatAllergy),
                            _buildSwitch("Fish", provider.hasFishAllergy,
                                provider.toggleFishAllergy),
                            const SizedBox(height: 32),
                            // Clear all button
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: OutlinedButton(
                                onPressed: () {
                                  provider.clearPersonalInfo();
                                  // No need to call setState, Consumer will rebuild
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: ColorPalette.red,
                                  side:
                                      const BorderSide(color: ColorPalette.red),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 24),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.delete_outline, size: 18),
                                    SizedBox(width: 8),
                                    Text("CLEAR ALL"),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label, String value, Function(String) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: ColorPalette.placeholdergray),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
                color: ColorPalette.placeholdergray.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: ColorPalette.blue),
            borderRadius: BorderRadius.circular(10),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        style: const TextStyle(color: ColorPalette.offWhite, fontSize: 16),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildNumberField(String label, int? value, Function(int?) onChanged) {
    final controller = TextEditingController(text: value?.toString() ?? '');
    controller.selection = TextSelection.fromPosition(
        TextPosition(offset: controller.text.length));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: ColorPalette.placeholdergray),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
                color: ColorPalette.placeholdergray.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: ColorPalette.blue),
            borderRadius: BorderRadius.circular(10),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        keyboardType: TextInputType.number,
        style: const TextStyle(color: ColorPalette.offWhite, fontSize: 16),
        onChanged: (val) => onChanged(int.tryParse(val)),
      ),
    );
  }

  Widget _buildDropdown(String label, String selected,
      ValueChanged<String?> onChanged, List<String> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        value: selected.isEmpty ? null : selected,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: ColorPalette.placeholdergray),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
                color: ColorPalette.placeholdergray.withOpacity(0.5)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
                color: ColorPalette.placeholdergray.withOpacity(0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: ColorPalette.blue),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        dropdownColor: ColorPalette.darkgray,
        style: const TextStyle(color: ColorPalette.offWhite, fontSize: 16),
        icon: const Icon(Icons.arrow_drop_down, color: ColorPalette.offWhite),
        items: items
            .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(item,
                      style: const TextStyle(color: ColorPalette.offWhite)),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSwitch(String label, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: ColorPalette.darkgray.withOpacity(0.8),
        ),
        child: SwitchListTile(
          value: value,
          onChanged: onChanged,
          title: Text(
            label,
            style: const TextStyle(
              color: ColorPalette.offWhite,
              fontSize: 16,
            ),
          ),
          activeColor: ColorPalette.blue,
          inactiveTrackColor: ColorPalette.placeholdergray.withOpacity(0.5),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
