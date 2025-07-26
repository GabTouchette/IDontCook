import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:i_cant_cook/theme/colors.dart';

final markdownStyle = MarkdownStyleSheet(
  p: const TextStyle(color: ColorPalette.offWhite, fontSize: 16),
  strong: const TextStyle(
      fontWeight: FontWeight.bold, color: ColorPalette.offWhite),
  em: const TextStyle(
      fontStyle: FontStyle.italic, color: ColorPalette.offWhite),
  listBullet: const TextStyle(color: ColorPalette.offWhite, fontSize: 16),
  h1: const TextStyle(
      fontSize: 26, fontWeight: FontWeight.bold, color: ColorPalette.offWhite),
  h2: const TextStyle(
      fontSize: 22, fontWeight: FontWeight.bold, color: ColorPalette.offWhite),
  h3: const TextStyle(
      fontSize: 18, fontWeight: FontWeight.bold, color: ColorPalette.offWhite),
  h4: const TextStyle(
      fontSize: 16, fontWeight: FontWeight.bold, color: ColorPalette.offWhite),
  h5: const TextStyle(
      fontSize: 14, fontWeight: FontWeight.bold, color: ColorPalette.offWhite),
  h6: const TextStyle(
      fontSize: 12, fontWeight: FontWeight.bold, color: ColorPalette.offWhite),
  listIndent: 24,
  unorderedListAlign: WrapAlignment.start,
  orderedListAlign: WrapAlignment.start,
);
