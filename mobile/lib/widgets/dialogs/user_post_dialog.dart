import 'package:flutter/material.dart';

class PostDialog extends StatefulWidget {
  final String recipeTitle;
  final String? recipeImageUrl;
  final String? recipeDescription;
  final Function(String? comment) onPost; // Callback when posting

  const PostDialog({
    super.key,
    required this.recipeTitle,
    this.recipeImageUrl,
    this.recipeDescription,
    required this.onPost,
  });

  @override
  _PostDialogState createState() => _PostDialogState();
}

class _PostDialogState extends State<PostDialog> {
  final TextEditingController _commentController = TextEditingController();

  Widget getRecipeImage(String? imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: imageUrl != null && imageUrl.isNotEmpty
          ? Image.network(imageUrl, height: 150, width: double.infinity, fit: BoxFit.cover)
          : Container(
              height: 150,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(12)),
              child: const Center(
                child: Icon(Icons.image, color: Colors.grey, size: 60),
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Share Recipe", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // Recipe Preview
            getRecipeImage(widget.recipeImageUrl),
            const SizedBox(height: 8),
            Text(widget.recipeTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(
              widget.recipeDescription?.isNotEmpty == true ? widget.recipeDescription! : "No description available.",
              style: TextStyle(color: Colors.grey[600]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 16),

            // Comment Input
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Add a comment (optional)...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 16),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    widget.onPost(_commentController.text.trim());
                    Navigator.pop(context);
                  },
                  child: const Text("Post"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
