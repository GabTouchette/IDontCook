"""Helpers for turning stored media references into client-usable URLs.

Local FileSystemStorage (self-hosted, no GCS) yields *relative* "/media/..."
paths, and behind the Cloudflare tunnel `request.scheme` is http (the tunnel
does not forward X-Forwarded-Proto), so a naive build_absolute_uri emits
http:// URLs that iOS ATS / Android cleartext policies block. GCS, by contrast,
already yields absolute https URLs. This helper normalizes both cases.
"""

from django.conf import settings


def absolute_media_url(request, url):
    """Return an absolute, https-in-prod URL for a (possibly relative) media path."""
    if not url:
        return url
    if url.startswith('/') and request is not None:
        url = request.build_absolute_uri(url)
    if settings.IS_PRODUCTION and url.startswith('http://'):
        url = 'https://' + url[len('http://'):]
    return url
