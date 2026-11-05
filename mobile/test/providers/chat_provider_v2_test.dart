import 'package:flutter_test/flutter_test.dart';
import 'package:i_cant_cook/api/ai_chatbot_api.dart';
import 'package:i_cant_cook/models/block/block.dart';
import 'package:i_cant_cook/models/chat/chat_page_context.dart';
import 'package:i_cant_cook/models/chat_v2_event/chat_v2_event.dart';
import 'package:i_cant_cook/models/mood/mood.dart';
import 'package:i_cant_cook/models/recipe_summary/recipe_summary.dart';
import 'package:i_cant_cook/providers/chat_provider.dart';

/// Fake API that replays a scripted v2 SSE event sequence and records the
/// request parameters the provider sent.
class FakeAiChatbotApi extends AiChatbotApi {
  FakeAiChatbotApi(this.events);

  final List<ChatV2Event> events;

  String? lastMessage;
  int? lastConversationId;
  String? lastContext;
  int? lastRecipeId;
  Mood? lastMood;
  Map<String, dynamic>? lastHomeFeed;

  @override
  Stream<ChatV2Event> chatWithBotStreamV2({
    required String message,
    int? conversationId,
    String context = 'global',
    int? recipeId,
    Mood? mood,
    Map<String, dynamic>? homeFeed,
    ChatPageContext? pageContext,
  }) {
    lastMessage = message;
    lastConversationId = conversationId;
    lastContext = context;
    lastRecipeId = recipeId;
    lastMood = mood;
    lastHomeFeed = homeFeed;
    return Stream.fromIterable(events);
  }
}

const _padThai = RecipeSummary(
  id: 12,
  title: 'Pad Thai',
  total_time: 25,
  calories: 540,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChatProvider v2 send path (§1.6)', () {
    test('typed event sequence builds the expected message/block state',
        () async {
      final api = FakeAiChatbotApi(const [
        ChatV2Event.messageStart(conversation_id: 42),
        ChatV2Event.textDelta(text: 'Here '),
        ChatV2Event.textDelta(text: 'you go.'),
        ChatV2Event.block(block: Block.recipeRef(recipe: _padThai)),
        ChatV2Event.textDelta(text: 'Enjoy!'),
        ChatV2Event.done(),
      ]);
      final provider = ChatProvider(api: api);

      await provider.sendMessageV2(
        message: '  quick thai dinner  ',
        chatContext: 'home',
        mood: Mood.rushed,
        homeFeed: {'feed_id': 'abc'},
      );

      // Request wiring.
      expect(api.lastMessage, 'quick thai dinner');
      expect(api.lastConversationId, isNull,
          reason: 'first turn has no conversation yet');
      expect(api.lastContext, 'home');
      expect(api.lastMood, Mood.rushed);
      expect(api.lastHomeFeed, {'feed_id': 'abc'});

      // Conversation id carried from message_start.
      expect(provider.v2ConversationId, 42);
      expect(provider.isV2Sending, isFalse);

      // Message state: user message + assistant message of ordered blocks.
      expect(provider.v2Messages.length, 2);

      final userMessage = provider.v2Messages[0];
      expect(userMessage.isUser, isTrue);
      expect(userMessage.blocks.length, 1);
      expect((userMessage.blocks.single as TextBlock).text,
          'quick thai dinner');

      final aiMessage = provider.v2Messages[1];
      expect(aiMessage.isUser, isFalse);
      expect(aiMessage.isLoading, isFalse);
      expect(aiMessage.blocks.length, 3,
          reason: 'text — block — text, in stream order');
      expect((aiMessage.blocks[0] as TextBlock).text, 'Here you go.',
          reason: 'consecutive text_deltas coalesce into one text block');
      expect(aiMessage.blocks[1], isA<RecipeRefBlock>());
      expect((aiMessage.blocks[2] as TextBlock).text, 'Enjoy!',
          reason: 'a block event splits the streamed text');
    });

    test('second turn sends the stored conversation_id', () async {
      final api = FakeAiChatbotApi(const [
        ChatV2Event.messageStart(conversation_id: 7),
        ChatV2Event.textDelta(text: 'Hi!'),
        ChatV2Event.done(),
      ]);
      final provider = ChatProvider(api: api);

      await provider.sendMessageV2(message: 'hello');
      expect(api.lastConversationId, isNull);

      await provider.sendMessageV2(message: 'again');
      expect(api.lastConversationId, 7);
      expect(provider.v2Messages.length, 4);
    });

    test('error event surfaces via onError and is shown in the thread',
        () async {
      final api = FakeAiChatbotApi(const [
        ChatV2Event.messageStart(conversation_id: 1),
        ChatV2Event.error(message: 'The model is unavailable.'),
        ChatV2Event.done(),
      ]);
      final provider = ChatProvider(api: api);

      final toasts = <String>[];
      await provider.sendMessageV2(
        message: 'hello?',
        onError: toasts.add,
      );

      expect(toasts, ['The model is unavailable.']);
      expect(provider.v2LastError, 'The model is unavailable.');
      final aiMessage = provider.v2Messages.last;
      expect(aiMessage.isLoading, isFalse);
      expect(aiMessage.plainText, contains('The model is unavailable.'));
    });

    test('stream exception is caught and surfaced, sending flag cleared',
        () async {
      final api = _ThrowingApi();
      final provider = ChatProvider(api: api);

      final toasts = <String>[];
      await provider.sendMessageV2(message: 'hi', onError: toasts.add);

      expect(provider.isV2Sending, isFalse);
      expect(toasts, hasLength(1));
      expect(provider.v2Messages.last.isLoading, isFalse);
    });

    test('empty message is ignored', () async {
      final provider = ChatProvider(api: FakeAiChatbotApi(const []));
      await provider.sendMessageV2(message: '   ');
      expect(provider.v2Messages, isEmpty);
    });

    test('resetV2Conversation clears thread and conversation id', () async {
      final api = FakeAiChatbotApi(const [
        ChatV2Event.messageStart(conversation_id: 9),
        ChatV2Event.textDelta(text: 'yo'),
        ChatV2Event.done(),
      ]);
      final provider = ChatProvider(api: api);
      await provider.sendMessageV2(message: 'hey');
      expect(provider.v2ConversationId, 9);

      provider.resetV2Conversation();
      expect(provider.v2Messages, isEmpty);
      expect(provider.v2ConversationId, isNull);
    });

    test(
        'tool_activity sets v2ActivityLabel while active; done clears it (plan §1.3)',
        () async {
      final api = FakeAiChatbotApi(const [
        ChatV2Event.messageStart(conversation_id: 5),
        ChatV2Event.toolActivity(tool: 'search_recipes'),
        ChatV2Event.block(block: Block.recipeRef(recipe: _padThai)),
        ChatV2Event.done(),
      ]);
      final provider = ChatProvider(api: api);

      final labelsDuringStream = <String?>[];
      provider.addListener(() {
        labelsDuringStream.add(provider.v2ActivityLabel);
      });

      await provider.sendMessageV2(message: 'find me something spicy');

      expect(labelsDuringStream, contains('Searching the cookbook…'));
      expect(provider.v2ActivityLabel, isNull,
          reason: 'a completed block, then done, clears the activity label');
    });

    test('tool_activity with an unrecognized tool falls back to a generic label',
        () async {
      final api = FakeAiChatbotApi(const [
        ChatV2Event.messageStart(conversation_id: 6),
        ChatV2Event.toolActivity(tool: 'some_future_tool'),
      ]);
      final provider = ChatProvider(api: api);

      String? seenLabel;
      provider.addListener(() {
        seenLabel ??= provider.v2ActivityLabel;
      });

      await provider.sendMessageV2(message: 'anything');

      expect(seenLabel, 'Working on it…');
    });

    test('error event clears v2ActivityLabel', () async {
      final api = FakeAiChatbotApi(const [
        ChatV2Event.messageStart(conversation_id: 8),
        ChatV2Event.toolActivity(tool: 'search_recipes'),
        ChatV2Event.error(message: 'boom'),
        ChatV2Event.done(),
      ]);
      final provider = ChatProvider(api: api);

      await provider.sendMessageV2(message: 'hi', onError: (_) {});

      expect(provider.v2ActivityLabel, isNull);
    });

    test('addV2AssistantMessage seeds the thread (home feed opening message)',
        () {
      final provider = ChatProvider(api: FakeAiChatbotApi(const []));
      provider.addV2AssistantMessage(const [
        Block.text(text: 'Good evening!'),
        Block.recipeRef(recipe: _padThai),
      ]);
      expect(provider.v2Messages.length, 1);
      expect(provider.v2Messages.single.isUser, isFalse);
      expect(provider.v2Messages.single.blocks.length, 2);
    });
  });
}

class _ThrowingApi extends AiChatbotApi {
  @override
  Stream<ChatV2Event> chatWithBotStreamV2({
    required String message,
    int? conversationId,
    String context = 'global',
    int? recipeId,
    Mood? mood,
    Map<String, dynamic>? homeFeed,
    ChatPageContext? pageContext,
  }) {
    return Stream.error(Exception('connection refused'));
  }
}
