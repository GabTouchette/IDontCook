import re
import requests
from bs4 import BeautifulSoup
from urllib.parse import urljoin, urlparse

_MAX_CONTENT_CHARS = 6000
_FETCH_TIMEOUT = 10

_INSTAGRAM_HOSTS = ("instagram.com", "instagr.am", "cdninstagram.com")
_STRIP_TAGS = {"script", "style", "nav", "footer", "header", "aside", "noscript"}

_BROWSER_HEADERS = {
    "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
    "Accept": "image/avif,image/webp,image/apng,image/*,*/*;q=0.8",
    "Accept-Language": "en-US,en;q=0.9",
}


def _fetch_image_bytes(image_url: str, page_url: str = ""):
    """
    Fetch raw image bytes + content-type from a URL.

    Many recipe CDNs (Food Network / Akamai, etc.) block plain `requests` via
    TLS/JA3 fingerprinting — no header combination gets past them. `curl_cffi`
    impersonates a real Chrome TLS handshake and slips through. We fall back to
    plain `requests` for hosts that don't need impersonation.

    Returns (bytes, content_type) or (None, None) on failure.
    """
    headers = {**_BROWSER_HEADERS, "Referer": page_url or image_url}

    # Primary: curl_cffi with Chrome impersonation (defeats TLS fingerprinting)
    try:
        from curl_cffi import requests as curl_requests

        resp = curl_requests.get(
            image_url,
            headers=headers,
            impersonate="chrome",
            timeout=15,
        )
        if resp.status_code == 200 and resp.content:
            ctype = resp.headers.get("Content-Type", "image/jpeg").split(";")[0].strip()
            return resp.content, ctype
    except Exception:
        pass

    # Fallback: plain requests (works for hosts without bot protection)
    try:
        resp = requests.get(image_url, timeout=10, headers=headers)
        if resp.status_code == 200 and resp.content:
            ctype = resp.headers.get("Content-Type", "image/jpeg").split(";")[0].strip()
            return resp.content, ctype
    except Exception:
        pass

    return None, None


def _download_and_store_image(image_url: str, page_url: str = "") -> str:
    """
    Download image from URL and store it via Django's default storage.
    Returns the stored URL, or empty string if download/storage fails.
    """
    import uuid
    import mimetypes
    from django.core.files.base import ContentFile
    from django.core.files.storage import default_storage

    try:
        image_data, content_type = _fetch_image_bytes(image_url, page_url)
        if not image_data:
            return ""

        ext = mimetypes.guess_extension(content_type) or ".jpg"
        # mimetypes sometimes returns .jpe for JPEG — normalise
        if ext in (".jpe", ".jpeg"):
            ext = ".jpg"

        filename = f"recipe_images/imported/{uuid.uuid4().hex}{ext}"
        path = default_storage.save(filename, ContentFile(image_data))
        return default_storage.url(path)
    except Exception:
        return ""


def _fetch_page_html(url: str) -> str:
    """
    Fetch a page's HTML. Recipe sites behind Akamai (Food Network, etc.) block
    plain `requests` via TLS fingerprinting, so try curl_cffi (Chrome
    impersonation) first and fall back to requests for unprotected hosts.
    Raises requests.HTTPError if neither can retrieve the page.
    """
    page_headers = {
        "User-Agent": _BROWSER_HEADERS["User-Agent"],
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "Accept-Language": "en-US,en;q=0.9",
    }

    # Primary: curl_cffi with Chrome impersonation (defeats TLS fingerprinting)
    try:
        from curl_cffi import requests as curl_requests

        resp = curl_requests.get(
            url, headers=page_headers, impersonate="chrome", timeout=15
        )
        if resp.status_code == 200 and resp.text:
            return resp.text
    except Exception:
        pass

    # Fallback: plain requests (raises HTTPError on non-2xx so the view can 502)
    response = requests.get(url, timeout=_FETCH_TIMEOUT, headers=page_headers)
    response.raise_for_status()
    return response.text


def fetch_and_clean_html(url: str) -> tuple[str, str]:
    """Fetch HTML and extract text + primary image URL"""
    html = _fetch_page_html(url)

    soup = BeautifulSoup(html, "html.parser")

    # Extract image URL (prefer og:image, then first img tag)
    image_url = ""
    og_image = soup.find("meta", property="og:image")
    if og_image and og_image.get("content"):
        image_url = og_image["content"]
    else:
        img = soup.find("img")
        if img and img.get("src"):
            image_url = img["src"]

    # Make relative URLs absolute
    if image_url:
        image_url = urljoin(url, image_url)

    # Remove unwanted tags
    for tag in soup.find_all(_STRIP_TAGS):
        tag.decompose()

    text = soup.get_text(separator="\n", strip=True)
    lines = [line for line in text.splitlines() if line.strip()]
    cleaned = "\n".join(lines)
    return cleaned[:_MAX_CONTENT_CHARS], image_url


def is_instagram_url(url: str) -> bool:
    """True if the URL points at an Instagram post/reel/tv."""
    try:
        host = (urlparse(url).hostname or "").lower()
    except Exception:
        return False
    return any(host == h or host.endswith("." + h) for h in _INSTAGRAM_HOSTS)


def _clean_instagram_caption(raw: str) -> str:
    """
    Instagram's og:description looks like:
        `1,234 likes, 56 comments - handle on January 1, 2024: "the real caption"`
    Strip the engagement/handle prefix and surrounding quotes so only the caption
    (which holds the recipe) is fed to the model. Falls back to the raw string when
    the pattern doesn't match.
    """
    if not raw:
        return ""
    text = raw.strip()
    # Drop a leading "N likes, M comments - handle on <date>:" prefix if present.
    prefix = re.match(r'^[\d,\.]+ likes?,?.*?:\s*', text, re.IGNORECASE | re.DOTALL)
    if prefix:
        text = text[prefix.end():]
    # Unwrap a single pair of surrounding double quotes.
    text = text.strip()
    if len(text) >= 2 and text[0] in "“\"" and text[-1] in "”\"":
        text = text[1:-1].strip()
    return text


def fetch_instagram_content(url: str) -> tuple[str, str]:
    """
    Best-effort extraction of an Instagram post/reel's caption + cover image from
    Open Graph / meta tags (no login, no paid API). Returns (caption, image_url).

    Raises ValueError with a user-facing message when Instagram serves a login wall
    or the caption can't be read (private post, removed content, or markup change).
    """
    html = _fetch_page_html(url)
    soup = BeautifulSoup(html, "html.parser")

    def _meta(attr: str, value: str) -> str:
        tag = soup.find("meta", attrs={attr: value})
        return (tag.get("content") or "").strip() if tag else ""

    caption = _meta("property", "og:description") or _meta("name", "description")
    caption = _clean_instagram_caption(caption)

    image_url = _meta("property", "og:image")
    if image_url:
        image_url = urljoin(url, image_url)

    # Login wall / private / removed: Instagram returns a generic interstitial with
    # no usable caption. Signal a clear, user-facing error instead of feeding junk
    # to the model.
    login_walled = "loginForm" in html or "Login • Instagram" in html
    if not caption or (login_walled and len(caption) < 40):
        raise ValueError(
            "Couldn't read this Instagram post — it may be private, removed, "
            "or Instagram blocked the request. Try a public reel or post."
        )

    return caption[:_MAX_CONTENT_CHARS], image_url


def import_recipe_from_url(url: str, service) -> str:
    import json
    import logging
    from .api import PromptTemplates, LIGHT_MODEL
    import anthropic
    from django.conf import settings

    logger = logging.getLogger(__name__)
    if is_instagram_url(url):
        content, image_url = fetch_instagram_content(url)
        prompt = PromptTemplates.instagram_import_prompt(content, image_url)
    else:
        content, image_url = fetch_and_clean_html(url)
        if not content:
            raise ValueError("No readable content found at this URL.")
        prompt = PromptTemplates.url_import_prompt(content, image_url)
    logger.debug(f"Extracted image_url from {url}: {image_url}")

    # Runs synchronously in the URL-import request path (already preceded by a
    # blocking page fetch); bound the LLM wall-clock instead of inheriting the
    # SDK default (600s x 2 retries) so a slow/hung call can't pin the request.
    client = anthropic.Anthropic(
        api_key=getattr(settings, "ANTHROPIC_API_KEY", None),
        timeout=45,
        max_retries=1,
    )
    response = client.messages.create(
        model=LIGHT_MODEL,
        max_tokens=2048,
        messages=[{"role": "user", "content": prompt}],
    )

    raw_response = response.content[0].text

    # Extract JSON from $$ delimiters
    match = re.search(r'\$\$\s*(.*?)\s*\$\$', raw_response, re.DOTALL)
    if match:
        json_str = match.group(1).strip()
        try:
            recipe_json = json.loads(json_str)

            # Download and store the image server-side (avoids CDN hotlink blocks)
            # Pass the original page URL as Referer so CDN whitelists pass
            stored_url = _download_and_store_image(image_url, page_url=url) if image_url else ""
            recipe_json["image_url"] = stored_url or image_url or recipe_json.get("image_url", "")

            # Fix servings: default to 4 if missing/null/1 and content doesn't mention servings
            servings = recipe_json.get("servings")
            if not servings or servings == 1 or servings == 0:
                servings_text = content.lower()
                # Only use 1 if the content explicitly mentions single serving
                if ("serves 1" in servings_text or "makes 1" in servings_text or "1 serving" in servings_text):
                    recipe_json["servings"] = 1
                else:
                    recipe_json["servings"] = 4  # Safe default

            # Return formatted response with the corrected JSON
            logger.debug(f"Final recipe JSON - servings: {recipe_json.get('servings')}, image_url: {recipe_json.get('image_url', '')}")
            return f"$$ {json.dumps(recipe_json)} $$"
        except json.JSONDecodeError:
            pass  # Fall back to raw response if JSON parsing fails

    return raw_response
