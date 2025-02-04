from rest_framework import generics, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from .models import Post, Comment, Like, Vote
from .serializers import PostSerializer, CommentSerializer, LikeSerializer, VoteSerializer
from django.shortcuts import get_object_or_404


class PostListCreateAPIView(generics.ListCreateAPIView):
    queryset = Post.objects.all()
    serializer_class = PostSerializer
    permission_classes = [IsAuthenticated]

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

class PostDetailAPIView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Post.objects.all()
    serializer_class = PostSerializer
    permission_classes = [IsAuthenticated]


class CommentListCreateAPIView(generics.ListCreateAPIView):
    queryset = Comment.objects.all()
    serializer_class = CommentSerializer
    permission_classes = [IsAuthenticated]

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

class CommentDetailAPIView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Comment.objects.all()
    serializer_class = CommentSerializer
    permission_classes = [IsAuthenticated]


class LikeCreateAPIView(generics.CreateAPIView):
    queryset = Like.objects.all()
    serializer_class = LikeSerializer
    permission_classes = [IsAuthenticated]

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)
        

class LikeDeleteAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def delete(self, request, post_id):
        like = Like.objects.filter(user=request.user, post_id=post_id).first()

        if like:
            like.delete()
            return Response({"message": "Like deleted successfully"}, status=status.HTTP_204_NO_CONTENT)
        return Response({"error": "Like not found"}, status=status.HTTP_404_NOT_FOUND)


class LikeListAPIView(generics.ListAPIView):
    queryset = Like.objects.all()
    serializer_class = LikeSerializer
    permission_classes = [IsAuthenticated]


class VoteCreateAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, post_id):
        value = request.data.get('value')  # Expected: -1 (downvote), 0 (remove vote), 1 (upvote)

        if value not in [-1, 0, 1]:
            return Response({"error": "Invalid vote value. Must be -1, 0, or 1."}, status=status.HTTP_400_BAD_REQUEST)

        post = get_object_or_404(Post, id=post_id)
        existing_vote = Vote.objects.filter(user=request.user, post=post).first()

        if existing_vote:
            if value == 0:  # Remove the vote
                existing_vote.delete()
                return Response({"message": "Vote removed successfully"}, status=status.HTTP_200_OK)
            else:
                existing_vote.value = value
                existing_vote.save()
                return Response({"message": "Vote updated successfully"}, status=status.HTTP_200_OK)
        else:
            if value != 0:  # Create a vote only if it's not zero
                Vote.objects.create(user=request.user, post=post, value=value)
                return Response({"message": "Vote created successfully"}, status=status.HTTP_201_CREATED)

        return Response({"message": "No action needed"}, status=status.HTTP_400_BAD_REQUEST)

class VoteDetailAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def delete(self, request, post_id):
        post = Post.objects.get(id=post_id)
        vote = Vote.objects.filter(user=request.user, post=post).first()
        
        if vote:
            vote.delete()
            return Response({"message": "Vote deleted successfully"}, status=status.HTTP_204_NO_CONTENT)
        else:
            return Response({"error": "Vote not found"}, status=status.HTTP_404_NOT_FOUND)


class VoteDeleteAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def delete(self, request, post_id):
        post = get_object_or_404(Post, id=post_id)
        vote = Vote.objects.filter(user=request.user, post=post).first()

        if vote:
            vote.delete()
            return Response({"message": "Vote deleted successfully"}, status=status.HTTP_204_NO_CONTENT)
        return Response({"error": "Vote not found"}, status=status.HTTP_404_NOT_FOUND)