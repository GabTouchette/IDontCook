from django.contrib import admin

from .models import GroceryBag, GroceryBagRecipe, GroceryItemOverride


class GroceryBagRecipeInline(admin.TabularInline):
    model = GroceryBagRecipe
    extra = 0
    raw_id_fields = ("recipe",)


class GroceryItemOverrideInline(admin.TabularInline):
    model = GroceryItemOverride
    extra = 0


@admin.register(GroceryBag)
class GroceryBagAdmin(admin.ModelAdmin):
    list_display = ("id", "user", "created_at", "updated_at")
    search_fields = ("user__username", "user__email")
    inlines = [GroceryBagRecipeInline, GroceryItemOverrideInline]
