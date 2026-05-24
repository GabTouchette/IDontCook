import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/models/recipe/recipe.dart';
import 'package:i_cant_cook/providers/chat_provider.dart';
import 'package:i_cant_cook/widgets/chatbot/ai_response_bubble.dart';
import 'package:i_cant_cook/widgets/chatbot/chat_message.dart';
import 'package:provider/provider.dart';

class RecipeChatDialog extends StatefulWidget {
  final Recipe recipe;

  const RecipeChatDialog({Key? key, required this.recipe}) : super(key: key);

  @override
  State<RecipeChatDialog> createState() => _RecipeChatDialogState();
}

class _RecipeChatDialogState extends State<RecipeChatDialog> {
  bool _starterMessageSent = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<ChatProvider>();
    provider.setCurrentRecipe(widget.recipe.id);

    if (!_starterMessageSent) {
      _starterMessageSent = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (provider.currentMessages.isEmpty) {
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
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.zero,
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
                              width: 36,
                              height: 2,
                              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              icon: Icon(Icons.close,
                                  color: Theme.of(context).colorScheme.onSurface,
                                  size: 20),
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
                      controller: provider.scrollController,
                      itemCount: provider.currentMessages.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, index) {
                        final msg = provider.currentMessages[index];
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
                          color: Theme.of(context).colorScheme.surface,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.25),
                            width: 1.5,
                          ),
                        ),
                        child: TextField(
                          controller: provider.chatController,
                          style: GoogleFonts.spaceGrotesk(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                          onSubmitted: (query) => provider.sendMessage(
                              query: query,
                              recipeId: widget.recipe.id,
                              isRecipeChat: true),
                          decoration: InputDecoration(
                            icon: Icon(Icons.chat_bubble_outline,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                                size: 18),
                            hintText: 'Ask something about this recipe...',
                            hintStyle: GoogleFonts.spaceGrotesk(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.35),
                              fontSize: 15,
                            ),
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
