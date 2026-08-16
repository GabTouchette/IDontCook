"""Server-side geocoding of Canadian postal codes.

Uses Zippopotam.us (free, keyless) at the FSA level — the first 3 characters of
a Canadian postal code (the Forward Sortation Area), which resolves to a
neighbourhood centroid. That's plenty of precision to centre a store map and to
seed the Overpass "nearby grocery" query.

Doing this server-side (rather than with an on-device geocoder) means the map
works identically on web and mobile, and keeps the mobile app free of a native
geocoding plugin. Cached aggressively; every failure returns None so the store
finder degrades to a list with no map.
"""

import logging
import re

import requests
from django.core.cache import cache

logger = logging.getLogger(__name__)

ZIPPOPOTAM_URL = "https://api.zippopotam.us/ca/{fsa}"
NOMINATIM_REVERSE_URL = "https://nominatim.openstreetmap.org/reverse"
HTTP_TIMEOUT = 10
GEOCODE_CACHE_TTL = 30 * 24 * 60 * 60  # 30 days — FSA centroids are static
REVERSE_CACHE_TTL = 7 * 24 * 60 * 60  # 7 days

_HEADERS = {"User-Agent": "ICantCook/1.0 (recipe app store finder)"}


def geocode_postal_code(postal_code):
    """Return (lat, lng) for a Canadian postal code, or None.

    Only the FSA (first 3 alphanumerics) is used, so 'H2X 1Y4' and 'H2X1Y4'
    resolve identically.
    """
    cleaned = re.sub(r"[^A-Za-z0-9]", "", str(postal_code or "")).upper()
    fsa = cleaned[:3]
    if len(fsa) < 3:
        return None

    cache_key = f"geocode_ca_{fsa}"
    cached = cache.get(cache_key)
    if cached is not None:
        # Cached miss is stored as an empty tuple to avoid re-hitting the API.
        return cached or None

    try:
        resp = requests.get(
            ZIPPOPOTAM_URL.format(fsa=fsa), headers=_HEADERS, timeout=HTTP_TIMEOUT
        )
        resp.raise_for_status()
        places = resp.json().get("places", [])
        if not places:
            cache.set(cache_key, (), GEOCODE_CACHE_TTL)
            return None
        lat = float(places[0]["latitude"])
        lng = float(places[0]["longitude"])
    except (requests.RequestException, ValueError, KeyError, IndexError) as exc:
        logger.warning("Geocode failed for %s: %s", fsa, exc)
        return None

    result = (lat, lng)
    cache.set(cache_key, result, GEOCODE_CACHE_TTL)
    return result


def reverse_geocode(lat, lng):
    """Return a postal code for exact coordinates (from GPS), or None.

    Uses OSM Nominatim reverse geocoding — the fallback for when the mobile
    client couldn't reverse-geocode on-device (e.g. web/desktop). Flipp needs a
    postal code for its regional banner lookup; the exact coordinates still
    drive the map + proximity. Cached per rounded coordinate; None on failure.
    """
    if lat is None or lng is None:
        return None
    cache_key = f"revgeo_{round(lat, 4)}_{round(lng, 4)}"
    cached = cache.get(cache_key)
    if cached is not None:
        return cached or None

    try:
        resp = requests.get(
            NOMINATIM_REVERSE_URL,
            params={"lat": lat, "lon": lng, "format": "json", "addressdetails": 1},
            headers=_HEADERS,
            timeout=HTTP_TIMEOUT,
        )
        resp.raise_for_status()
        postcode = (resp.json().get("address", {}) or {}).get("postcode")
    except (requests.RequestException, ValueError) as exc:
        logger.warning("Reverse geocode failed for %s,%s: %s", lat, lng, exc)
        return None

    if not postcode:
        cache.set(cache_key, "", REVERSE_CACHE_TTL)
        return None
    cache.set(cache_key, postcode, REVERSE_CACHE_TTL)
    return postcode
