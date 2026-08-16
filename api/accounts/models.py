from django.contrib.auth.models import AbstractUser
from django.db import models

from api.settings import AUTH_USER_MODEL

class CustomUser(AbstractUser):
    avatar_icon = models.CharField(max_length=100, default="lemon")

    def __str__(self):
        return self.username


class UserSettings(models.Model):
    user = models.OneToOneField(AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="settings")

    # Personal Info
    age = models.PositiveIntegerField(null=True, blank=True)
    gender = models.CharField(max_length=20, blank=True)
    city = models.CharField(max_length=100, blank=True)
    country = models.CharField(max_length=100, blank=True)
    ethnicity = models.CharField(max_length=100, blank=True)

    # Grocery deals — the user's location powers the "deals near you" home
    # module (aggregating the nearest stores). postal_code is what Flipp needs;
    # latitude/longitude give exact proximity (from GPS). The deals_store_* fields
    # remain for the standalone store finder but aren't required by the feed.
    postal_code = models.CharField(max_length=10, blank=True)
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)
    deals_store_merchant = models.CharField(max_length=120, blank=True)
    deals_store_merchant_id = models.IntegerField(null=True, blank=True)

    # Dietary Preferences
    is_vegan = models.BooleanField(default=False)
    is_vegetarian = models.BooleanField(default=False)
    is_gluten_free = models.BooleanField(default=False)
    is_lactose_intolerant = models.BooleanField(default=False)

    # Allergies
    has_peanut_allergy = models.BooleanField(default=False)
    has_tree_nut_allergy = models.BooleanField(default=False)
    has_shellfish_allergy = models.BooleanField(default=False)
    has_egg_allergy = models.BooleanField(default=False)
    has_milk_allergy = models.BooleanField(default=False)
    has_soy_allergy = models.BooleanField(default=False)
    has_wheat_allergy = models.BooleanField(default=False)
    has_fish_allergy = models.BooleanField(default=False)

    def __str__(self):
        return f"{self.user.username}'s Settings"
