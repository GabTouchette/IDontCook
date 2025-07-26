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
          const SizedBox(height: 8.0),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🕒 Prep Time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Prep Time",
                      style: TextStyle(
                        color: ColorPalette.offWhite,
                        fontSize: 14,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      decoration: BoxDecoration(
                        color: ColorPalette.lightgray,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        keyboardType: TextInputType.number,
                        controller: prepTimeController,
                        style: const TextStyle(
                          color: ColorPalette.offBlack,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'minutes',
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
              ),

              const SizedBox(width: 16.0),

              // 🔥 Cook Time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Cook Time",
                      style: TextStyle(
                        color: ColorPalette.offWhite,
                        fontSize: 14,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      decoration: BoxDecoration(
                        color: ColorPalette.lightgray,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        keyboardType: TextInputType.number,
                        controller: cookTimeController,
                        style: const TextStyle(
                          color: ColorPalette.offBlack,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'minutes',
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
              ),
            ],
          ),
        ],
      ),
    );
  }
}
