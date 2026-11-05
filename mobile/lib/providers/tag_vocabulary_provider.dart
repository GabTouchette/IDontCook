import 'package:flutter/foundation.dart';
import 'package:i_cant_cook/api/recipe_api.dart';
import 'package:i_cant_cook/utils/constants.dart';

/// Holds the curated tag vocabulary served by the backend
/// (`GET recipes/tags/vocabulary/`), the single source of truth for selectable
/// tags across the create/edit form and the explore filter.
///
/// Starts from the bundled [tagOptions] so the UI is never empty, then replaces
/// it with the API response on first load. Keep this fetched set authoritative;
/// [tagOptions] is only an offline fallback.
class TagVocabularyProvider extends ChangeNotifier {
  Map<String, List<String>> _vocabulary = tagOptions;
  bool _isLoaded = false;
  bool _isLoading = false;

  Map<String, List<String>> get vocabulary => _vocabulary;
  bool get isLoaded => _isLoaded;

  /// Loads the vocabulary once per session (no-op if already loaded/loading).
  Future<void> ensureLoaded() async {
    if (_isLoaded || _isLoading) return;
    await load();
  }

  /// Forces a reload from the backend. On failure the existing (or fallback)
  /// vocabulary is kept.
  Future<void> load() async {
    _isLoading = true;
    try {
      final data = await RecipeApi().fetchTagVocabulary();
      if (data.isNotEmpty) {
        _vocabulary = data;
        _isLoaded = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('TagVocabularyProvider.load failed: $e');
    } finally {
      _isLoading = false;
    }
  }
}
