import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/models/recipe/recipe.dart';
import 'package:i_cant_cook/providers/chat_provider.dart';
import 'package:i_cant_cook/widgets/chatbot/ai_response_bubble.dart';
import 'package:i_cant_cook/widgets/chatbot/chat_message.dart';
import 'package:provider/provider.dart';

class RecipeChatDialog extends StatefulWidget {
  final Recipe recipe;

  /// Optional question to auto-send as soon as the chat opens — used by the
  /// ingredient long-press actions ("What is this?" / "Suggest replacements")
  /// so the chat opens with the question already asked.
  final String? initialQuery;

  const RecipeChatDialog({Key? key, required this.recipe, this.initialQuery})
      : super(key: key);

  @override
  State<RecipeChatDialog> createState() => _RecipeChatDialogState();
}

class _RecipeChatDialogState extends State<RecipeChatDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<ChatProvider>();
      provider.setCurrentRecipe(widget.recipe.id);
      if (provider.currentMessages.isEmpty) {
        provider.addMessage(
          sender: "ai",
          text: "Ask me something about your ${widget.recipe.title} recipe!",
          isRecipeChat: true,
        );
      }

      // Auto-send a pre-built question (e.g. from an ingredient long-press)
      // so the chat opens with the question already asked and answered.
      final initialQuery = widget.initialQuery?.trim();
      if (initialQuery != null && initialQuery.isNotEmpty) {
        provider.sendMessage(
          query: initialQuery,
          recipeId: widget.recipe.id,
          isRecipeChat: true,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SizedBox(
          height: screenHeight * 0.65,
          child: Consumer<ChatProvider>(
            builder: (context, provider, _) => Column(
              children: [
                // Handle bar + close button
                Padding(
                  padding: const EdgeInsets.only(top: 12, left: 16, right: 16),
                  child: SizedBox(
                    height: 40,
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: Container(
                            width: 36,
                            height: 2,
                            color: cs.outline.withOpacity(0.3),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: Icon(Icons.refresh, color: cs.onSurface, size: 20),
                            tooltip: 'Clear chat',
                            onPressed: () {
                              provider.clearRecipeChat();
                              provider.addMessage(
                                sender: 'ai',
                                text: 'Ask me something about your ${widget.recipe.title} recipe!',
                                isRecipeChat: true,
                              );
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon:
                                Icon(Icons.close, color: cs.onSurface, size: 20),
                            onPressed: () => Navigator.pop(context),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Messages
                Expanded(
                  child: ListView.builder(
                    controller: provider.scrollController,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: provider.currentMessages.length,
                    itemBuilder: (context, index) {
                      final msg = provider.currentMessages[index];
                      final isUser = msg['sender'] == 'user';
                      return Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Align(
                          alignment: isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 4.0),
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
                        ),
                      );
                    },
                  ),
                ),
                // Input — matches chatbot page style
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cs.surface,
                      border: Border.all(
                        color: cs.outline.withOpacity(0.25),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: provider.chatController,
                            style: GoogleFonts.spaceGrotesk(
                              color: cs.onSurface,
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                            ),
                            onSubmitted: (query) {
                              FocusScope.of(context).unfocus();
                              provider.sendMessage(
                                query: query,
                                recipeId: widget.recipe.id,
                                isRecipeChat: true,
                              );
                            },
                            decoration: InputDecoration(
                              hintText: 'Ask something about this recipe...',
                              hintStyle: GoogleFonts.spaceGrotesk(
                                color: cs.onSurface.withOpacity(0.35),
                                fontSize: 15,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 14.0,
                                horizontal: 16.0,
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            final query =
                                provider.chatController.text.trim();
                            if (query.isNotEmpty) {
                              FocusScope.of(context).unfocus();
                              provider.sendMessage(
                                query: query,
                                recipeId: widget.recipe.id,
                                isRecipeChat: true,
                              );
                            }
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            color: cs.onSurface,
                            child: Icon(
                              Icons.arrow_forward,
                              color: cs.surface,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
