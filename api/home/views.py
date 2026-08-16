import random
import uuid

from django.utils import timezone
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from .collectors import FeedContext, collect_modules
from .deals_service import aggregate_deals, nearby_stores, resolve_location, stores_by_ids
from .flipp_client import FlippClient, normalize_postal
from .geocode import geocode_postal_code, reverse_geocode
from .greetings import get_greeting
from .overpass_client import expand_store_locations, nearby_grocery_pois
from .ranking import MOODS, compute_daypart, rank_modules


class HomeFeedView(APIView):
    """GET /api/home/feed/?local_hour=17&weekday=4&mood=rushed

    Returns the plan §1.5 adaptive home feed. Daypart is computed from the
    client-provided local hour — never the server clock.
    """

    permission_classes = [IsAuthenticated]

    def get(self, request):
        local_hour = self._parse_int(request.query_params.get('local_hour'))
        if local_hour is None or not 0 <= local_hour <= 23:
            return Response(
                {'error': 'local_hour is required and must be an integer between 0 and 23.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        weekday = self._parse_int(request.query_params.get('weekday'))
        if weekday is None or not 0 <= weekday <= 6:
            return Response(
                {'error': 'weekday is required and must be an integer between 0 (Monday) and 6 (Sunday).'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        mood = request.query_params.get('mood') or None
        if mood is not None and mood not in MOODS:
            return Response(
                {'error': f"mood must be one of: {', '.join(MOODS)}."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        daypart = compute_daypart(local_hour)
        is_weekend = weekday in (5, 6)
        now = timezone.now()

        # Optional device location for the nearby-deals module (client GPS).
        lat = self._parse_float(request.query_params.get('lat'))
        lng = self._parse_float(request.query_params.get('lng'))

        # Fresh per-request variety component so refresh / mood re-rank rotate
        # the greeting, prompt, theme and hero pick rather than returning the
        # exact same feed within a day (the day-of-year rotation is the stable
        # base; this is what makes a pull-to-refresh actually feel different).
        ctx = FeedContext(
            user=request.user,
            now=now,
            daypart=daypart,
            is_weekend=is_weekend,
            mood=mood,
            lat=lat,
            lng=lng,
            variety_seed=random.randint(0, 10_000),
        )
        candidates = collect_modules(ctx)
        modules = rank_modules(
            candidates, daypart, is_weekend, mood,
            saved_count=ctx.saved_count,
            # Same per-request seed that rotates copy also jitters ranking, so a
            # refresh reshuffles which sections surface — not just their wording.
            variety_seed=ctx.variety_seed,
        )

        greeting = get_greeting(daypart, mood, seed=ctx.copy_seed)
        blocks = [{'block_type': 'text', 'text': greeting}]
        blocks.extend({'block_type': 'module', 'module': module} for module in modules)

        return Response({
            'feed_id': str(uuid.uuid4()),
            'context': {'daypart': daypart, 'is_weekend': is_weekend, 'mood': mood},
            'greeting': greeting,
            'blocks': blocks,
        })

    @staticmethod
    def _parse_int(value):
        if value is None:
            return None
        try:
            return int(value)
        except (TypeError, ValueError):
            return None

    @staticmethod
    def _parse_float(value):
        if value is None:
            return None
        try:
            return float(value)
        except (TypeError, ValueError):
            return None


class StoreSearchView(APIView):
    """GET /api/home/stores/?postal_code=H2X1Y4[&lat=45.5&lng=-73.56]

    Returns grocery stores with an active weekly flyer near the given postal
    code, deduped by merchant. Drives the store-finder UI so a user can pick
    their Metro / IGA / etc. Postal code is required; results come from Flipp.

    The postal code is geocoded server-side (FSA centroid) so each store is
    enriched with a `lat`/`lng` from the nearest matching OSM grocery POI for a
    map, and `center` is returned — no on-device geocoding needed, so the map
    works on web and mobile alike. `lat`/`lng` query params override the
    geocode (e.g. a future "use my location" GPS flow).
    """

    permission_classes = [IsAuthenticated]

    def get(self, request):
        postal = normalize_postal(request.query_params.get('postal_code'))
        lat = self._parse_float(request.query_params.get('lat'))
        lng = self._parse_float(request.query_params.get('lng'))
        have_coords = lat is not None and lng is not None

        # Need a postal code (for Flipp) OR coordinates (which we reverse-geocode
        # to a postal code server-side — the fallback when the device couldn't).
        if len(postal) < 6 and not have_coords:
            return Response(
                {'error': 'Provide postal_code (e.g. H2X1Y4) or lat/lng.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        if len(postal) < 6 and have_coords:
            resolved = reverse_geocode(lat, lng)
            if resolved:
                postal = normalize_postal(resolved)

        center = {'lat': lat, 'lng': lng} if have_coords else None

        # Couldn't resolve a postal code from the coordinates — no Flipp banners,
        # but still return the center so the client can show the map/empty state.
        if len(postal) < 6:
            return Response({'postal_code': postal, 'center': center, 'stores': []})

        stores = FlippClient().grocery_stores(postal)

        # No GPS coords → geocode the postal code's FSA centroid for the map.
        if not have_coords:
            geo = geocode_postal_code(postal)
            if geo is not None:
                lat, lng = geo
                center = {'lat': lat, 'lng': lng}

        if lat is not None and lng is not None:
            pois = nearby_grocery_pois(lat, lng)
            # Expand each banner into its nearby physical locations (multiple
            # Metros/IGAs), ranked by proximity.
            stores = expand_store_locations(stores, pois, center_lat=lat, center_lng=lng)

        return Response({'postal_code': postal, 'center': center, 'stores': stores})

    @staticmethod
    def _parse_float(value):
        if value is None:
            return None
        try:
            return float(value)
        except (TypeError, ValueError):
            return None


class DealsListView(APIView):
    """GET /api/home/deals/  — the full "See all deals" list.

    The biggest discounts pooled from the user's nearest stores (same model as
    the home rail, just uncapped). Location comes from `lat`/`lng` query params,
    else the user's persisted settings; deepest discount first, each item tagged
    with its store + distance.

    `merchant_ids` (comma-separated) aggregates exactly that curated set of
    banners instead of the nearest ones — used by the deals page's store filter.
    """

    SEE_ALL_STORE_LIMIT = 5

    permission_classes = [IsAuthenticated]

    def get(self, request):
        settings = getattr(request.user, 'settings', None)
        lat = self._parse_float(request.query_params.get('lat'))
        lng = self._parse_float(request.query_params.get('lng'))
        if lat is None or lng is None:
            lat = getattr(settings, 'latitude', None)
            lng = getattr(settings, 'longitude', None)
        postal = normalize_postal(
            request.query_params.get('postal_code')
            or getattr(settings, 'postal_code', '')
        )

        lat, lng, postal = resolve_location(lat=lat, lng=lng, postal=postal)
        center = {'lat': lat, 'lng': lng} if (lat is not None and lng is not None) else None

        if len(postal) < 6:
            return Response({
                'postal_code': postal, 'center': center,
                'stores': [], 'total_count': 0, 'items': [],
            })

        merchant_ids = self._parse_int_list(request.query_params.get('merchant_ids'))
        if merchant_ids:
            stores = stores_by_ids(postal, lat, lng, merchant_ids)
        else:
            stores = nearby_stores(postal, lat, lng, store_limit=self.SEE_ALL_STORE_LIMIT)
        items = aggregate_deals(stores)
        return Response({
            'postal_code': postal,
            'center': center,
            'stores': [
                {
                    'merchant': s['merchant'],
                    'merchant_id': s['merchant_id'],
                    'merchant_logo': s.get('logo_url'),
                    'distance_m': s.get('distance_m'),
                }
                for s in stores
            ],
            'total_count': len(items),
            'items': items,
        })

    @staticmethod
    def _parse_int_list(value):
        if not value:
            return []
        ids = []
        for part in value.split(','):
            part = part.strip()
            if part.lstrip('-').isdigit():
                ids.append(int(part))
        return ids

    @staticmethod
    def _parse_float(value):
        if value is None:
            return None
        try:
            return float(value)
        except (TypeError, ValueError):
            return None
