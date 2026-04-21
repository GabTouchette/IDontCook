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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
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
                                color: Theme.of(context).colorScheme.outline,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              icon: Icon(Icons.close,
                                  color: Theme.of(context).colorScheme.onSurface),
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
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: provider.chatController,
                          style: GoogleFonts.nunito(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          onSubmitted: (query) => provider.sendMessage(
                              query: query,
                              recipeId: widget.recipe.id,
                              isRecipeChat: true),
                          decoration: InputDecoration(
                            icon: Icon(Icons.search,
                                color: Theme.of(context).colorScheme.primary),
                            hintText: 'Ask something about this recipe...',
                            hintStyle: GoogleFonts.nunito(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
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
