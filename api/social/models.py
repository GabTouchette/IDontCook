from django.db import models
from django.contrib.auth.models import User
from recipes.models import Recipe


class Post(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    recipe = models.ForeignKey(Recipe, on_delete=models.CASCADE, null=True, blank=True)
    content = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def upvote_count(self):
        return self.votes.filter(value=1).count()

    def downvote_count(self):
        return self.votes.filter(value=-1).count()

    def net_vote_count(self):
        return self.votes.aggregate(models.Sum('value'))['value__sum'] or 0

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
    post = models.ForeignKey(Post, on_delete=models.CASCADE, related_name="likes", null=True, blank=True)
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
    VOTE_CHOICES = [
        (-1, 'Downvote'),
        (0, 'No Vote'),
        (1, 'Upvote'),
    ]

    user = models.ForeignKey(User, on_delete=models.CASCADE)
    post = models.ForeignKey(Post, on_delete=models.CASCADE, related_name='votes')
    value = models.IntegerField(choices=VOTE_CHOICES, default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=['user', 'post'], name='unique_user_post_vote')
        ]

    def __str__(self):
        return f"{'Upvote' if self.value == 1 else 'Downvote' if self.value == -1 else 'No Vote'} by {self.user.username} on {self.created_at}"
