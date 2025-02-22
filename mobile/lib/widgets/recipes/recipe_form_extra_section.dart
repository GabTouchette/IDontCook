import 'package:flutter/material.dart';
import 'package:i_cant_cook/theme/colors.dart';

class ExtraSection extends StatelessWidget {
  final TextEditingController descriptionController;
  final TextEditingController notesController;

  const ExtraSection({
    Key? key,
    required this.descriptionController,
    required this.notesController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Extra",
            style: TextStyle(
              color: ColorPalette.offWhite,
              fontWeight: FontWeight.w300,
              fontSize: 24,
            ),
          ),
          SizedBox(height: 8.0),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            decoration: BoxDecoration(
              color: ColorPalette.lightgray,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: descriptionController,
              style: TextStyle(
                color: ColorPalette.offBlack,
              ),
              decoration: InputDecoration(
                hintText: 'Description',
                hintStyle: TextStyle(
                  color: ColorPalette.placeholdergray,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12.0),
              ),
            ),
          ),
          SizedBox(height: 32.0),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            decoration: BoxDecoration(
              color: ColorPalette.lightgray,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: notesController,
              style: TextStyle(
                color: ColorPalette.offBlack,
              ),
              decoration: InputDecoration(
                hintText: 'Notes',
                hintStyle: TextStyle(
                  color: ColorPalette.placeholdergray,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12.0),
              ),
            ),
          ),
          SizedBox(height: 16.0),
        ],
      ),
    );
  }
}
