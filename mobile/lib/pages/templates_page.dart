import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TemplatesPage extends StatelessWidget {
  const TemplatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final templates = const [
      {'name': 'Quick Week', 'desc': '30-min meals for busy days'},
      {'name': 'Vegetarian', 'desc': 'Plant-forward meals'},
      {'name': 'Family', 'desc': 'Kid-friendly classics'},
    ];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: Text('Templates',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w900, fontSize: 24)),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: templates.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final t = templates[i];
          return ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
            ),
            title: Text(t['name']!, style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
            subtitle: Text(t['desc']!),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Applying template: ${t['name']} (coming soon)')),
              );
            },
          );
        },
      ),
    );
  }
}
