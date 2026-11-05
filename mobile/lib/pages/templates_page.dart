import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/widgets/toasts/information_toast.dart';

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
        centerTitle: true,
        title: Text(
          'TEMPLATES',
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            letterSpacing: 2.5,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        leading: IconButton(
          padding: const EdgeInsets.only(left: 16.0),
          icon: Icon(
            Icons.chevron_left,
            color: Theme.of(context).colorScheme.primary,
            size: 32,
          ),
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
              borderRadius: BorderRadius.circular(4),
              side: BorderSide(
                  color:
                      Theme.of(context).colorScheme.outline.withOpacity(0.2)),
            ),
            title: Text(t['name']!,
                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600)),
            subtitle: Text(t['desc']!),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              InformationToast.info(
                context,
                'Applying template: ${t['name']} (coming soon)',
              );
            },
          );
        },
      ),
    );
  }
}
