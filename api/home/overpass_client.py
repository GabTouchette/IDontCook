"""Nearby grocery-store locations from OpenStreetMap via the Overpass API.

Flipp tells us *which* merchants have a weekly flyer near a postal code, but not
*where* their stores are (no address/coordinates). To place stores on a map we
pull grocery POIs (name + lat/lng) from OSM around a point and match them to the
Flipp merchants by name (see `match_stores_to_pois`).

Free and keyless, but a shared community resource — so results are cached
aggressively (store locations barely change) and every failure degrades to an
empty list (the store list still works without a map).
"""

import logging
import re
import unicodedata

import requests
from django.core.cache import cache

logger = logging.getLogger(__name__)

OVERPASS_URL = "https://overpass-api.de/api/interpreter"
# Capped well under a gunicorn worker timeout: this call only ever runs in the
# background warm path now (never a request), but a wedged Overpass should still
# fail fast so the warm thread doesn't linger. The query itself asks for
# [timeout:20] below.
HTTP_TIMEOUT = 12  # seconds
POIS_CACHE_TTL = 24 * 60 * 60  # 1 day — store locations rarely move
DEFAULT_RADIUS_M = 6000  # wide enough to catch multiple locations per chain

_HEADERS = {"User-Agent": "ICantCook/1.0 (recipe app store finder)"}

# Generic words dropped before token-matching a store name to a POI name, so
# "Avril Supermarché Santé" still matches an OSM "Avril", and "Les Marchés
# Tradition" matches "... Marchés Tradition". Keep this conservative — dropping
# too much causes false matches.
_STOPWORDS = {
    "marche", "marches", "super", "supermarche", "supermarches", "epicerie",
    "market", "supermarket", "grocery", "le", "la", "les", "du", "de", "des",
    "et", "extra", "plus", "sante", "express", "food", "foods", "inc", "ltee",
    "ltd", "co", "magasin", "store",
}


def _strip_accents(text):
    return "".join(
        c for c in unicodedata.normalize("NFKD", text) if not unicodedata.combining(c)
    )


def _normalize(name):
    """Lowercase, de-accent, keep alphanumerics + spaces, collapse whitespace."""
    text = _strip_accents(str(name or "")).lower()
    text = re.sub(r"[^a-z0-9]+", " ", text)
    return re.sub(r"\s+", " ", text).strip()


def _tokens(normalized):
    return {t for t in normalized.split() if len(t) >= 3 and t not in _STOPWORDS}


def names_match(store_name, poi_name):
    """Heuristic: does an OSM POI name refer to the same chain as a store name?

    True when either normalized name contains the other (e.g. "IGA" ⊂ "IGA
    Marché Verreault"), or they share a significant token (e.g. both contain
    "tradition"). Conservative token filtering keeps false positives low.
    """
    a = _normalize(store_name)
    b = _normalize(poi_name)
    if not a or not b:
        return False
    if a in b or b in a:
        return True
    return bool(_tokens(a) & _tokens(b))


def _haversine_m(lat1, lng1, lat2, lng2):
    """Great-circle distance in metres (small helper, no external deps)."""
    from math import asin, cos, radians, sin, sqrt

    r = 6371000.0
    d_lat = radians(lat2 - lat1)
    d_lng = radians(lng2 - lng1)
    h = sin(d_lat / 2) ** 2 + cos(radians(lat1)) * cos(radians(lat2)) * sin(d_lng / 2) ** 2
    return 2 * r * asin(sqrt(h))


def nearby_grocery_pois(lat, lng, radius_m=DEFAULT_RADIUS_M, allow_network=True):
    """Grocery POIs (supermarkets + groceries) within `radius_m` of a point.

    Returns a list of {name, lat, lng}. Cached per rounded coordinate + radius.
    Empty list on any failure.

    `allow_network=False` makes this cache-only: a cache miss returns [] WITHOUT
    ever calling Overpass. Request-path callers pass False so a slow/throttled
    overpass-api.de (seen taking ~25s) can never block a user request — the
    distance ranking just degrades until the background warm populates the cache.
    Only the background warm (home.tasks / warm_deals command) calls with
    network enabled.
    """
    if lat is None or lng is None:
        return []
    # Round the cache key so nearby requests share a cached result.
    cache_key = f"overpass_grocery_{round(lat, 3)}_{round(lng, 3)}_{radius_m}"
    cached = cache.get(cache_key)
    if cached is not None:
        return cached
    if not allow_network:
        return []

    query = (
        "[out:json][timeout:20];"
        "("
        f"node[shop=supermarket](around:{radius_m},{lat},{lng});"
        f"way[shop=supermarket](around:{radius_m},{lat},{lng});"
        f"node[shop=grocery](around:{radius_m},{lat},{lng});"
        f"way[shop=grocery](around:{radius_m},{lat},{lng});"
        ");"
        "out center 300;"
    )
    try:
        resp = requests.post(
            OVERPASS_URL, data={"data": query}, headers=_HEADERS, timeout=HTTP_TIMEOUT
        )
        resp.raise_for_status()
        elements = resp.json().get("elements", [])
    except (requests.RequestException, ValueError) as exc:
        logger.warning("Overpass fetch failed for %s,%s: %s", lat, lng, exc)
        return []

    pois = []
    for el in elements:
        tags = el.get("tags", {})
        name = tags.get("name") or tags.get("brand")
        if not name:
            continue
        # Nodes carry lat/lon directly; ways/relations carry a `center`.
        plat = el.get("lat") or (el.get("center") or {}).get("lat")
        plng = el.get("lon") or (el.get("center") or {}).get("lon")
        if plat is None or plng is None:
            continue
        pois.append({"name": name, "lat": plat, "lng": plng})

    cache.set(cache_key, pois, POIS_CACHE_TTL)
    return pois


def expand_store_locations(banners, pois, center_lat=None, center_lng=None,
                           per_banner_cap=8):
    """Expand Flipp banners into physical store locations from OSM POIs.

    Flipp exposes one flyer per merchant *banner* per region; OSM has the many
    physical *locations* of that banner. We attach every nearby matching POI as
    its own selectable entry (same flyer/deals, different location), so the user
    sees e.g. several Metros ranked by distance rather than a single one.

    Each returned entry is a copy of the banner dict plus `name` (the OSM
    location name, which may be more specific than the banner — e.g. "Metro
    Marcano"), `lat`, `lng`, and `distance_m` (from `center`). Banners with no
    matched POI still appear once (deals selectable, no map pin). The list is
    sorted by proximity, unlocated banners last.
    """
    entries = []
    for banner in banners:
        matches = [p for p in pois if names_match(banner["merchant"], p["name"])]

        # Overpass returns a node *and* a way for the same store — dedupe by a
        # coarse coordinate key so one physical store yields one entry.
        seen = set()
        deduped = []
        for p in matches:
            key = (round(p["lat"], 4), round(p["lng"], 4))
            if key in seen:
                continue
            seen.add(key)
            deduped.append(p)

        if center_lat is not None and center_lng is not None:
            deduped.sort(
                key=lambda p: _haversine_m(center_lat, center_lng, p["lat"], p["lng"])
            )

        if not deduped:
            entries.append({
                **banner, "name": banner["merchant"],
                "lat": None, "lng": None, "distance_m": None,
            })
            continue

        for p in deduped[:per_banner_cap]:
            dist = None
            if center_lat is not None and center_lng is not None:
                dist = round(_haversine_m(center_lat, center_lng, p["lat"], p["lng"]))
            entries.append({
                **banner,
                "name": p["name"] or banner["merchant"],
                "lat": p["lat"],
                "lng": p["lng"],
                "distance_m": dist,
            })

    # Nearest first; banners with no location fall to the end (alphabetical).
    entries.sort(key=lambda e: (
        0 if e["distance_m"] is not None else 1,
        e["distance_m"] if e["distance_m"] is not None else 0,
        e["merchant"].lower(),
    ))
    return entries
