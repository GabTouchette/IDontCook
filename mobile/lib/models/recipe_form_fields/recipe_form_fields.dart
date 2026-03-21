import 'package:flutter/material.dart';

class IngredientField {
  TextEditingController controller;
  FocusNode focusNode;
  int? canonicalId;
  String? canonicalName;
  // Structured fields
  TextEditingController qtyController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController descController = TextEditingController();
  String unit = '';

  IngredientField({
    required this.controller,
    required this.focusNode,
    this.canonicalId,
    this.canonicalName,
  });
}

class InstructionField {
  TextEditingController controller;
  FocusNode focusNode;

  InstructionField({required this.controller, required this.focusNode});
}
