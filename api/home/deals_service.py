"""Location-driven grocery-deal aggregation.

Ties together the Flipp banner flyers, OSM store locations, and geocoding to
answer one question: "what are the biggest discounts at the stores nearest me?"

Shared by the home feed's nearby-deals module and the standalone "see all"
endpoint so both aggregate identically.
"""

import logging

from .flipp_client import FlippClient, normalize_postal
from .geocode import geocode_postal_code, reverse_geocode
from .overpass_client import expand_store_locations, nearby_grocery_pois

logger = logging.getLogger(__name__)

DEFAULT_STORE_LIMIT = 5


def resolve_location(lat=None, lng=None, postal=None):
    """Fill in whatever's missing among (lat, lng, postal).

    Prefers exact coordinates (GPS); reverse-geocodes them to a postal code for
    Flipp when needed, or forward-geocodes a postal code's FSA centroid when we
    only have a postal. Returns (lat, lng, postal) with any still-unknown values
    left as None/''.
    """
    postal = normalize_postal(postal) if postal else ''

    if (lat is None or lng is None) and len(postal) >= 3:
        geo = geocode_postal_code(postal)
        if geo is not None:
            lat, lng = geo

    if len(postal) < 6 and lat is not None and lng is not None:
        rev = reverse_geocode(lat, lng)
        if rev:
            postal = normalize_postal(rev)

    return lat, lng, postal


def nearby_stores(postal, lat=None, lng=None, store_limit=DEFAULT_STORE_LIMIT):
    """The `store_limit` closest distinct grocery banners near the location.

    Each returned store is a banner dict (merchant, merchant_id, flyer_id,
    logo_url, valid_to) plus `distance_m` (nearest location) — deduped by banner
    and ordered nearest-first. Falls back to alphabetical banners when there are
    no coordinates.
    """
    if len(postal) < 6:
        return []
    banners = FlippClient().grocery_stores(postal)
    if not banners:
        return []

    if lat is not None and lng is not None:
        pois = nearby_grocery_pois(lat, lng)
        entries = expand_store_locations(banners, pois, center_lat=lat, center_lng=lng)
    else:
        entries = [
            {**b, 'name': b['merchant'], 'lat': None, 'lng': None, 'distance_m': None}
            for b in banners
        ]

    # First occurrence of each banner wins (entries are already nearest-first).
    seen = set()
    stores = []
    for entry in entries:
        mid = entry['merchant_id']
        if mid in seen:
            continue
        seen.add(mid)
        stores.append(entry)
        if len(stores) >= store_limit:
            break
    return stores


def stores_by_ids(postal, lat, lng, merchant_ids):
    """Resolve an explicit set of banners (by merchant_id) near the location.

    Used when the user has curated their own store list on the deals page. Each
    returned store is the banner's nearest location (with `distance_m`), in
    nearest-first order. Requested banners with no flyer in this postal area are
    simply omitted.
    """
    if len(postal) < 6 or not merchant_ids:
        return []
    wanted = set(merchant_ids)
    banners = FlippClient().grocery_stores(postal)
    if not banners:
        return []

    if lat is not None and lng is not None:
        pois = nearby_grocery_pois(lat, lng)
        entries = expand_store_locations(banners, pois, center_lat=lat, center_lng=lng)
    else:
        entries = [
            {**b, 'name': b['merchant'], 'lat': None, 'lng': None, 'distance_m': None}
            for b in banners
        ]

    seen = set()
    stores = []
    for entry in entries:
        mid = entry['merchant_id']
        if mid in wanted and mid not in seen:
            seen.add(mid)
            stores.append(entry)
    return stores


def deal_savings(price_value, discount):
    """Absolute dollar savings, derived from the sale price + discount %.

    sale = regular * (1 - d/100)  =>  regular = sale / (1 - d/100),
    so savings = regular - sale. Returns None when it can't be computed
    (missing price/discount, or a nonsensical discount outside 0<d<100).
    """
    if price_value is None or discount is None or discount <= 0 or discount >= 100:
        return None
    regular = price_value / (1 - discount / 100.0)
    return round(regular - price_value, 2)


def _rank_key(item):
    """Rank by biggest dollar savings first; items with no computable savings
    fall to the end, tie-broken by deepest % then lowest price."""
    savings = item.get('savings')
    price = item.get('price_value')
    return (
        0 if savings is not None else 1,          # savings-bearing items first
        -(savings if savings is not None else 0),  # biggest savings first
        -(item.get('discount') or 0),              # then deepest percentage
        price if price is not None else float('inf'),
    )


def aggregate_deals(stores):
    """Every flyer item across `stores`, tagged with store + distance + savings,
    ranked by biggest dollar savings first.

    Each item keeps its `merchant` (set by FlippClient) and gains `distance_m`
    (from its store) and `savings` (derived dollar amount, or None).
    """
    items = []
    client = FlippClient()
    for store in stores:
        for item in client.flyer_items(store['flyer_id'], merchant=store['merchant']):
            tagged = dict(item)
            tagged['distance_m'] = store.get('distance_m')
            tagged['savings'] = deal_savings(item.get('price_value'), item.get('discount'))
            items.append(tagged)

    items.sort(key=_rank_key)
    return items
