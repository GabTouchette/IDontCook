import 'package:flutter/material.dart';
import 'package:i_cant_cook/theme/colors.dart';

class TimeSection extends StatelessWidget {
  final TextEditingController prepTimeController;
  final TextEditingController cookTimeController;

  const TimeSection({
    Key? key,
    required this.prepTimeController,
    required this.cookTimeController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Time",
            style: TextStyle(
              color: ColorPalette.offWhite,
              fontWeight: FontWeight.w300,
              fontSize: 24,
            ),
          ),
          SizedBox(height: 8.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  decoration: BoxDecoration(
                    color: ColorPalette.lightgray,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    keyboardType: TextInputType.number,
                    controller: prepTimeController,
                    style: TextStyle(
                      color: ColorPalette.offBlack,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Prep Time (min)',
                      hintStyle: TextStyle(
                        color: ColorPalette.placeholdergray,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12.0),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16.0),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  decoration: BoxDecoration(
                    color: ColorPalette.lightgray,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    keyboardType: TextInputType.number,
                    controller: cookTimeController,
                    style: TextStyle(
                      color: ColorPalette.offBlack,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Cook Time (min)',
                      hintStyle: TextStyle(
                        color: ColorPalette.placeholdergray,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12.0),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
