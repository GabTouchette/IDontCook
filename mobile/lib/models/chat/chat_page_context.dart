/// A lightweight snapshot of what the user is currently looking at, handed to
/// the global chat so it can answer "what's on this page" questions from
/// anywhere in the app. Each page registers one of these via
/// [ChatProvider.setPageContext]; the chat forwards it to the v2 endpoint as
/// `page_context` (see `PromptTemplates.page_context_section` on the backend).
class ChatPageContext {
  /// Human-readable page name, e.g. "Explore", "Meal plan", or a recipe title.
  final String label;

  /// Stable key for the surface (e.g. 'explore', 'recipe_detail'). Used to tell
  /// contexts apart without string-matching the label.
  final String pageKey;

  /// Optional one-line summary of the current state (e.g. active filters).
  final String? summary;

  /// Page-specific structured data — visible recipe ids/titles, filters, the
  /// recipe being viewed, the meal-plan week, etc. Kept small; the backend
  /// length-caps it anyway.
  final Map<String, dynamic>? data;

  const ChatPageContext({
    required this.label,
    required this.pageKey,
    this.summary,
    this.data,
  });

  Map<String, dynamic> toJson() => {
        'label': label,
        if (summary != null) 'summary': summary,
        if (data != null) 'data': data,
      };
}
