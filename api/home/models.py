from django.db import models


class HomeEvent(models.Model):
    """An admin-managed, time-boxed event surfaced on the home feed as an
    `event_card` module (e.g. "Soup week"). Active while `is_active` is set
    and `starts_at <= now <= ends_at`."""

    slug = models.SlugField(max_length=100, unique=True)
    title = models.CharField(max_length=255)
    body = models.TextField(blank=True)
    image_url = models.URLField(max_length=500, blank=True)
    cta = models.CharField(max_length=255, blank=True)
    starts_at = models.DateTimeField()
    ends_at = models.DateTimeField()
    priority = models.FloatField(default=1.0, help_text="Ranking boost multiplier for this event's card.")
    is_active = models.BooleanField(default=True)
    tag_filter = models.CharField(
        max_length=100,
        blank=True,
        help_text="Optional recipe tag; when set, up to 4 matching recipes are attached to the card.",
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-starts_at']

    def __str__(self):
        return f"{self.title} ({self.slug})"
