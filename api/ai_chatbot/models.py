from django.db import models
from accounts.models import CustomUser


class Conversation(models.Model):
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE)
    
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
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE)

    def __str__(self):
        return f"{self.sender} - {self.created_at}"


class ChatMessage(models.Model):
    """
    Server-side conversation history for chat v2 (tool-use protocol).

    Stores both sides of the conversation. `blocks` holds the structured
    blocks emitted during the assistant turn (plan §1.1 block schema:
    recipe / recipe_ref / recipe_update), as a JSON list.
    """
    ROLE_USER = "user"
    ROLE_ASSISTANT = "assistant"
    ROLE_CHOICES = [
        (ROLE_USER, "User"),
        (ROLE_ASSISTANT, "Assistant"),
    ]

    conversation = models.ForeignKey(Conversation, related_name='messages', on_delete=models.CASCADE)
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE)
    role = models.CharField(max_length=16, choices=ROLE_CHOICES)
    text = models.TextField(blank=True, default="")
    blocks = models.JSONField(default=list, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["created_at", "id"]

    def __str__(self):
        return f"{self.role} - conversation {self.conversation_id} - {self.created_at}"