import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/api/social_api.dart';
import 'package:i_cant_cook/models/comment/comment.dart';
import 'package:i_cant_cook/models/post/post.dart';
import 'package:i_cant_cook/pages/user_profile_page.dart';
import 'package:i_cant_cook/theme/avatars.dart';

class CommentDrawer extends StatefulWidget {
  final Post post;
  final Function? onCommentAdded;

  const CommentDrawer(
      {Key? key, required this.post, required this.onCommentAdded})
      : super(key: key);

  @override
  _CommentDrawerState createState() => _CommentDrawerState();
}

class _CommentDrawerState extends State<CommentDrawer> {
  late Future<List<Comment>> _comments;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _comments = SocialApi().fetchComments(widget.post.id);
  }

  void _addComment() async {
    if (_commentController.text.isNotEmpty) {
      var commentData = {
        "user": widget.post.user.id,
        "content": _commentController.text,
      };

      await SocialApi().createComment(commentData, widget.post.id);
      setState(() {
        _comments = SocialApi().fetchComments(widget.post.id);
      });
      _commentController.clear();
      widget.onCommentAdded?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.transparent,
      body: DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.zero,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 16.0),
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: FutureBuilder<List<Comment>>(
                      future: _comments,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(child: Text(snapshot.error.toString()));
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return Center(
                              child: Text(
                                'No comments yet.',
                                style: GoogleFonts.spaceGrotesk(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                                  fontSize: 14,
                                ),
                              ));
                        }
                        return ListView.builder(
                          controller: scrollController,
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            final comment = snapshot.data![index];
                            return Padding(
                              padding: const EdgeInsets.only(left: 16.0),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          UserProfilePage(user: comment.user),
                                    ),
                                  );
                                },
                                child: ListTile(
                                  leading: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Theme.of(context).colorScheme.outline.withOpacity(0.35),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Center(
                                      child: Avatars.getAvatarIcon(
                                          comment.user.avatar_icon),
                                    ),
                                  ),
                                  title: Text(
                                    "@${comment.user.username}",
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                  subtitle: Text(
                                    comment.content,
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                      height: 1.4,
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  _buildCommentInput(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.35),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.chat_bubble_outline,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "@${widget.post.user.username}",
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                'COMMENTS',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.2,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.25),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                style: GoogleFonts.spaceGrotesk(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                decoration: InputDecoration(
                  hintText: 'Add a comment...',
                  hintStyle: GoogleFonts.spaceGrotesk(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.35),
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 14.0, horizontal: 14.0),
                ),
                onSubmitted: (_) => _addComment(),
              ),
            ),
            GestureDetector(
              onTap: _addComment,
              child: Container(
                width: 48,
                height: 48,
                color: const Color(0xFFCAFF00),
                child: const Icon(
                  Icons.send,
                  color: Color(0xFF0A0A0A),
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
