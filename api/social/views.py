from rest_framework import generics, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from .models import Post, Comment, Like, Vote, Follow
from .serializers import PostSerializer, CommentSerializer, LikeSerializer, VoteSerializer
from django.shortcuts import get_object_or_404
from django.http import JsonResponse
from django.contrib.auth.models import User
from api.serializers import UserSerializer
from recipes.models import Recipe
from recipes.serializers import RecipeSerializer

class PostListCreateAPIView(generics.ListCreateAPIView):
    queryset = Post.objects.all()
    serializer_class = PostSerializer
    permission_classes = [IsAuthenticated]

    def perform_create(self, serializer):
        serializer.save()

    def get(self, request, *args, **kwargs):
        posts = self.get_queryset()
        serializer = self.get_serializer(posts, many=True)
        return JsonResponse(serializer.data, safe=False)

    def post(self, request, *args, **kwargs):
        return super().post(request, *args, **kwargs)


class PostDetailAPIView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Post.objects.all()
    serializer_class = PostSerializer
    permission_classes = [IsAuthenticated]

    def get(self, request, *args, **kwargs):
        post = self.get_object()
        serializer = self.get_serializer(post)
        return JsonResponse(serializer.data)

    def put(self, request, *args, **kwargs):
        return super().put(request, *args, **kwargs)

    def delete(self, request, *args, **kwargs):
        return super().delete(request, *args, **kwargs)


class CommentListCreateAPIView(generics.ListCreateAPIView):
    serializer_class = CommentSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        post_id = self.kwargs.get('post_id')
        return Comment.objects.filter(post_id=post_id)

    def perform_create(self, serializer):
        post_id = self.kwargs.get('post_id')
        post = get_object_or_404(Post, id=post_id)
        serializer.save(user=self.request.user, post=post)

    def get(self, request, *args, **kwargs):
        comments = self.get_queryset()
        serializer = self.get_serializer(comments, many=True)
        return JsonResponse(serializer.data, safe=False)

    def post(self, request, *args, **kwargs):
        return super().post(request, *args, **kwargs)


class LikeCreateAPIView(generics.CreateAPIView):
    queryset = Like.objects.all()
    serializer_class = LikeSerializer
    permission_classes = [IsAuthenticated]

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

    def post(self, request, *args, **kwargs):
        return super().post(request, *args, **kwargs)


class LikeDeleteAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def delete(self, request, post_id):
        like = Like.objects.filter(user=request.user, post_id=post_id).first()

        if like:
            like.delete()
            return JsonResponse({"message": "Like deleted successfully"}, status=status.HTTP_204_NO_CONTENT)
        return JsonResponse({"error": "Like not found"}, status=status.HTTP_404_NOT_FOUND)


class LikeListAPIView(generics.ListAPIView):
    queryset = Like.objects.all()
    serializer_class = LikeSerializer
    permission_classes = [IsAuthenticated]

    def get(self, request, *args, **kwargs):
        likes = self.get_queryset()
        serializer = self.get_serializer(likes, many=True)
        return JsonResponse(serializer.data, safe=False)


class VoteCreateAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, post_id):
        value = request.data.get('value')  

        if value not in [-1, 0, 1]:
            return JsonResponse({"error": "Invalid vote value. Must be -1, 0, or 1."}, status=status.HTTP_400_BAD_REQUEST)

        post = get_object_or_404(Post, id=post_id)
        existing_vote = Vote.objects.filter(user=request.user, post=post).first()

        if existing_vote:
            if value == 0:  
                existing_vote.delete()
                return JsonResponse({"message": "Vote removed successfully"}, status=status.HTTP_200_OK)
            else:
                existing_vote.value = value
                existing_vote.save()
                return JsonResponse({"message": "Vote updated successfully"}, status=status.HTTP_200_OK)
        else:
            if value != 0:  
                Vote.objects.create(user=request.user, post=post, value=value)
                return JsonResponse({"message": "Vote created successfully"}, status=status.HTTP_201_CREATED)

        return JsonResponse({"message": "No action needed"}, status=status.HTTP_400_BAD_REQUEST)


class UserSearchAPIView(APIView):
    permission_classes = [IsAuthenticated]  

    def get(self, request):
        query = request.query_params.get('q', '').strip()  

        if not query:
            return Response(
                {"error": "Search query parameter 'q' is required."},
                status=status.HTTP_400_BAD_REQUEST
            )

        users = User.objects.filter(username__icontains=query)

        serializer = UserSerializer(users, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)
    
    
class UserPostsAPIView(generics.ListAPIView):
    serializer_class = PostSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user_id = self.kwargs.get('user_id')
        user = get_object_or_404(User, id=user_id)
        return Post.objects.filter(user=user)

    def get(self, request, *args, **kwargs):
        posts = self.get_queryset()
        serializer = self.get_serializer(posts, many=True)
        return JsonResponse(serializer.data, safe=False)


class UserRecipesAPIView(generics.ListAPIView):
    serializer_class = RecipeSerializer  
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user_id = self.kwargs.get('user_id')
        user = get_object_or_404(User, id=user_id)
        return Recipe.objects.filter(created_by=user)  

    def get(self, request, *args, **kwargs):
        recipes = self.get_queryset()
        serializer = self.get_serializer(recipes, many=True)
        return JsonResponse(serializer.data, safe=False)


class CreateFollowAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, user_id):
        current_user = request.user
        user_to_follow = get_object_or_404(User, id=user_id)

        if current_user == user_to_follow:
            return Response({"error": "You cannot follow yourself."}, status=400)

        if not Follow.objects.filter(follower=current_user, followed=user_to_follow).exists():
            Follow.objects.create(follower=current_user, followed=user_to_follow)
            return Response({"message": "You are now following this user."}, status=201)
        else:
            return Response({"error": "You are already following this user."}, status=400)


class DeleteFollowAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def delete(self, request, user_id):
        current_user = request.user
        user_to_unfollow = get_object_or_404(User, id=user_id)

        follow = Follow.objects.filter(follower=current_user, followed=user_to_unfollow).first()

        if follow:
            follow.delete()
            return Response({"message": "You have unfollowed this user."}, status=204)
        else:
            return Response({"error": "You are not following this user."}, status=400)
        

class IsUserFollowingAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, user_id):
        follower = request.user
        followed = get_object_or_404(User, id=user_id)
        
        is_following = follower.following.filter(id=followed.id).exists()

        return JsonResponse({"is_following": is_following})


class VoteDetailAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def delete(self, request, post_id):
        post = Post.objects.get(id=post_id)
        vote = Vote.objects.filter(user=request.user, post=post).first()
        
        if vote:
            vote.delete()
            return JsonResponse({"message": "Vote deleted successfully"}, status=status.HTTP_204_NO_CONTENT)
        else:
            return JsonResponse({"error": "Vote not found"}, status=status.HTTP_404_NOT_FOUND)


class VoteDeleteAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def delete(self, request, post_id):
        post = get_object_or_404(Post, id=post_id)
        vote = Vote.objects.filter(user=request.user, post=post).first()

        if vote:
            vote.delete()
            return JsonResponse({"message": "Vote deleted successfully"}, status=status.HTTP_204_NO_CONTENT)
        return JsonResponse({"error": "Vote not found"}, status=status.HTTP_404_NOT_FOUND)
