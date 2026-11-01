"""Pre-warm the grocery-deals cache for every active user location.

The deals pipeline (Flipp flyers + OSM Overpass POIs + geocoding) is slow on a
cold cache — the "See all deals" endpoint and the home-feed rail both read a
shared cache that this command fills ahead of time, so a user never pays the
cold cost in the request path. Run it on a schedule (Coolify scheduled task /
cron) a few times a day; flyers only change weekly so a few hours of staleness
is fine.

    python manage.py warm_deals                # all distinct user locations
    python manage.py warm_deals --limit 50     # cap work per run
    python manage.py warm_deals --postal H2X1Y4 --lat 45.5088 --lng -73.5878

Writes the rail payload under deals_cache_key(...) and, as a side effect,
populates the shared Flipp-items, Overpass-POI and geocode caches that the
See-all endpoint also reads. Requires a SHARED cache backend (Redis) to help
other gunicorn workers — with per-process LocMem each worker stays cold.
"""

import logging

from django.core.cache import cache
from django.core.management.base import BaseCommand

from accounts.models import UserSettings
from home.deals_service import (
    DEALS_CACHE_TTL,
    DEFAULT_STORE_LIMIT,
    compute_deals_rail,
    deals_cache_key,
)

logger = logging.getLogger(__name__)

_EMPTY = {'state': 'empty'}


class Command(BaseCommand):
    help = "Pre-warm the grocery-deals cache for active user locations."

    def add_arguments(self, parser):
        parser.add_argument('--limit', type=int, default=None,
                            help='Max distinct locations to warm this run.')
        parser.add_argument('--store-limit', type=int, default=DEFAULT_STORE_LIMIT,
                            help='Stores aggregated per location (default 5).')
        parser.add_argument('--postal', type=str, default=None,
                            help='Warm a single explicit location (with --lat/--lng).')
        parser.add_argument('--lat', type=float, default=None)
        parser.add_argument('--lng', type=float, default=None)

    def handle(self, *args, **opts):
        store_limit = opts['store_limit']

        if opts['postal'] or (opts['lat'] is not None and opts['lng'] is not None):
            locations = [(opts['lat'], opts['lng'], opts['postal'] or '')]
        else:
            locations = self._distinct_locations(limit=opts['limit'])

        if not locations:
            self.stdout.write("No user locations to warm.")
            return

        warmed = empty = failed = 0
        for lat, lng, postal in locations:
            key = deals_cache_key(lat, lng, postal)
            try:
                payload = compute_deals_rail(lat, lng, postal, store_limit=store_limit)
            except Exception:
                failed += 1
                logger.exception("warm_deals failed for %s", key)
                continue
            cache.set(key, payload or _EMPTY, DEALS_CACHE_TTL)
            if payload:
                warmed += 1
                self.stdout.write(self.style.SUCCESS(
                    f"ready  {key}  ({payload.get('total_count', 0)} items)"
                ))
            else:
                empty += 1
                self.stdout.write(f"empty  {key}")

        self.stdout.write(self.style.SUCCESS(
            f"Done. warmed={warmed} empty={empty} failed={failed} "
            f"of {len(locations)} location(s)."
        ))

    @staticmethod
    def _distinct_locations(limit=None):
        """Distinct (lat, lng, postal) across all users with any location signal.

        Coordinates are rounded to ~110m so users on the same block share one
        warm — the exact grid deals_cache_key rounds to. A usable signal is
        either coordinates or a postal with at least an FSA (3 chars).
        """
        rows = (
            UserSettings.objects
            .exclude(latitude__isnull=True, longitude__isnull=True, postal_code='')
            .values_list('latitude', 'longitude', 'postal_code')
        )
        seen = set()
        out = []
        for lat, lng, postal in rows:
            postal = (postal or '').strip()
            has_coords = lat is not None and lng is not None
            if not has_coords and len(postal) < 3:
                continue
            dedupe_key = (
                round(lat, 3) if lat is not None else None,
                round(lng, 3) if lng is not None else None,
                postal.upper().replace(' ', ''),
            )
            if dedupe_key in seen:
                continue
            seen.add(dedupe_key)
            out.append((lat, lng, postal))
            if limit and len(out) >= limit:
                break
        return out
