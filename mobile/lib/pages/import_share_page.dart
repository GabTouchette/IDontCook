import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/api/ai_chatbot_api.dart';
import 'package:i_cant_cook/pages/create_recipe_page.dart';
import 'package:i_cant_cook/widgets/toasts/information_toast.dart';

/// Landing screen for a recipe link shared into the app from the OS share sheet
/// (e.g. an Instagram reel/post). Fetches + extracts the recipe on the backend,
/// then hands the draft to [CreateRecipePage] for the user to review and save.
///
/// On failure (private post, login wall, no recipe in the caption) it shows a
/// clear message and returns the user to where they were — never a blank form.
class ImportSharePage extends StatefulWidget {
  final String url;

  const ImportSharePage({super.key, required this.url});

  @override
  State<ImportSharePage> createState() => _ImportSharePageState();
}

class _ImportSharePageState extends State<ImportSharePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _import());
  }

  Future<void> _import() async {
    try {
      final result = await AiChatbotApi().importRecipeFromUrl(widget.url);
      // Backend returns null on any non-2xx (private/login-walled/unreachable).
      if (result == null) {
        _fail("Couldn't read that post — it may be private, or Instagram "
            "blocked the request. Try a public reel or post.");
        return;
      }
      if (result['error'] != null) {
        _fail(result['error'].toString());
        return;
      }

      final recipe = _parseRecipe(result['response'] as String?);
      if (recipe == null) {
        _fail('No recipe found in that post.');
        return;
      }

      if (!mounted) return;
      // Replace this screen with the prefilled create form so back doesn't
      // return to the transient loading screen.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => CreateRecipePage(prefillData: recipe),
        ),
      );
    } catch (e) {
      _fail('Import failed: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  /// The URL/OCR import path wraps the recipe JSON in `$$ ... $$`; unwrap it and
  /// decode. Returns null for `$$ null $$`, empty, or unparseable payloads.
  Map<String, dynamic>? _parseRecipe(String? response) {
    if (response == null) return null;
    var body = response.trim();

    final match = RegExp(r'\$\$\s*(.*?)\s*\$\$', dotAll: true).firstMatch(body);
    if (match != null) body = match.group(1)!.trim();

    if (body.isEmpty || body.toLowerCase() == 'null') return null;

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {
      // fall through
    }
    return null;
  }

  void _fail(String message) {
    if (!mounted) return;
    InformationToast.error(context, message);
    // Return to wherever the user was; fall back to the recipes tab if this
    // screen has nothing beneath it (e.g. a cold-start share).
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      nav.pushReplacementNamed('/recipes');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 24),
            Text(
              'Reading the recipe…',
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                'Pulling the ingredients and steps from the shared post.',
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
