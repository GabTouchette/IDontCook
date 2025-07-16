import 'package:flutter/material.dart';
import 'package:i_cant_cook/api/settings_api.dart';

class SettingsProvider with ChangeNotifier {
  final SettingsApi _settingsApi = SettingsApi();

  // Personal profile info
  int? age;
  String gender = '';
  String city = '';
  String country = '';
  String ethnicity = '';

  // Dietary preferences
  bool isVegan = false;
  bool isVegetarian = false;
  bool isGlutenFree = false;
  bool isLactoseIntolerant = false;

  // Allergies
  bool hasPeanutAllergy = false;
  bool hasTreeNutAllergy = false;
  bool hasShellfishAllergy = false;
  bool hasEggAllergy = false;
  bool hasMilkAllergy = false;
  bool hasSoyAllergy = false;
  bool hasWheatAllergy = false;
  bool hasFishAllergy = false;

  // Personal info setters
  void setAge(int? value) {
    age = value;
    notifyListeners();
  }

  void setGender(String value) {
    gender = value;
    notifyListeners();
  }

  void setCity(String value) {
    city = value;
    notifyListeners();
  }

  void setCountry(String value) {
    country = value;
    notifyListeners();
  }

  void setEthnicity(String value) {
    ethnicity = value;
    notifyListeners();
  }

  // Dietary preferences toggles
  void toggleVegan(bool value) {
    isVegan = value;
    notifyListeners();
  }

  void toggleVegetarian(bool value) {
    isVegetarian = value;
    notifyListeners();
  }

  void toggleGlutenFree(bool value) {
    isGlutenFree = value;
    notifyListeners();
  }

  void toggleLactoseIntolerant(bool value) {
    isLactoseIntolerant = value;
    notifyListeners();
  }

  // Allergies toggles
  void togglePeanutAllergy(bool value) {
    hasPeanutAllergy = value;
    notifyListeners();
  }

  void toggleTreeNutAllergy(bool value) {
    hasTreeNutAllergy = value;
    notifyListeners();
  }

  void toggleShellfishAllergy(bool value) {
    hasShellfishAllergy = value;
    notifyListeners();
  }

  void toggleEggAllergy(bool value) {
    hasEggAllergy = value;
    notifyListeners();
  }

  void toggleMilkAllergy(bool value) {
    hasMilkAllergy = value;
    notifyListeners();
  }

  void toggleSoyAllergy(bool value) {
    hasSoyAllergy = value;
    notifyListeners();
  }

  void toggleWheatAllergy(bool value) {
    hasWheatAllergy = value;
    notifyListeners();
  }

  void toggleFishAllergy(bool value) {
    hasFishAllergy = value;
    notifyListeners();
  }

  void clearPersonalInfo() {
    age = null;
    gender = '';
    city = '';
    country = '';
    ethnicity = '';
    isVegan = false;
    isVegetarian = false;
    isGlutenFree = false;
    isLactoseIntolerant = false;
    hasPeanutAllergy = false;
    hasTreeNutAllergy = false;
    hasShellfishAllergy = false;
    hasEggAllergy = false;
    hasMilkAllergy = false;
    hasSoyAllergy = false;
    hasWheatAllergy = false;
    hasFishAllergy = false;
    notifyListeners();
  }

  Map<String, dynamic> toJson() {
    return {
      'age': age,
      'gender': gender,
      'city': city,
      'country': country,
      'ethnicity': ethnicity,
      'is_vegan': isVegan,
      'is_vegetarian': isVegetarian,
      'is_gluten_free': isGlutenFree,
      'is_lactose_intolerant': isLactoseIntolerant,
      'has_peanut_allergy': hasPeanutAllergy,
      'has_tree_nut_allergy': hasTreeNutAllergy,
      'has_shellfish_allergy': hasShellfishAllergy,
      'has_egg_allergy': hasEggAllergy,
      'has_milk_allergy': hasMilkAllergy,
      'has_soy_allergy': hasSoyAllergy,
      'has_wheat_allergy': hasWheatAllergy,
      'has_fish_allergy': hasFishAllergy,
    };
  }

  Future<void> fetchAndLoadPersonalInfo() async {
    final data = await _settingsApi.getPersonalInfo();
    if (data == null) return;

    age = data['age'];
    gender = data['gender'] ?? '';
    city = data['city'] ?? '';
    country = data['country'] ?? '';
    ethnicity = data['ethnicity'] ?? '';

    isVegan = data['is_vegan'] ?? false;
    isVegetarian = data['is_vegetarian'] ?? false;
    isGlutenFree = data['is_gluten_free'] ?? false;
    isLactoseIntolerant = data['is_lactose_intolerant'] ?? false;

    hasPeanutAllergy = data['has_peanut_allergy'] ?? false;
    hasTreeNutAllergy = data['has_tree_nut_allergy'] ?? false;
    hasShellfishAllergy = data['has_shellfish_allergy'] ?? false;
    hasEggAllergy = data['has_egg_allergy'] ?? false;
    hasMilkAllergy = data['has_milk_allergy'] ?? false;
    hasSoyAllergy = data['has_soy_allergy'] ?? false;
    hasWheatAllergy = data['has_wheat_allergy'] ?? false;
    hasFishAllergy = data['has_fish_allergy'] ?? false;

    notifyListeners();
  }
}
