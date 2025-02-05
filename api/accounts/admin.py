from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from django.utils.html import format_html
from .models import CustomUser

class CustomUserAdmin(UserAdmin):
    model = CustomUser
    list_display = ['username', 'email', 'first_name', 'last_name', 'is_staff', 'avatar_icon']
    list_filter = ['is_staff', 'is_superuser']
    search_fields = ['username', 'email']
    ordering = ['username']

    fieldsets = UserAdmin.fieldsets + (
        (None, {'fields': ('avatar_icon',)}),
    )

admin.site.register(CustomUser, CustomUserAdmin)
