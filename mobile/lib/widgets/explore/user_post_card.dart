import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mobile/pages/recipe_detail_page.dart';
import 'package:mobile/theme/colors.dart';

class UserPostCard extends StatefulWidget {
  final String userName;
  final int voteCount;
  final String? content;
  final int? recipeId;
  final String? recipeTitle;
  final String? recipeDescription;
  final String? recipeImageUrl;

  const UserPostCard({
    super.key,
    required this.userName,
    required this.recipeId,
    required this.recipeTitle,
    this.recipeDescription,
    this.recipeImageUrl,
    this.voteCount = 0,
    this.content,
  });

  @override
  _UserPostCardState createState() => _UserPostCardState();
}

class _UserPostCardState extends State<UserPostCard> {
  int _currentVoteCount = 0;

  @override
  void initState() {
    super.initState();
    _currentVoteCount = widget.voteCount;
  }

  void _upvote() {
    setState(() {
      _currentVoteCount++;
    });
  }

  void _downvote() {
    setState(() {
      _currentVoteCount--;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      color: ColorPalette.darkgray,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: ColorPalette.lightgray,
                    child: const FaIcon(FontAwesomeIcons.solidLemon, color: ColorPalette.mustard,),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "@${widget.userName}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w300,
                      color: ColorPalette.offWhite,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "shared a new recipe",
                    style: TextStyle(color: ColorPalette.placeholdergray),
                  ),
                ],
              ),
            ),
            if (widget.content != null) ...[
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Text(
                  '"${widget.content!}"',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: ColorPalette.offWhite,
                  ),
                ),
              ),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      IconButton(
                        style: ButtonStyle(
                          padding: WidgetStateProperty.all(
                            const EdgeInsets.all(0),
                          ),
                        ),
                        icon: const Icon(Icons.keyboard_arrow_up),
                        onPressed: _upvote,
                        color: ColorPalette.gray,
                        iconSize: 50,
                      ),
                      Text(
                        "$_currentVoteCount",
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: ColorPalette.offWhite),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        style: ButtonStyle(
                          padding: WidgetStateProperty.all(
                            const EdgeInsets.all(0),
                          ),
                        ),
                        icon: const Icon(Icons.keyboard_arrow_down),
                        onPressed: _downvote,
                        color: ColorPalette.gray,
                        iconSize: 50,
                      ),
                    ],
                  ),
                ),
                getRecipeImage(widget.recipeImageUrl),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.recipeTitle ?? "${widget.userName}'s Recipe",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: ColorPalette.offWhite,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.recipeDescription?.isNotEmpty == true
                            ? widget.recipeDescription!
                            : "No description available.",
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w300,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: () {},
                  icon: FaIcon(
                    FontAwesomeIcons.heart,
                    color: ColorPalette.offWhite,
                    size: 28,
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: FaIcon(
                    FontAwesomeIcons.comment,
                    color: ColorPalette.offWhite,
                    size: 28,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => RecipeDetailPage(
                          recipeId: widget.recipeId,
                        ),
                      ),
                    );
                  },
                  icon: FaIcon(
                    FontAwesomeIcons.upRightFromSquare,
                    color: ColorPalette.offWhite,
                    size: 24,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget getRecipeImage(String? imageUrl) {
    final random = Random();
    int imageNumber = random.nextInt(11) + 1;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: imageUrl != null && imageUrl.isNotEmpty
          ? Image.network(
              imageUrl,
              height: 120,
              width: 120,
              fit: BoxFit.cover,
            )
          : Container(
              color: ColorPalette.offWhite,
              height: 120,
              width: 120,
              child: Stack(
                children: [
                  Image.asset(
                    'assets/images/stock_food_$imageNumber.jpg',
                    fit: BoxFit.cover,
                    height: 120,
                    width: 120,
                  ),
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                      child: Container(),
                    ),
                  ),
                  Center(
                    child: Icon(
                      Icons.image,
                      color: ColorPalette.lightgray,
                      size: 50,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
