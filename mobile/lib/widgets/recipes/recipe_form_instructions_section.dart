
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/models/recipe_form_fields/recipe_form_fields.dart';

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
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Number badge - smaller and lighter (positioned at top)
              Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    "${i + 1}",
                    style: GoogleFonts.nunito(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10.0),
              // Text field - expanded to take more space
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.15),
                    ),
                  ),
                  child: TextField(
                    controller: widget.instructions[i].controller,
                    focusNode: widget.instructions[i].focusNode,
                    maxLines: 3,
                    minLines: 2,
                    style: GoogleFonts.nunito(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
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
                      hintText: 'Step ${i + 1}: Describe what to do...',
                      hintStyle: GoogleFonts.nunito(
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                        fontSize: 15,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6.0),
              // Delete button - smaller and more subtle (positioned at top)
              Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.error.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  iconSize: 16,
                  icon: Icon(
                    Icons.close,
                    color: Theme.of(context).colorScheme.error.withOpacity(0.8),
                  ),
                  onPressed: widget.instructions.length > 1
                      ? () {
                          setState(() {
                            widget.instructions.removeAt(i);
                          });
                          widget.onInstructionsChanged(widget.instructions);
                        }
                      : null,
                ),
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
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Container(
        padding: const EdgeInsets.all(18.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.format_list_numbered,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  "Instructions",
                  style: GoogleFonts.nunito(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14.0),
            ..._buildInstructionsInputFields(),
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text(
                "Write clear, step-by-step instructions for your recipe",
                style: GoogleFonts.nunito(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}