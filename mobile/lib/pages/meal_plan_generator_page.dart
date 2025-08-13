import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:i_cant_cook/providers/meal_plan_provider.dart';

class MealPlanGeneratorPage extends StatefulWidget {
  const MealPlanGeneratorPage({super.key});

  @override
  State<MealPlanGeneratorPage> createState() => _MealPlanGeneratorPageState();
}

class _MealPlanGeneratorPageState extends State<MealPlanGeneratorPage> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  bool _loading = false;
  bool _focusSaved = true;

  String _dayLabel(DateTime weekStart, int dayIndex) {
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final idx = dayIndex.clamp(0, 6);
    final date = weekStart.add(Duration(days: idx));
    final md = '${months[date.month - 1]} ${date.day}';
    return '${names[idx]} • $md';
  }

  String _dayLabelPlain(DateTime weekStart, int dayIndex) {
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final idx = dayIndex.clamp(0, 6);
    final date = weekStart.add(Duration(days: idx));
    final md = '${months[date.month - 1]} ${date.day}';
    return '${names[idx]} $md';
  }

  @override
  Widget build(BuildContext context) {
    final mp = context.watch<MealPlanProvider>();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: Text('Generate Meal Plan',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w900)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selected days reminder
              Builder(builder: (context) {
                final selected = [...mp.selectedDaysList]..sort();
                if (selected.isEmpty) return const SizedBox.shrink();
                final ws = mp.visibleWeekStart;
                return Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('You\'re planning for:',
                            style: GoogleFonts.nunito(
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        Text(
                          selected.length == 1
                              ? _dayLabelPlain(ws, selected.first)
                              : '${_dayLabelPlain(ws, selected.first)} - ${_dayLabelPlain(ws, selected.last)}',
                          style:
                              GoogleFonts.nunito(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 12),
              Text(
                'Describe what you want from a meal plan',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descCtrl,
                minLines: 5,
                maxLines: 10,
                decoration: const InputDecoration(
                  hintText:
                      'e.g., Family-friendly dinners for 4, low-carb lunches, 30-min meals, include leftovers for next day…',
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              FilterChip(
                label: const Text('Focus on my saved recipes'),
                selected: _focusSaved,
                onSelected: (v) => setState(() => _focusSaved = v),
              ),
              const SizedBox(height: 6),
              Text(
                'We\'ll prioritize your saved recipes when possible.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading
                      ? null
                      : () async {
                          setState(() => _loading = true);
                          await mp.generateAIMealPlan(
                            context,
                            specialRequests: _descCtrl.text.trim(),
                            focusOnSaved: _focusSaved,
                          );
                          // ignore: use_build_context_synchronously
                          Navigator.pop(context);
                        },
                  child: _loading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.onPrimary))
                      : Text('Generate',
                          style:
                              GoogleFonts.nunito(fontWeight: FontWeight.w800)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
