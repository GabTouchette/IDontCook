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
  final _dietCtrl = TextEditingController();
  final _cuisineCtrl = TextEditingController();
  final _specialCtrl = TextEditingController();
  int _maxPrep = 45;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final mp = context.watch<MealPlanProvider>();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: Text('Generate Meal Plan', style: GoogleFonts.nunito(fontWeight: FontWeight.w900)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Dietary restrictions (comma-separated)', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              TextFormField(controller: _dietCtrl),
              const SizedBox(height: 16),
              Text('Cuisine preferences (comma-separated)', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              TextFormField(controller: _cuisineCtrl),
              const SizedBox(height: 16),
              Text('Max prep time (minutes)', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
              Slider(
                value: _maxPrep.toDouble(),
                min: 10,
                max: 120,
                divisions: 11,
                label: '$_maxPrep',
                onChanged: (v) => setState(() => _maxPrep = v.toInt()),
              ),
              const SizedBox(height: 16),
              Text('Special requests (optional)', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              TextFormField(controller: _specialCtrl),
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
                            dietaryRestrictions: _dietCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                            cuisines: _cuisineCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                            maxPrepTime: _maxPrep,
                            specialRequests: _specialCtrl.text,
                          );
                          // ignore: use_build_context_synchronously
                          Navigator.pop(context);
                        },
                  child: _loading
                      ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.onPrimary))
                      : Text('Generate', style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
