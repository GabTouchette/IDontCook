from django.conf import settings
from django.contrib import admin
from django.urls import path, include, re_path
from django.views.static import serve

from .image_proxy import image_proxy

urlpatterns = [
    path("admin/", admin.site.urls),

    path("api/images/proxy/", image_proxy, name="image-proxy"),
    path("api/recipes/", include("recipes.urls")),
    path('api/ai/', include('ai_chatbot.urls')),
    path('api/social/', include('social.urls')),
    path('api/accounts/', include('accounts.urls')),
    path('api/', include('meal_planning.urls')),
    path('api/home/', include('home.urls')),
    path('api/grocery/', include('grocery.urls')),
]

# When media lives on local disk (self-hosted, no GCS bucket), serve it through
# Django. Whitenoise can't be used here: it indexes files once at boot, so
# runtime-uploaded images wouldn't be served until a restart. This route is
# skipped when USE_GCS is on (images are served from the bucket's own URLs).
if not settings.USE_GCS:
    urlpatterns += [
        re_path(
            r"^media/(?P<path>.*)$",
            serve,
            {"document_root": settings.MEDIA_ROOT},
        ),
    ]
