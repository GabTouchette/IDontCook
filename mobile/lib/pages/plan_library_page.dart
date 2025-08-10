import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:i_cant_cook/providers/meal_plan_provider.dart';

class PlanLibraryPage extends StatelessWidget {
  const PlanLibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: Text('Plan Library',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w900, fontSize: 24)),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: context.read<MealPlanProvider>().listPlans(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final plans = snapshot.data ?? [];
          if (plans.isEmpty) {
            return Center(
              child: Text('No saved plans yet', style: GoogleFonts.nunito()),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: plans.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final p = plans[i];
              final name = (p['name'] as String?) ?? 'Meal Plan';
              final ws = (p['week_start_date'] as String?) ?? '';
              final count = ((p['planned_meals'] as List?)?.length ?? 0).toString();
              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
                ),
                title: Text(name, style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
                subtitle: Text('Week of $ws • $count meals'),
                trailing: TextButton(
                  onPressed: () async {
                    await context.read<MealPlanProvider>().loadPlanById(p['id'] as int);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Load'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
