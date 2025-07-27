import 'package:flutter/material.dart';
import 'package:i_cant_cook/api/settings_api.dart';
import 'package:i_cant_cook/enums/toast_type.dart';
import 'package:i_cant_cook/providers/settings_provider.dart';
import 'package:i_cant_cook/widgets/toasts/information_toast.dart';
import 'package:provider/provider.dart';

class PersonalInfoDialog extends StatelessWidget {
  const PersonalInfoDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
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
                              color: Theme.of(context)
                                  .colorScheme
                                  .surface
                                  .withOpacity(0.7),
                            ),
                            child: Icon(Icons.close,
                                color: Theme.of(context).colorScheme.onSurface,
                                size: 32),
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
                                color: Theme.of(context).colorScheme.onSurface,
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
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.2),
                            ),
                            child: Icon(Icons.check,
                                color: Theme.of(context).colorScheme.primary,
                                size: 32),
                          ),
                          onPressed: () async {
                            final success = await SettingsApi()
                                .updatePersonalInfo(provider.toJson());
                            if (success && context.mounted) {
                              Navigator.of(context).pop();
                            } else {
                              InformationToast.show(
                                context: context,
                                message: "Failed to save settings",
                                type: ToastType.error,
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
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.8),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            ),
                            _buildNumberField(
                                context, "Age", provider.age, provider.setAge),
                            _buildDropdown(
                                context,
                                "Gender",
                                provider.gender,
                                (val) => provider.setGender(val ?? ''),
                                ['Male', 'Female', 'Non-Binary', 'Other']),
                            _buildTextField(context, "City", provider.city,
                                provider.setCity),
                            _buildTextField(context, "Country",
                                provider.country, provider.setCountry),
                            _buildTextField(context, "Ethnicity",
                                provider.ethnicity, provider.setEthnicity),

                            // Dietary Preferences Section
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 16, bottom: 8),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  "DIETARY PREFERENCES",
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.8),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            ),
                            _buildSwitch(context, "Vegan", provider.isVegan,
                                provider.toggleVegan),
                            _buildSwitch(
                                context,
                                "Vegetarian",
                                provider.isVegetarian,
                                provider.toggleVegetarian),
                            _buildSwitch(
                                context,
                                "Gluten Free",
                                provider.isGlutenFree,
                                provider.toggleGlutenFree),
                            _buildSwitch(
                                context,
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
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.8),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            ),
                            _buildSwitch(
                                context,
                                "Peanut",
                                provider.hasPeanutAllergy,
                                provider.togglePeanutAllergy),
                            _buildSwitch(
                                context,
                                "Tree Nuts",
                                provider.hasTreeNutAllergy,
                                provider.toggleTreeNutAllergy),
                            _buildSwitch(
                                context,
                                "Shellfish",
                                provider.hasShellfishAllergy,
                                provider.toggleShellfishAllergy),
                            _buildSwitch(
                                context,
                                "Eggs",
                                provider.hasEggAllergy,
                                provider.toggleEggAllergy),
                            _buildSwitch(
                                context,
                                "Milk",
                                provider.hasMilkAllergy,
                                provider.toggleMilkAllergy),
                            _buildSwitch(context, "Soy", provider.hasSoyAllergy,
                                provider.toggleSoyAllergy),
                            _buildSwitch(
                                context,
                                "Wheat",
                                provider.hasWheatAllergy,
                                provider.toggleWheatAllergy),
                            _buildSwitch(
                                context,
                                "Fish",
                                provider.hasFishAllergy,
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
                                  foregroundColor:
                                      Theme.of(context).colorScheme.error,
                                  side: BorderSide(
                                      color:
                                          Theme.of(context).colorScheme.error),
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

  Widget _buildTextField(BuildContext context, String label, String value,
      Function(String) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle:
              TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withOpacity(0.5)),
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide:
                BorderSide(color: Theme.of(context).colorScheme.primary),
            borderRadius: BorderRadius.circular(10),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface, fontSize: 16),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildNumberField(BuildContext context, String label, int? value,
      Function(int?) onChanged) {
    final controller = TextEditingController(text: value?.toString() ?? '');
    controller.selection = TextSelection.fromPosition(
        TextPosition(offset: controller.text.length));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle:
              TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withOpacity(0.5)),
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide:
                BorderSide(color: Theme.of(context).colorScheme.primary),
            borderRadius: BorderRadius.circular(10),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        keyboardType: TextInputType.number,
        style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface, fontSize: 16),
        onChanged: (val) => onChanged(int.tryParse(val)),
      ),
    );
  }

  Widget _buildDropdown(BuildContext context, String label, String selected,
      ValueChanged<String?> onChanged, List<String> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        value: selected.isEmpty ? null : selected,
        decoration: InputDecoration(
          labelText: label,
          labelStyle:
              TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withOpacity(0.5)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withOpacity(0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                BorderSide(color: Theme.of(context).colorScheme.primary),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        dropdownColor: Theme.of(context).colorScheme.surface,
        style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface, fontSize: 16),
        icon: Icon(Icons.arrow_drop_down,
            color: Theme.of(context).colorScheme.onSurface),
        items: items
            .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(item,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface)),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSwitch(BuildContext context, String label, bool value,
      Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
        ),
        child: SwitchListTile(
          value: value,
          onChanged: onChanged,
          title: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
            ),
          ),
          activeColor: Theme.of(context).colorScheme.primary,
          inactiveTrackColor:
              Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
