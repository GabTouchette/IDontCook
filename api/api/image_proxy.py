"""
Cross-origin image proxy for scraped recipe images.

Context: ~59% of catalog recipes reference images on hosts that serve NO
`Access-Control-Allow-Origin` header (www.allrecipes.com, images.ricardocuisine.com,
food.fnr.sndimg.com). On Flutter *web* the CanvasKit renderer paints network images
onto a <canvas>, and the browser refuses to read cross-origin images that lack CORS
headers ("tainted canvas") — so those images silently fail to render with no console
error. Native iOS/Android is unaffected (no CORS there).

This endpoint fetches the upstream image server-to-server (no CORS on the server side)
and re-serves it with `Access-Control-Allow-Origin: *`, so the browser will paint it.

Safety: to avoid becoming an open proxy / SSRF vector this only fetches from a fixed
allowlist of known recipe-image hosts, resolves the host to a public IP, caps the
response size, and only relays responses whose Content-Type is an image.
"""
import ipaddress
import logging
import socket
from urllib.parse import urlparse

import requests
from django.http import HttpResponse, HttpResponseBadRequest, StreamingHttpResponse
from django.views.decorators.http import require_GET

logger = logging.getLogger(__name__)

# Upstream image hosts we scrape from. Restricting the proxy to known hosts keeps
# it from being abused as a generic open proxy. Extend this when the scraper starts
# pulling from a new domain (grep the catalog: SELECT DISTINCT host FROM web_image_url).
ALLOWED_IMAGE_HOSTS = frozenset({
    "www.allrecipes.com",
    "images.allrecipes.com",
    "images.immediate.co.uk",
    "images.ricardocuisine.com",
    "ucarecdn.com",
    "food.fnr.sndimg.com",
    # Dotdash Meredith CDNs (Serious Eats / Simply Recipes) — serve no CORS header
    # and 460-block non-browser User-Agents, so they must go through the proxy.
    "www.seriouseats.com",
    "www.simplyrecipes.com",
})

MAX_IMAGE_BYTES = 15 * 1024 * 1024  # 15 MB ceiling
UPSTREAM_TIMEOUT = 10  # seconds
CACHE_MAX_AGE = 7 * 24 * 60 * 60  # 7 days — upstream image URLs are effectively immutable
_BROWSER_UA = (
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/124.0 Safari/537.36"
)


def _host_is_public(hostname):
    """Reject hosts that resolve to private/loopback/link-local IPs (SSRF guard)."""
    try:
        infos = socket.getaddrinfo(hostname, None)
    except socket.gaierror:
        return False
    for info in infos:
        ip = ipaddress.ip_address(info[4][0])
        if (ip.is_private or ip.is_loopback or ip.is_link_local
                or ip.is_reserved or ip.is_multicast or ip.is_unspecified):
            return False
    return True


@require_GET
def image_proxy(request):
    raw_url = (request.GET.get("url") or "").strip()
    if not raw_url:
        return HttpResponseBadRequest("Missing url parameter")

    parsed = urlparse(raw_url)
    if parsed.scheme not in ("http", "https") or not parsed.hostname:
        return HttpResponseBadRequest("Invalid url")
    if parsed.hostname not in ALLOWED_IMAGE_HOSTS:
        logger.warning("Image proxy rejected non-allowlisted host: %s", parsed.hostname)
        return HttpResponseBadRequest("Host not allowed")
    if not _host_is_public(parsed.hostname):
        return HttpResponseBadRequest("Host not allowed")

    headers = {
        "User-Agent": _BROWSER_UA,
        "Accept": "image/avif,image/webp,image/apng,image/*,*/*;q=0.8",
        "Referer": f"{parsed.scheme}://{parsed.hostname}/",
    }
    try:
        upstream = requests.get(
            raw_url, headers=headers, stream=True, timeout=UPSTREAM_TIMEOUT
        )
    except requests.RequestException:
        logger.warning("Image proxy upstream fetch failed: %s", raw_url, exc_info=True)
        return HttpResponse(status=502)

    content_type = upstream.headers.get("Content-Type", "")
    if upstream.status_code != 200 or not content_type.startswith("image/"):
        status = upstream.status_code if upstream.status_code != 200 else 415
        upstream.close()
        # Fail closed: the client's Image errorBuilder shows its placeholder.
        return HttpResponse(status=status)

    def _stream():
        total = 0
        try:
            for chunk in upstream.iter_content(chunk_size=64 * 1024):
                total += len(chunk)
                if total > MAX_IMAGE_BYTES:
                    logger.warning("Image proxy aborted oversized response: %s", raw_url)
                    break
                yield chunk
        finally:
            upstream.close()

    response = StreamingHttpResponse(_stream(), content_type=content_type)
    response["Access-Control-Allow-Origin"] = "*"
    response["Cache-Control"] = f"public, max-age={CACHE_MAX_AGE}"
    return response
