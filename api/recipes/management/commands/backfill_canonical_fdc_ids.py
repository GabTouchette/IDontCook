"""Pin each CanonicalIngredient to one USDA FoodData Central entry.

This is the keystone of "proper ingredients": once a canonical row has a stable
``usda_fdc_id``, nutrition is looked up by that id (not a fragile per-name
search) and ``backfill_canonical_portions`` can pull real gram weights. For each
canonical name this searches USDA, scores the candidates, and stores the best
``fdc_id`` when the score clears ``--min-score`` (weak matches are left unlinked
rather than polluting the catalog with a wrong pin).

    python manage.py backfill_canonical_fdc_ids --only-missing --sleep 0.3
    python manage.py backfill_canonical_fdc_ids --dry-run --limit 20   # preview picks
"""

import re
import time

from django.core.management.base import BaseCommand

from recipes.models import CanonicalIngredient
from recipes.usda_api import USDAClient

# Generic foods live in Foundation / SR Legacy / Survey; branded entries have
# noisy descriptions, so nudge the former ahead on otherwise-equal matches.
_DATA_TYPE_BONUS = {
    "Foundation": 0.10,
    "SR Legacy": 0.08,
    "Survey (FNDDS)": 0.05,
}

_TOKEN_RE = re.compile(r"[a-z]+")


def _stem(tok: str) -> str:
    """Crude singulariser so a name matches USDA's plural descriptions
    ("onion" vs "Onions, raw", "egg" vs "Eggs")."""
    if len(tok) > 3 and tok.endswith("es"):
        return tok[:-2]
    if len(tok) > 3 and tok.endswith("s") and not tok.endswith("ss"):
        return tok[:-1]
    return tok


def _stem_list(text: str):
    return [_stem(t) for t in _TOKEN_RE.findall((text or "").lower())]


def _tokens(text: str) -> set:
    return set(_stem_list(text))


def score_candidate(query: str, description: str, data_type: str = "") -> float:
    """Score how well a USDA entry matches a canonical name (0..~1.2).

    Rewards covering all of the query's words, penalises extra words in the
    description (so "butter" prefers "Butter, salted" over "Butter, with olive
    oil, salted spread"), and — crucially — rewards the query matching the
    description's *head* word, so "onion" picks "Onions, raw" over "Bread,
    onion". Deterministic; unit-tested offline.
    """
    q = _tokens(query)
    desc_list = _stem_list(description)
    d = set(desc_list)
    if not q or not d:
        return 0.0
    inter = q & d
    if not inter:                           # no shared word -> not a match
        return 0.0
    coverage = len(inter) / len(q)          # how much of the query is present
    jaccard = len(inter) / len(q | d)       # penalises description bloat
    subset = 1.0 if q <= d else 0.0         # whole query appears in description
    head_bonus = 0.15 if desc_list[0] in q else 0.0  # query is the head food
    base = 0.50 * coverage + 0.25 * jaccard + 0.10 * subset + head_bonus
    return base + _DATA_TYPE_BONUS.get(data_type, 0.0)


def best_match(query: str, candidates):
    """Return (candidate, score) for the highest-scoring candidate, or (None, 0)."""
    best, best_score = None, 0.0
    for c in candidates:
        s = score_candidate(query, c.get("description", ""), c.get("data_type", ""))
        # Tie-break toward the shorter (more generic) description.
        if s > best_score or (
            best is not None and s == best_score
            and len(c.get("description", "")) < len(best.get("description", ""))
        ):
            best, best_score = c, s
    return best, best_score


class Command(BaseCommand):
    help = "Link CanonicalIngredient rows to a stable USDA fdc_id by scored search."

    def add_arguments(self, parser):
        parser.add_argument("--dry-run", action="store_true", help="Don't save changes")
        parser.add_argument("--limit", type=int, default=0, help="Max rows to process (0 = all)")
        parser.add_argument("--only-missing", action="store_true",
                            help="Skip canonicals that already have a usda_fdc_id")
        parser.add_argument("--min-score", type=float, default=0.5,
                            help="Minimum match score to accept a pin (default 0.5)")
        parser.add_argument("--sleep", type=float, default=0.3,
                            help="Seconds between USDA requests (rate limiting)")
        parser.add_argument("--override-file",
                            help="JSON {canonical_name: fdc_id} of hand-curated pins. These are "
                                 "applied verbatim (get-or-create the canonical, set usda_fdc_id) "
                                 "before any search — the authoritative source for names USDA "
                                 "search can't match or mis-matches. Can be used alone (no USDA key).")

    def handle(self, *args, **options):
        dry = options["dry_run"]
        limit = options["limit"]
        only_missing = options["only_missing"]
        min_score = options["min_score"]
        sleep_s = options["sleep"]

        # Hand-curated overrides first (authoritative; replays catalog curation).
        if options.get("override_file"):
            self._apply_overrides(options["override_file"], dry)

        client = USDAClient()
        if not client.api_key:
            # Overrides don't need USDA; only error if we were also asked to search.
            msg = "USDA_API_KEY not configured"
            if options.get("override_file"):
                self.stdout.write(f"{msg}; applied overrides only, skipping search.")
                return
            self.stderr.write(self.style.ERROR(f"{msg}; aborting."))
            return

        qs = CanonicalIngredient.objects.all().order_by("id")
        if only_missing:
            qs = qs.filter(usda_fdc_id__isnull=True) | qs.filter(usda_fdc_id="")
            qs = qs.distinct()
        if limit:
            qs = qs[:limit]

        scanned = pinned = weak = 0
        for ci in qs.iterator():
            scanned += 1
            # Prefer the English name; fall back to French for FR-only rows.
            query = (ci.canonical_name_en or ci.canonical_name_fr or "").strip()
            if not query:
                continue

            candidates = client.search_candidates(query)
            if sleep_s:
                time.sleep(sleep_s)

            match, score = best_match(query, candidates)
            if not match or score < min_score:
                weak += 1
                self.stdout.write(
                    f"  ? {query}: best={match.get('description') if match else 'none'} "
                    f"(score={score:.2f}) — below {min_score}, left unlinked"
                )
                continue

            self.stdout.write(
                f"  + {query} -> [{match['data_type']}] {match['description']} "
                f"(fdc {match['fdc_id']}, score={score:.2f})"
            )
            if not dry:
                ci.usda_fdc_id = match["fdc_id"]
                ci.save(update_fields=["usda_fdc_id"])
            pinned += 1

            if scanned % 100 == 0:
                self.stdout.write(f"Scanned {scanned}, pinned {pinned}, weak {weak}")

        self.stdout.write(self.style.SUCCESS(
            f"Done. Scanned {scanned}, pinned {pinned}, left-unlinked {weak}"
            + (" (dry run)" if dry else "")
        ))

    def _apply_overrides(self, path, dry):
        """Apply hand-curated {canonical_name: fdc_id} pins verbatim.

        Get-or-creates the canonical (so re-split concepts like "ground beef"
        materialise on a fresh seed) and sets usda_fdc_id, overwriting any prior
        (mis-)match. Deterministic; no USDA calls.
        """
        import json

        with open(path, encoding="utf-8") as fh:
            overrides = json.load(fh)
        applied = created = 0
        for name, fdc in overrides.items():
            name = (name or "").strip()
            if not name or not fdc:
                continue
            ci = CanonicalIngredient.objects.filter(canonical_name_en=name).first()
            if ci is None:
                if dry:
                    created += 1
                    continue
                ci = CanonicalIngredient.objects.create(canonical_name_en=name)
                created += 1
            if str(ci.usda_fdc_id or "") != str(fdc):
                if not dry:
                    ci.usda_fdc_id = str(fdc)
                    ci.save(update_fields=["usda_fdc_id"])
                applied += 1
        self.stdout.write(self.style.SUCCESS(
            f"Overrides: {applied} pinned, {created} canonicals created from {path}"
            + (" (dry run)" if dry else "")
        ))
