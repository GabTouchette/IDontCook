"""Background tasks for the home feed.

The home feed request path must never block on external I/O. `collect_deals`
(home/collectors.py) reads a warmed cache entry and, on a miss, enqueues
`warm_deals_cache` to populate it out-of-band — so a slow OSM Overpass (25s
timeout) or Flipp call can never hang the feed. The deals rail simply appears on
the next feed load once the cache is warm.
"""

import logging
import os
import threading

from celery import shared_task
from django.core.cache import cache

from .deals_service import (
    DEALS_CACHE_TTL,
    DEALS_LOCK_TTL,
    DEFAULT_STORE_LIMIT,
    compute_deals_rail,
    deals_cache_key,
)

logger = logging.getLogger(__name__)

# Cached when a location resolves to no deals, so we return "no rail" fast and
# don't re-warm the same empty location on every feed load until the TTL lapses.
_EMPTY = {'state': 'empty'}


@shared_task
def warm_deals_cache(cache_key, lat, lng, postal, store_limit=DEFAULT_STORE_LIMIT):
    """Compute the deals rail for a location and write it to the shared cache.

    Idempotent and self-guarding: writes the ready payload on success, or an
    empty marker when the location yields nothing, then releases the in-flight
    lock. Never raises into the caller.
    """
    lock_key = cache_key + '_lock'
    try:
        payload = compute_deals_rail(lat, lng, postal, store_limit=store_limit)
        cache.set(cache_key, payload or _EMPTY, DEALS_CACHE_TTL)
        logger.info(
            "home deals warm: %s -> %s",
            cache_key,
            'ready' if payload else 'empty',
        )
    except Exception:
        # Leave the cache cold so a later feed load retries; log for visibility.
        logger.exception("home deals warm failed for %s", cache_key)
    finally:
        cache.delete(lock_key)


# Whether a dedicated Celery worker is deployed to consume warm_deals_cache.
# The Coolify prod service runs gunicorn ONLY — there is no separate Celery worker
# process — so with a healthy broker, `.delay()` would enqueue a task nothing ever
# runs and the rail would hang on `loading` forever.
# Default to running the warm in an in-process daemon thread (bounded ~6s work,
# deduped by the Redis lock, out of the request path). Set DEALS_WARM_USE_CELERY=
# true only once a real Celery worker is actually running.
_USE_CELERY_FOR_DEALS = os.getenv('DEALS_WARM_USE_CELERY', 'false').lower() in (
    '1', 'true', 'yes',
)


def dispatch_deals_warm(cache_key, lat, lng, postal, store_limit=DEFAULT_STORE_LIMIT):
    """Kick off a single background warm for this location (deduped by a lock).

    Runs the warm in an in-process daemon thread by default so it executes even
    without a Celery worker deployed (the prod case). When DEALS_WARM_USE_CELERY
    is set, queues on Celery instead, falling back to a thread if the broker is
    unavailable. A no-op when a warm for this location is already in flight.
    """
    lock_key = cache_key + '_lock'
    # cache.add is atomic on Redis: only the first caller acquires the lock.
    if not cache.add(lock_key, 1, DEALS_LOCK_TTL):
        return

    args = (cache_key, lat, lng, postal, store_limit)

    if _USE_CELERY_FOR_DEALS:
        try:
            warm_deals_cache.delay(*args)
            return
        except Exception as exc:
            logger.warning(
                "Celery dispatch failed for deals warm (%s); running in a thread", exc
            )

    # Default path (and broker-down fallback): run the warm inline in a daemon
    # thread. The request already returned the `loading` placeholder, so this
    # never blocks the feed; the client polls until the cache flips to `ready`.
    logger.info("home deals warm: starting inline thread for %s", cache_key)
    threading.Thread(target=warm_deals_cache, args=args, daemon=True).start()
