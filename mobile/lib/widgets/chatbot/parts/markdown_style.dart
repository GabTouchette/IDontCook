import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

final markdownStyle = MarkdownStyleSheet(
  p: const TextStyle(fontSize: 16),
  strong: const TextStyle(
    fontWeight: FontWeight.bold,
  ),
  em: const TextStyle(
    fontStyle: FontStyle.italic,
  ),
  listBullet: const TextStyle(fontSize: 16),
  h1: const TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.bold,
  ),
  h2: const TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
  ),
  h3: const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  ),
  h4: const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
  ),
  h5: const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
  ),
  h6: const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
  ),
  listIndent: 24,
  unorderedListAlign: WrapAlignment.start,
  orderedListAlign: WrapAlignment.start,
);
