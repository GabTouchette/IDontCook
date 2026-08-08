import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:i_cant_cook/models/block/block.dart';
import 'package:i_cant_cook/models/mood/mood.dart';

part 'home_feed.freezed.dart';
part 'home_feed.g.dart';

/// `context` object of the home-feed response — plan §1.5 (LOCKED contract).
///
/// `{ "daypart": "evening", "is_weekend": false, "mood": "rushed" }`
///
/// [mood] keeps the raw wire string (null when unset); [moodValue] resolves
/// it to a [Mood], returning null for unknown values (forward-compat).
@freezed
class HomeFeedContext with _$HomeFeedContext {
  const HomeFeedContext._();

  const factory HomeFeedContext({
    @Default('') String daypart,
    @Default(false) bool is_weekend,
    String? mood,
  }) = _HomeFeedContext;

  factory HomeFeedContext.fromJson(Map<String, dynamic> json) =>
      _$HomeFeedContextFromJson(json);

  Mood? get moodValue => Mood.fromWire(mood);
}

/// Response of `GET /api/home/feed/` — plan §1.5 (LOCKED contract).
///
/// ```json
/// {
///   "feed_id": "uuid",
///   "context": { "daypart": "evening", "is_weekend": false, "mood": "rushed" },
///   "greeting": "string",
///   "blocks": [ Block, ... ]
/// }
/// ```
///
/// `blocks[0]` is a `text` block with the greeting/framing line, followed by
/// 3–6 ranked `module` blocks. Unknown block/module types parse into their
/// `unknown` variants (never throw); use [renderableBlocks] to skip them.
@freezed
class HomeFeed with _$HomeFeed {
  const HomeFeed._();

  const factory HomeFeed({
    @Default('') String feed_id,
    @Default(HomeFeedContext()) HomeFeedContext context,
    @Default('') String greeting,
    @Default(<Block>[]) List<Block> blocks,
  }) = _HomeFeed;

  factory HomeFeed.fromJson(Map<String, dynamic> json) =>
      _$HomeFeedFromJson(json);

  /// Blocks minus unknown block types and modules with unknown module types
  /// (plan §1.2 forward-compat rule: silently skipped).
  List<Block> get renderableBlocks => blocks
      .where((block) => block.maybeMap(
            unknown: (_) => false,
            module: (moduleBlock) => moduleBlock.module.isKnownType,
            orElse: () => true,
          ))
      .toList();
}
