"""Resilient Redis cache backend.

Django's built-in RedisCache lets any Redis connection error propagate — and
with no socket timeout a single unreachable Redis makes every `cache.get` hang
until gunicorn kills the worker (WORKER TIMEOUT). That turns a cache dependency
into a hard dependency: if Redis blips, the whole API goes down.

`ResilientRedisCache` degrades gracefully instead: on any Redis error a read
returns the default (a cache miss) and a write is a no-op. The app keeps serving
— uncached and slower, exactly as it did before Redis — rather than 500-ing or
timing out. Pair with short socket timeouts in the cache OPTIONS so failures are
fast, not hangs.
"""

import logging

from django.core.cache.backends.base import DEFAULT_TIMEOUT
from django.core.cache.backends.redis import RedisCache

logger = logging.getLogger(__name__)

try:  # Build the set of exceptions that mean "Redis is unavailable".
    import redis

    _REDIS_ERRORS = (redis.RedisError, ConnectionError, TimeoutError, OSError)
except Exception:  # pragma: no cover - redis should be installed in prod
    _REDIS_ERRORS = (ConnectionError, TimeoutError, OSError)


class ResilientRedisCache(RedisCache):
    """RedisCache that treats connection failures as a cache miss / no-op."""

    _warned = False

    def _degraded(self, op, exc):
        # Log the first failure loudly, then stay quiet to avoid log floods
        # while Redis is down.
        if not ResilientRedisCache._warned:
            logger.error("cache %s failed; serving uncached (Redis unavailable): %s", op, exc)
            ResilientRedisCache._warned = True
        else:
            logger.debug("cache %s failed (Redis unavailable): %s", op, exc)

    def get(self, key, default=None, version=None):
        try:
            result = super().get(key, default, version)
            ResilientRedisCache._warned = False
            return result
        except _REDIS_ERRORS as exc:
            self._degraded("get", exc)
            return default

    def set(self, key, value, timeout=DEFAULT_TIMEOUT, version=None):
        try:
            return super().set(key, value, timeout, version)
        except _REDIS_ERRORS as exc:
            self._degraded("set", exc)
            return False

    def add(self, key, value, timeout=DEFAULT_TIMEOUT, version=None):
        try:
            return super().add(key, value, timeout, version)
        except _REDIS_ERRORS as exc:
            # Return False so lock-style callers treat it as "not acquired" and
            # take the safe path rather than assuming they hold a lock.
            self._degraded("add", exc)
            return False

    def delete(self, key, version=None):
        try:
            return super().delete(key, version)
        except _REDIS_ERRORS as exc:
            self._degraded("delete", exc)
            return False

    def touch(self, key, timeout=DEFAULT_TIMEOUT, version=None):
        try:
            return super().touch(key, timeout, version)
        except _REDIS_ERRORS as exc:
            self._degraded("touch", exc)
            return False

    def has_key(self, key, version=None):
        try:
            return super().has_key(key, version)
        except _REDIS_ERRORS as exc:
            self._degraded("has_key", exc)
            return False

    def get_many(self, keys, version=None):
        try:
            return super().get_many(keys, version)
        except _REDIS_ERRORS as exc:
            self._degraded("get_many", exc)
            return {}

    def set_many(self, data, timeout=DEFAULT_TIMEOUT, version=None):
        try:
            return super().set_many(data, timeout, version)
        except _REDIS_ERRORS as exc:
            self._degraded("set_many", exc)
            return list(data)

    def delete_many(self, keys, version=None):
        try:
            return super().delete_many(keys, version)
        except _REDIS_ERRORS as exc:
            self._degraded("delete_many", exc)

    def clear(self):
        try:
            return super().clear()
        except _REDIS_ERRORS as exc:
            self._degraded("clear", exc)
            return False
