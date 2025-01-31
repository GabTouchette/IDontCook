
import 'package:flutter/material.dart';
import 'package:mobile/models/recipe_form_fields.dart';
import 'package:mobile/theme/colors.dart';

class InstructionsSection extends StatefulWidget {
  final List<InstructionField> instructions;
  final ValueChanged<List<InstructionField>> onInstructionsChanged;

  const InstructionsSection({
    Key? key,
    required this.instructions,
    required this.onInstructionsChanged,
  }) : super(key: key);

  @override
  _InstructionsSectionState createState() => _InstructionsSectionState();
}

class _InstructionsSectionState extends State<InstructionsSection> {
  List<Widget> _buildInstructionsInputFields() {
    List<Widget> inputFields = [];

    for (int i = 0; i < widget.instructions.length; i++) {
      inputFields.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            children: [
              Text(
                "${i + 1}.",
                style: TextStyle(
                  color: ColorPalette.offWhite,
                  fontSize: 18,
                ),
              ),
              SizedBox(width: 8.0),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  decoration: BoxDecoration(
                    color: ColorPalette.lightgray,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: widget.instructions[i].controller,
                    focusNode: widget.instructions[i].focusNode,
                    maxLines: 4,
                    style: TextStyle(
                      color: ColorPalette.offBlack,
                    ),
                    onChanged: (text) {
                      if (i == widget.instructions.length - 1 && text.isNotEmpty) {
                        setState(() {
                          widget.instructions.add(InstructionField(
                              controller: TextEditingController(),
                              focusNode: FocusNode()));
                        });
                        widget.onInstructionsChanged(widget.instructions);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Instruction',
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
              IconButton(
                icon: Icon(Icons.delete, color: ColorPalette.offWhite),
                onPressed: widget.instructions.length > 1
                    ? () {
                        setState(() {
                          widget.instructions.removeAt(i);
                        });
                        widget.onInstructionsChanged(widget.instructions);
                      }
                    : null,
              ),
            ],
          ),
        ),
      );
    }

    return inputFields;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Instructions",
            style: TextStyle(
              color: ColorPalette.offWhite,
              fontWeight: FontWeight.w300,
              fontSize: 24,
            ),
          ),
          SizedBox(height: 8.0),
          ..._buildInstructionsInputFields(),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              "Enter each instruction step by step.",
              style: TextStyle(
                color: ColorPalette.offWhite.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}