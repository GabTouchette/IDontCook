class RecipeParser {
  static List<String> split(String message) {
    final regex = RegExp(r'\$\$(.*?)\$\$|&&(.*?)&&|@@(.*?)@@', dotAll: true);
    final matches = regex.allMatches(message);

    List<String> parts = [];
    int lastIndex = 0;

    for (final match in matches) {
      if (match.start > lastIndex) {
        parts.add(message.substring(lastIndex, match.start).trim());
      }
      parts.add(match.group(0)!);
      lastIndex = match.end;
    }

    if (lastIndex < message.length) {
      parts.add(message.substring(lastIndex).trim());
    }

    return parts.where((part) => part.isNotEmpty).toList();
  }
}
