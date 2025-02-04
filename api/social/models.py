from django.db import models
from django.contrib.auth.models import User
from recipes.models import Recipe


class Post(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    recipe = models.ForeignKey(Recipe, on_delete=models.CASCADE, null=True)
    content = models.TextField(blank=True, null=True)  
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def upvote_count(self):
        return self.vote_set.filter(is_upvote=True).count()

    def downvote_count(self):
        return self.vote_set.filter(is_upvote=False).count()
    
    def net_vote_count(self):
        return self.upvote_count() - self.downvote_count()
    
    def __str__(self):
        return f"Post by {self.user.username} on {self.created_at}"


class Comment(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    post = models.ForeignKey(Post, on_delete=models.CASCADE, related_name='comments')
    content = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return f"Comment by {self.user.username} on {self.created_at}"


class Like(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    post = models.ForeignKey(Post, on_delete=models.CASCADE, null=True, blank=True)
    comment = models.ForeignKey(Comment, on_delete=models.CASCADE, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ('user', 'post', 'comment')  
    
    def __str__(self):
        return f"Like by {self.user.username}"


class Follow(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='following')
    followed_user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='followers')
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ('user', 'followed_user')  
    
    def __str__(self):
        return f"{self.user.username} follows {self.followed_user.username}"


class Vote(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    post = models.ForeignKey(Post, on_delete=models.CASCADE, null=True, blank=True)
    is_upvote = models.BooleanField()  
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('user', 'post')  
    
    def __str__(self):
        return f"{'Upvote' if self.is_upvote else 'Downvote'} by {self.user.username} on {self.created_at}"