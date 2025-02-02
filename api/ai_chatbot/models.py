from django.db import models

class Conversation(models.Model):
    # user = models.ForeignKey(User, on_delete=models.CASCADE)
    
    user_query = models.TextField()  
    ai_response = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Conversation {self.id} - {self.created_at}"

class ChatHistory(models.Model):
    conversation = models.ForeignKey(Conversation, related_name='history', on_delete=models.CASCADE)
    sender = models.CharField(max_length=50)  # 'user' or 'ai'
    message = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.sender} - {self.created_at}"
