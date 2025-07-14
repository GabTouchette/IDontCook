import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:i_cant_cook/mixins/chatbot_mixin.dart';
import 'package:i_cant_cook/models/recipe/recipe.dart';
import 'package:i_cant_cook/providers/chat_provider.dart';
import 'package:i_cant_cook/theme/colors.dart';
import 'package:i_cant_cook/widgets/chatbot/ai_response_bubble.dart';
import 'package:i_cant_cook/widgets/chatbot/chat_message.dart';

class RecipeChatModal extends StatefulWidget {
  final Recipe recipe;

  const RecipeChatModal({Key? key, required this.recipe}) : super(key: key);

  @override
  State<RecipeChatModal> createState() => _RecipeChatModalState();
}

class _RecipeChatModalState extends State<RecipeChatModal> with ChatBotMixin {
  bool _starterMessageSent = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<ChatProvider>();
    provider.setCurrentRecipe(widget.recipe.id);

    if (!_starterMessageSent) {
      _starterMessageSent = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (provider.recipeMessages.isEmpty) {
          provider.addMessage(
            sender: "ai",
            text: "Ask me something about your ${widget.recipe.title} recipe!",
            isRecipeChat: true,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.6,
      builder: (context, scrollControllerSheet) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: ColorPalette.darkergray,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Consumer<ChatProvider>(
              builder: (context, provider, _) => Column(
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 12, left: 16, right: 16),
                    child: SizedBox(
                      height: 40,
                      child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.center,
                            child: Container(
                              width: 40,
                              height: 5,
                              decoration: BoxDecoration(
                                color: Colors.grey[600],
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              icon: const Icon(Icons.close,
                                  color: ColorPalette.offWhite),
                              onPressed: () => Navigator.pop(context),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: provider.recipeMessages.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, index) {
                        final msg = provider.recipeMessages[index];
                        final isUser = msg['sender'] == 'user';
                        return Align(
                          alignment: isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: msg['sender'] == 'ai'
                                ? AiResponseBubble(
                                    message: msg['text'],
                                    isLoading: msg['isLoading'] == true,
                                    isRecipeLoading:
                                        msg['isRecipeLoading'] == true,
                                    originalRecipe: widget.recipe,
                                  )
                                : MessageWidget(
                                    messageText: msg['text'] ?? '',
                                    isUser: isUser,
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: ColorPalette.darkgray,
                          borderRadius: BorderRadius.circular(30),
                          border:
                              Border.all(color: ColorPalette.placeholdergray),
                        ),
                        child: TextField(
                          controller: chatController,
                          style: const TextStyle(color: ColorPalette.offWhite),
                          onSubmitted: (query) => sendMessageWithContext(
                              query, provider,
                              recipeId: widget.recipe.id, isRecipeChat: true),
                          decoration: const InputDecoration(
                            icon: Icon(Icons.search,
                                color: ColorPalette.placeholdergray),
                            hintText: 'Ask something about this recipe...',
                            hintStyle:
                                TextStyle(color: ColorPalette.placeholdergray),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
