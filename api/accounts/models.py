from django.contrib.auth.models import AbstractUser
from django.db import models

class CustomUser(AbstractUser):
    avatar_icon = models.CharField(max_length=100, default="fa-lemon")

    def __str__(self):
        return self.username
