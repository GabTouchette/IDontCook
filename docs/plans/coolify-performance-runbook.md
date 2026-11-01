# Coolify backend performance runbook

Context: the backend now runs on a self-hosted Mac mini via Coolify
(`api.idontcook.app`). A benchmark (2026-10-31) found two problems that make the
explore page and grocery deals slow, plus one migration gap. This runbook covers
the fixes. Code changes for the deals request path and the two warm commands are
already in the repo; the steps below are the infra/ops side you run on Coolify.

## TL;DR of what was wrong

| Symptom | Root cause |
|---|---|
| `/api/home/deals/` = ~26 s **every** call | OSM Overpass (25 s timeout) ran **inline** in the request; public endpoint throttles → empty POIs, alphabetical stores, 26 s |
| Deals rail flickers `loading ⇄ ready`; caches never warm | **No Redis on Coolify** → Django cache falls back to per-process `LocMemCache`, split across the 2 gunicorn workers |
| Explore "fast" but empty | Railway catalog (thousands of recipes) **not migrated** to Coolify |

The empty catalog hid the real explore cost: scoring the whole catalog by cosine
similarity grows with recipe count, so explore gets slow once the data is back —
which is why the shared cache + precompute below matter.

---

## 1. Provision Redis on Coolify (highest impact, config only)

`api/settings.py` switches the Django cache to `ResilientRedisCache` automatically
**only when `ENVIRONMENT=production`** AND a Redis URL is present — the Redis
branch is gated on `IS_PRODUCTION` (settings ~L328). Without both, every cache
(recommendation profiles, deal aggregates, Flipp/OSM/geocode) falls back to
per-worker LocMem and stays cold, which defeats everything else here.

> The live app was found running in **development mode** (no HSTS / no HTTPS
> redirect) — that's why the cache was LocMem even with 2 workers. Fixing this
> means flipping to production, which also turns off `DEBUG`.

1. In Coolify, add a **Redis** service (one-click resource) in the same project;
   copy its connection URL (`redis://default:<pw>@<host>:6379`).
2. On the **backend** service, set these env vars. The ones marked *(required)*
   will stop the app from booting if missing once `ENVIRONMENT=production`:
   ```
   ENVIRONMENT=production                         # (required) engages Redis + disables DEBUG
   DJANGO_SECRET_KEY=<long random secret>         # (required) must be set when DEBUG=false
   ALLOWED_HOSTS=api.idontcook.app                # (required) else ALLOWED_HOSTS is empty -> crash
   REDIS_URL=redis://default:<pw>@<host>:6379/0   # the Django cache
   CELERY_BROKER_URL=redis://default:<pw>@<host>:6379/0      # (required in prod)
   CELERY_RESULT_BACKEND=redis://default:<pw>@<host>:6379/0  # (required in prod)
   # If a Flutter WEB client exists (DEBUG=false restricts CORS):
   CORS_ALLOWED_ORIGINS=https://<web-domain>
   CSRF_TRUSTED_ORIGINS=https://<web-domain>,https://api.idontcook.app
   ```
   (`DATABASE_URL` and the GCS creds are already set — leave them. The cache URL
   resolves from `REDIS_PUBLIC_URL` → `REDIS_URL` → `CELERY_BROKER_URL`.)
3. Redeploy the backend.

Watch-outs after the flip:
- **Redirect loop:** `SECURE_SSL_REDIRECT` turns on. Behind Cloudflare, use SSL
  mode **Full** so `X-Forwarded-Proto: https` reaches the app (settings already
  trusts it via `SECURE_PROXY_SSL_HEADER`). Escape hatch if it loops:
  `SECURE_SSL_REDIRECT=false`.
- **Secret key:** mobile logins survive (DRF tokens are DB rows); only Django
  admin sessions reset.

**Verify it took:**
- `curl -sI https://api.idontcook.app/api/recipes/ | grep -i strict-transport` —
  an HSTS header means production mode is live (and DEBUG is off).
- Hit the home feed a few times in a row; the deals rail should stay `ready`
  instead of alternating `ready/loading` = the Redis cache is shared. Or from a
  shell on the box:
```bash
python manage.py shell -c "from django.core.cache import cache; cache.set('k',1,30); print(cache.get('k'))"
```
Escape hatch: `DISABLE_REDIS_CACHE=true` forces LocMem back without a deploy.

---

## 2. Scheduled pre-warm (so users never pay the cold cost)

Two management commands were added. Run them as **Coolify Scheduled Tasks**
(Project → the backend service → Scheduled Tasks), pointed at the container.

### Deals — a few times a day (flyers change weekly)
```
python manage.py warm_deals
```
Warms the deals cache for every distinct user location (dedup to ~110 m grid).
Suggested cron: `0 */4 * * *` (every 4 h). Options: `--limit N`, `--store-limit N`,
or `--postal/--lat/--lng` for a single location.

### Recommendations — nightly, after any vector rebuild
```
python manage.py warm_recommendations --rebuild-vectors
```
Refits the TF-IDF vectors, warms global trending, then precomputes each active
user's explore pool. Suggested cron: `30 3 * * *` (03:30). Options:
`--active-days N` (default 45), `--limit N`, drop `--rebuild-vectors` to only warm.

> Needs Redis (#1) to be useful — otherwise the warm lands in one worker's memory.

Cache TTLs are env-tunable (defaults are already precompute-friendly and safe
because the caches are busted explicitly on every vote/signal change):
```
REC_PROFILE_CACHE_TTL=21600     # 6h   (user taste profile)
REC_SIMILAR_CACHE_TTL=86400     # 24h  (ranked explore pool — the expensive one)
REC_TRENDING_CACHE_TTL=3600     # 1h   (global trending)
```

---

## 3. Deals request path is now Overpass-free (already in code)

`DealsListView`, `StoreSearchView` and the service layer now read OSM POIs from
the **cache only** (`allow_network=False`); a cold POI cache triggers a
background warm and the request returns immediately (stores just lack distance
ranking until the warm lands). Overpass (and its 25 s) runs **only** in the
background warm / `warm_deals`. Overpass `HTTP_TIMEOUT` lowered 25 → 12 s.
`/api/home/deals/` also accepts an optional `?limit=N` (default uncapped, so the
existing client contract is unchanged).

Net effect once Redis + `warm_deals` are live: `/api/home/deals/` drops from
~26 s to sub-second on a warm location, and worst case (cold) is the Flipp item
fan-out (~2–5 s), never the 25 s Overpass hang.

---

## 4. Migrate the catalog: Railway → Coolify Postgres

The Coolify DB is empty (`/api/recipes/` → `[]`). Move the Railway data over.
Chosen approach: full dump of the Railway (source) DB restored into the empty
Coolify (target) DB.

```bash
# 1. Dump schema+data from Railway (use a pg client matching the server version).
pg_dump --no-owner --no-acl --format=custom \
  "$RAILWAY_DATABASE_URL" -f railway.dump

# 2. (Target is empty) restore into Coolify.
pg_restore --no-owner --no-acl --clean --if-exists \
  --dbname "$COOLIFY_DATABASE_URL" railway.dump

# 3. Apply any newer migrations on top, then sanity-check counts.
python manage.py migrate
python manage.py shell -c "from recipes.models import Recipe; print('recipes:', Recipe.objects.count())"
```

Caveats:
- **Client version must match the Railway server major version** (local `pg_dump`
  here is v14; Railway is likely 15/16). Use `railway run pg_dump …`, a matching
  Homebrew `postgresql@NN`, or a one-off Docker `postgres:NN` image.
- After migration, run `warm_recommendations --rebuild-vectors` so the TF-IDF
  vectors exist for the imported catalog, then `warm_deals`.
- Re-benchmark explore with real data to confirm the cache + precompute hold.
