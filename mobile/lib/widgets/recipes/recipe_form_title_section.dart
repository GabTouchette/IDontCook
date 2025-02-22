
import 'package:flutter/material.dart';
import 'package:i_cant_cook/theme/colors.dart';

class TitleSection extends StatelessWidget {
  final TextEditingController titleController;

  const TitleSection({Key? key, required this.titleController}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Title",
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
              controller: titleController,
              style: TextStyle(
                color: ColorPalette.offBlack,
              ),
              decoration: InputDecoration(
                hintText: 'Recipe title',
                hintStyle: TextStyle(
                  color: ColorPalette.placeholdergray,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12.0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
