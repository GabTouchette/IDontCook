
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
    final lime = Theme.of(context).colorScheme.secondary;
    final onLime = Theme.of(context).colorScheme.onSecondary;

    for (int i = 0; i < widget.instructions.length; i++) {
      inputFields.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Lime step badge
              Container(
                width: 32,
                height: 32,
                color: lime,
                alignment: Alignment.center,
                child: Text(
                  '${i + 1}',
                  style: GoogleFonts.spaceGrotesk(
                    color: onLime,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: widget.instructions[i].controller,
                  focusNode: widget.instructions[i].focusNode,
                  maxLines: 3,
                  minLines: 2,
                  style: GoogleFonts.spaceGrotesk(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                  ),
                  onChanged: (text) {
                    if (i == widget.instructions.length - 1 &&
                        text.isNotEmpty) {
                      setState(() {
                        widget.instructions.add(InstructionField(
                            controller: TextEditingController(),
                            focusNode: FocusNode()));
                      });
                      widget.onInstructionsChanged(widget.instructions);
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Step ${i + 1}...',
                    hintStyle: GoogleFonts.spaceGrotesk(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.3),
                      fontSize: 14,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(
                        color: lime,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Delete button — only visible when step has content
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: widget.instructions[i].controller,
                builder: (context, value, _) {
                  if (value.text.isEmpty) return const SizedBox(width: 40);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        widget.instructions.removeAt(i);
                      });
                      widget.onInstructionsChanged(widget.instructions);
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .error
                              .withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.close,
                        size: 14,
                        color: Theme.of(context)
                            .colorScheme
                            .error
                            .withValues(alpha: 0.7),
                      ),
                    ),
                  );
                },
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
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'INSTRUCTIONS',
            style: GoogleFonts.spaceGrotesk(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Container(
              width: 28,
              height: 2,
              color: Theme.of(context).colorScheme.secondary),
          const SizedBox(height: 12),
          ..._buildInstructionsInputFields(),
        ],
      ),
    );
  }
}