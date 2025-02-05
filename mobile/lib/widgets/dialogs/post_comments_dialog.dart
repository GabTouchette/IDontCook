import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mobile/api/social_api.dart';
import 'package:mobile/models/comment.dart';
import 'package:mobile/models/post.dart';
import 'package:mobile/pages/user_profile_page.dart';
import 'package:mobile/theme/avatars.dart';
import 'package:mobile/theme/colors.dart';

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
            decoration: const BoxDecoration(
              color: ColorPalette.darkgray,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                          return const Center(
                              child: Text("No comments yet.",
                                  style:
                                      TextStyle(color: ColorPalette.offWhite)));
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
                                  leading: CircleAvatar(
                                    backgroundColor: ColorPalette.lightgray,
                                    child: Avatars.getAvatarIcon(
                                        comment.user.avatar_icon),
                                  ),
                                  title: Text(
                                    "@${comment.user.username}",
                                    style: const TextStyle(
                                        color: ColorPalette.offWhite),
                                  ),
                                  subtitle: Text(
                                    comment.content,
                                    style:
                                        const TextStyle(color: Colors.white70),
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
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: ColorPalette.lightgray,
            child: FaIcon(
              FontAwesomeIcons.solidLemon,
              color: ColorPalette.mustard,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "@${widget.post.user.username}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w300,
                  color: ColorPalette.offWhite,
                ),
              ),
              const Text(
                "shared a recipe",
                style: TextStyle(color: ColorPalette.placeholdergray),
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
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          color: ColorPalette.lightgray,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                style: const TextStyle(color: ColorPalette.offBlack),
                decoration: InputDecoration(
                  hintText: "Add a comment...",
                  hintStyle:
                      const TextStyle(color: ColorPalette.placeholdergray),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 16.0, horizontal: 16.0),
                ),
                onSubmitted: (_) => _addComment(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: ColorPalette.mustard),
              onPressed: _addComment,
            ),
          ],
        ),
      ),
    );
  }
}
