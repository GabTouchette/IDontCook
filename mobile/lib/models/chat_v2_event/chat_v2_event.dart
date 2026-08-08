import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:i_cant_cook/models/block/block.dart';

part 'chat_v2_event.freezed.dart';
part 'chat_v2_event.g.dart';

/// One SSE event of the chat v2 protocol — plan §1.6 (LOCKED contract).
///
/// Each event is a `data:` line of JSON:
/// ```json
/// { "type": "message_start", "conversation_id": 123 }
/// { "type": "text_delta", "text": "..." }
/// { "type": "block", "block": <Block> }
/// { "type": "tool_activity", "tool": "search_recipes" }
/// { "type": "error", "message": "..." }
/// { "type": "done" }
/// ```
///
/// Unknown event types parse into [ChatV2Event.unknown] (never throw).
@Freezed(
  unionKey: 'type',
  unionValueCase: FreezedUnionCase.snake,
  fallbackUnion: 'unknown',
)
class ChatV2Event with _$ChatV2Event {
  /// `type: "message_start"` — carries the (possibly newly created)
  /// conversation id.
  const factory ChatV2Event.messageStart({
    int? conversation_id,
  }) = ChatV2MessageStart;

  /// `type: "text_delta"` — a streamed chunk of assistant text.
  const factory ChatV2Event.textDelta({
    @Default('') String text,
  }) = ChatV2TextDelta;

  /// `type: "block"` — a completed tool call became a typed [Block].
  const factory ChatV2Event.block({
    required Block block,
  }) = ChatV2BlockEvent;

  /// `type: "tool_activity"` — a "data tool" (e.g. `search_recipes`) started
  /// running. Purely informational: no [Block] is produced for it and
  /// `text_delta`/`block` events keep streaming after it as normal. Clients
  /// may use [tool] to show an in-progress label ("Searching the
  /// cookbook…") while the round-trip is in flight (plan §1.3).
  const factory ChatV2Event.toolActivity({
    @Default('') String tool,
  }) = ChatV2ToolActivity;

  /// `type: "error"` — a server-side error message.
  const factory ChatV2Event.error({
    @Default('') String message,
  }) = ChatV2Error;

  /// `type: "done"` — the assistant turn is complete.
  const factory ChatV2Event.done() = ChatV2Done;

  /// Fallback for unknown event types — ignored by the client.
  const factory ChatV2Event.unknown() = ChatV2Unknown;

  factory ChatV2Event.fromJson(Map<String, dynamic> json) =>
      _$ChatV2EventFromJson(json);
}
