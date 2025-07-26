from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from django.utils.html import format_html
from .models import CustomUser, UserSettings

class CustomUserAdmin(UserAdmin):
    model = CustomUser
    list_display = ['id', 'username', 'email', 'first_name', 'last_name', 'is_staff', 'avatar_icon']
    list_filter = ['is_staff', 'is_superuser']
    search_fields = ['username', 'email']
    ordering = ['username']

    fieldsets = UserAdmin.fieldsets + (
        (None, {'fields': ('avatar_icon',)}),
    )

@admin.register(UserSettings)
class UserSettingsAdmin(admin.ModelAdmin):
    list_display = [
        'user', 'age', 'gender', 'city', 'country', 'ethnicity',
        'is_vegan', 'is_vegetarian', 'is_gluten_free', 'is_lactose_intolerant',
        'has_peanut_allergy', 'has_tree_nut_allergy', 'has_shellfish_allergy',
        'has_egg_allergy', 'has_milk_allergy', 'has_soy_allergy',
        'has_wheat_allergy', 'has_fish_allergy',
    ]
    search_fields = ['user__username', 'city', 'country', 'ethnicity']
    list_filter = ['is_vegan', 'is_vegetarian', 'has_peanut_allergy', 'has_fish_allergy']


admin.site.register(CustomUser, CustomUserAdmin)
