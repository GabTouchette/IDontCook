from django.contrib import admin

from .models import HomeEvent


@admin.register(HomeEvent)
class HomeEventAdmin(admin.ModelAdmin):
    list_display = ('slug', 'title', 'starts_at', 'ends_at', 'priority', 'is_active', 'tag_filter')
    list_filter = ('is_active', 'starts_at', 'ends_at')
    search_fields = ('slug', 'title', 'body')
    prepopulated_fields = {'slug': ('title',)}
    ordering = ('-starts_at',)
