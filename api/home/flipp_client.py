"""Client for Flipp's (Wishabi) undocumented public flyer backend.

Flipp aggregates the weekly flyers for most Canadian grocery chains (Metro,
IGA, Maxi, Super C, Adonis, Provigo, ...). This client wraps two endpoints of
its web backend:

    GET /flipp/flyers?postal_code=...        -> flyers near a postal code
    GET /flipp/flyers/{flyer_id}             -> items (with prices) in a flyer

It powers the "nearby grocery deals" home-feed module and the store finder.

Caveats this module deliberately absorbs so callers stay simple:
  * The API is undocumented and unauthenticated — it can change without notice.
    Every network call degrades to an empty result (never raises) so the home
    feed never 500s because Flipp hiccuped.
  * Responses are cached (Django cache) per postal code / flyer for a few hours
    because flyers only change weekly — see FLYERS_CACHE_TTL / ITEMS_CACHE_TTL.
    NOTE: the project's Django cache is LocMem (per-process), so this cache is
    per-worker, not shared. Good enough to spare Flipp on repeat views; revisit
    if we move to Redis for the Django cache.
  * Prices arrive as free-text strings ("$1.99", "2/$5.00", "") — `_parse_price`
    turns them into a float where possible and leaves the raw string for display.

Modelled on recipes/usda_api.py (requests + timeout + raise_for_status) with a
cache layer modelled on recommendations/api.py.
"""

import logging
import re

import requests
from django.core.cache import cache

logger = logging.getLogger(__name__)

FLIPP_BASE_URL = "https://backflipp.wishabi.com/flipp"
FLIPP_LOCALE = "en-ca"
GROCERY_CATEGORY = "Groceries"
HTTP_TIMEOUT = 10  # seconds

# Flyers change weekly; cache generously to spare the upstream and stay snappy.
FLYERS_CACHE_TTL = 6 * 60 * 60  # 6 hours
ITEMS_CACHE_TTL = 6 * 60 * 60  # 6 hours

# Flipp 403s empty/curl-style User-Agents; present as a normal browser.
_HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
        "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"
    ),
}


def normalize_postal(postal_code):
    """Uppercase and strip spaces. Flipp accepts 'H2X1Y4', not 'H2X 1Y4'."""
    return re.sub(r"\s+", "", str(postal_code or "")).upper()


def _parse_price(raw):
    """Best-effort parse of a Flipp price string into a float.

    Handles '$1.99', '1.99', '2/$5.00' and '2 for $5' (returns unit price for
    multi-buys). Returns None when there's no machine-readable price (many
    items put the price only on the flyer image).
    """
    if not raw:
        return None
    s = str(raw).strip()
    # Multi-buy: "2/$5.00", "2 for $5" -> per-unit price.
    m = re.search(r"(\d+)\s*(?:/|for)\s*\$?\s*(\d+(?:[.,]\d{1,2})?)", s, re.IGNORECASE)
    if m:
        qty = int(m.group(1))
        total = float(m.group(2).replace(",", "."))
        return round(total / qty, 2) if qty else None
    m = re.search(r"(\d+(?:[.,]\d{1,2})?)", s)
    if m:
        return float(m.group(1).replace(",", "."))
    return None


def _clean_name(raw):
    """Flipp names in QC are bilingual: 'FRAISES | STRAWBERRIES'.

    Return (display, alt) where display is the first segment and alt the second
    (or None). We keep both so the UI can show one and fall back to the other.
    """
    text = (raw or "").strip()
    if "|" in text:
        parts = [p.strip() for p in text.split("|") if p.strip()]
        if len(parts) >= 2:
            return parts[0], parts[1]
        if parts:
            return parts[0], None
    return text, None


def _select_grocery_stores(flyers):
    """Filter flyers to grocery merchants and dedupe by merchant.

    A postal code often returns the same merchant several times (multiple store
    locations / overlapping runs). We keep one flyer per merchant_id, preferring
    the one that ends soonest — the current *weekly* flyer rather than a
    long-running evergreen one.
    """
    by_merchant = {}
    for f in flyers:
        categories = f.get("categories") or []
        if GROCERY_CATEGORY not in categories:
            continue
        merchant_id = f.get("merchant_id")
        if merchant_id is None:
            continue
        store = {
            "merchant": f.get("merchant") or "",
            "merchant_id": merchant_id,
            "flyer_id": f.get("id"),
            "logo_url": f.get("merchant_logo") or None,
            "valid_from": f.get("valid_from"),
            "valid_to": f.get("valid_to"),
        }
        existing = by_merchant.get(merchant_id)
        if existing is None or _ends_before(store["valid_to"], existing["valid_to"]):
            by_merchant[merchant_id] = store
    return sorted(by_merchant.values(), key=lambda s: s["merchant"].lower())


def _ends_before(a, b):
    """True if ISO date-time string `a` ends strictly before `b`. None sorts last."""
    if a is None:
        return False
    if b is None:
        return True
    return a < b


def _parse_item(item, flyer_id, merchant):
    """Normalize one Flipp flyer item into our deal shape."""
    display, alt = _clean_name(item.get("name"))
    if not display:
        return None
    raw_price = item.get("price")
    return {
        "name": display,
        "name_alt": alt,
        "brand": item.get("brand") or "",
        "price": raw_price or None,  # original string for display
        "price_value": _parse_price(raw_price),  # float for sorting, or None
        "discount": item.get("discount"),  # percent int, or None
        "image_url": item.get("cutout_image_url") or None,
        "valid_from": item.get("valid_from"),
        "valid_to": item.get("valid_to"),
        "merchant": merchant,
        "flyer_id": flyer_id,
    }


class FlippClient:
    """Thin, cache-backed wrapper over the Flipp flyer backend."""

    def __init__(self, locale=FLIPP_LOCALE):
        self.locale = locale

    def _get(self, path, params=None):
        url = f"{FLIPP_BASE_URL}/{path}"
        query = {"locale": self.locale}
        if params:
            query.update(params)
        response = requests.get(url, params=query, headers=_HEADERS, timeout=HTTP_TIMEOUT)
        response.raise_for_status()
        return response.json()

    def grocery_stores(self, postal_code):
        """Grocery flyers near a postal code, deduped by merchant, sorted by name.

        Returns a list of store dicts (see `_select_grocery_stores`). Empty list
        on any failure or unknown postal code.
        """
        postal = normalize_postal(postal_code)
        if not postal:
            return []
        cache_key = f"flipp_stores_{self.locale}_{postal}"
        cached = cache.get(cache_key)
        if cached is not None:
            return cached
        try:
            data = self._get("flyers", {"postal_code": postal})
        except (requests.RequestException, ValueError) as exc:
            logger.warning("Flipp flyers fetch failed for %s: %s", postal, exc)
            return []
        flyers = data if isinstance(data, list) else data.get("flyers", [])
        stores = _select_grocery_stores(flyers)
        cache.set(cache_key, stores, FLYERS_CACHE_TTL)
        return stores

    def find_flyer_for_merchant(self, postal_code, merchant_id):
        """Resolve the current weekly flyer for a merchant near a postal code.

        We persist merchant_id (stable) rather than flyer_id (changes weekly),
        so this re-resolves the live flyer each week. Returns a store dict or
        None.
        """
        for store in self.grocery_stores(postal_code):
            if store["merchant_id"] == merchant_id:
                return store
        return None

    def flyer_items(self, flyer_id, merchant=""):
        """All parsed items for a flyer. Empty list on failure."""
        if not flyer_id:
            return []
        cache_key = f"flipp_items_{flyer_id}"
        cached = cache.get(cache_key)
        if cached is not None:
            return cached
        try:
            data = self._get(f"flyers/{flyer_id}")
        except (requests.RequestException, ValueError) as exc:
            logger.warning("Flipp items fetch failed for flyer %s: %s", flyer_id, exc)
            return []
        raw_items = data.get("items", []) if isinstance(data, dict) else []
        items = [it for it in (_parse_item(i, flyer_id, merchant) for i in raw_items) if it]
        cache.set(cache_key, items, ITEMS_CACHE_TTL)
        return items

    def store_deals(self, postal_code, merchant_id, limit=None):
        """Convenience: resolve a merchant's current flyer and return its items,
        sorted by discount (deepest first), then by lowest price."""
        store = self.find_flyer_for_merchant(postal_code, merchant_id)
        if not store:
            return []
        items = self.flyer_items(store["flyer_id"], merchant=store["merchant"])
        items.sort(
            key=lambda it: (
                -(it["discount"] or 0),
                it["price_value"] if it["price_value"] is not None else float("inf"),
            )
        )
        return items[:limit] if limit else items
