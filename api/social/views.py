from rest_framework import generics, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from .models import Post, Comment, Like, Vote
from .serializers import PostSerializer, CommentSerializer, LikeSerializer, VoteSerializer

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

class LikeListAPIView(generics.ListAPIView):
    queryset = Like.objects.all()
    serializer_class = LikeSerializer
    permission_classes = [IsAuthenticated]


class VoteCreateAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, post_id):
        is_upvote = request.data.get('is_upvote', True)
        post = Post.objects.get(id=post_id)

        existing_vote = Vote.objects.filter(user=request.user, post=post).first()
        
        if existing_vote:
            existing_vote.is_upvote = is_upvote
            existing_vote.save()
            return Response({"message": "Vote updated successfully"}, status=status.HTTP_200_OK)
        else:
            Vote.objects.create(user=request.user, post=post, is_upvote=is_upvote)
            return Response({"message": "Vote created successfully"}, status=status.HTTP_201_CREATED)

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
