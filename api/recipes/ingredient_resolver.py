"""Resolve free-text ingredient names to a single :class:`CanonicalIngredient`.

The catalog is the resolution hub: instead of every ingredient line running its
own USDA text search (and trusting the first hit), lines resolve *once* to a
canonical concept, and nutrition + grocery merging key off that concept. This
module owns that resolution.

Resolution escalates only as far as it needs to:

    1. exact  — normalized name matches a canonical name or alias (EN/FR)
    2. alias  — same, matched via an alias surface form
    3. fuzzy  — closest catalog name above a confidence floor (string similarity;
                this is also the seam where a semantic/embedding candidate stage
                would slot in — it just needs to return (name, score) pairs)
    4. llm    — Claude disambiguates among the top fuzzy candidates when string
                similarity alone is inconclusive

Every result carries a ``confidence`` (0..1) and ``method`` so callers can store
them on the ``Ingredient`` and flag low-confidence links for review before they
feed nutrition numbers.
"""

from __future__ import annotations

import difflib
import logging
from dataclasses import dataclass
from typing import List, Optional, Tuple

from django.conf import settings

from .ingredient_normalizer import clean_for_usda, normalize_name_and_prep

logger = logging.getLogger(__name__)

# Accept a fuzzy match outright at/above this score; never escalate to the LLM.
_FUZZY_ACCEPT = 0.90
# Below this, candidates are too weak to be worth showing the LLM.
_CANDIDATE_FLOOR = 0.60
# Confidence stamped on an LLM-selected match (a plausible but not-certain pick).
_LLM_CONFIDENCE = 0.80


@dataclass
class ResolveResult:
    canonical_id: Optional[int]
    canonical: Optional[object]  # CanonicalIngredient | None (avoid import cycle)
    confidence: float
    method: str  # 'exact' | 'alias' | 'fuzzy' | 'llm' | 'none'

    @property
    def matched(self) -> bool:
        return self.canonical_id is not None


# --- Index -----------------------------------------------------------------
# Built lazily and cached per-process. Catalog changes are rare (seed/backfill
# commands); callers that mutate it should call clear_cache().
_INDEX: Optional["_CatalogIndex"] = None


class _CatalogIndex:
    """In-memory surface-form -> canonical_id lookup over the whole catalog."""

    def __init__(self):
        from .models import CanonicalIngredient

        # surface form (lowercased) -> canonical_id, and whether it's a primary
        # name (exact) or an alias. Lowest id wins on collision (deterministic).
        self.exact: dict[str, int] = {}
        self.alias: dict[str, int] = {}
        self._by_id: dict[int, object] = {}

        rows = CanonicalIngredient.objects.all().only(
            "id", "canonical_name_en", "canonical_name_fr", "aliases_en", "aliases_fr"
        )
        for ci in rows.iterator():
            self._by_id[ci.id] = ci
            for name in (ci.canonical_name_en, ci.canonical_name_fr):
                if name:
                    self.exact.setdefault(name.strip().lower(), ci.id)
            for alias in (ci.aliases_en or []) + (ci.aliases_fr or []):
                if alias:
                    self.alias.setdefault(str(alias).strip().lower(), ci.id)

        # Pool of surface forms for fuzzy matching (names + aliases).
        self._forms: List[str] = list(self.exact.keys()) + list(self.alias.keys())

    def get(self, canonical_id: int):
        return self._by_id.get(canonical_id)

    def lookup_exact(self, form: str) -> Tuple[Optional[int], Optional[str]]:
        if form in self.exact:
            return self.exact[form], "exact"
        if form in self.alias:
            return self.alias[form], "alias"
        return None, None

    def fuzzy_candidates(self, form: str, n: int = 5) -> List[Tuple[str, float, int]]:
        """Return up to ``n`` (surface_form, score, canonical_id) above the floor."""
        matches = difflib.get_close_matches(form, self._forms, n=n, cutoff=_CANDIDATE_FLOOR)
        out: List[Tuple[str, float, int]] = []
        for m in matches:
            score = difflib.SequenceMatcher(None, form, m).ratio()
            cid = self.exact.get(m) or self.alias.get(m)
            if cid is not None:
                out.append((m, score, cid))
        out.sort(key=lambda t: t[1], reverse=True)
        return out


def _get_index() -> "_CatalogIndex":
    global _INDEX
    if _INDEX is None:
        _INDEX = _CatalogIndex()
    return _INDEX


def clear_cache() -> None:
    """Drop the cached catalog index (call after seeding/editing the catalog)."""
    global _INDEX
    _INDEX = None


# --- Resolution ------------------------------------------------------------
def resolve(raw_name: str, *, use_llm: bool = True) -> ResolveResult:
    """Resolve a raw ingredient name to a canonical concept.

    ``use_llm=False`` keeps resolution fully deterministic (string-only) — useful
    for bulk backfills where a per-row LLM call would be too slow/expensive.
    """
    none = ResolveResult(None, None, 0.0, "none")
    if not raw_name or not raw_name.strip():
        return none

    index = _get_index()

    # Build candidate surface forms, most-normalized first. normalize_name_and_prep
    # strips descriptors ("fresh", "minced"); clean_for_usda additionally strips
    # measure/unit words ("cloves", "leaves") that would otherwise leak into the
    # name ("garlic cloves" -> "garlic"). Trying each catches more exact hits
    # before resorting to fuzzy.
    norm_name, _prep = normalize_name_and_prep(raw_name)
    forms: List[str] = []
    for form in (norm_name, clean_for_usda(raw_name), raw_name):
        f = (form or "").strip().lower()
        if f and f not in forms:
            forms.append(f)

    # 1/2) Exact or alias, across the candidate forms.
    for f in forms:
        cid, method = index.lookup_exact(f)
        if cid is not None:
            confidence = 1.0 if method == "exact" else 0.98
            return ResolveResult(cid, index.get(cid), confidence, method)

    # 3) Fuzzy, on the most-normalized form.
    primary = forms[0] if forms else raw_name.strip().lower()
    candidates = index.fuzzy_candidates(primary)
    if candidates:
        best_form, best_score, best_cid = candidates[0]
        if best_score >= _FUZZY_ACCEPT:
            return ResolveResult(best_cid, index.get(best_cid), round(best_score, 3), "fuzzy")

        # 4) LLM disambiguation among the plausible candidates.
        if use_llm:
            chosen = _llm_disambiguate(primary, candidates, index)
            if chosen is not None:
                return ResolveResult(chosen, index.get(chosen), _LLM_CONFIDENCE, "llm")

        # Return the best fuzzy guess but flag it as low-confidence for review.
        return ResolveResult(best_cid, index.get(best_cid), round(best_score, 3), "fuzzy")

    return none


def _llm_disambiguate(name: str, candidates, index) -> Optional[int]:
    """Ask Claude to pick the best canonical id among candidates, or None."""
    api_key = getattr(settings, "ANTHROPIC_API_KEY", None)
    if not api_key:
        return None
    try:
        import json
        import re

        import anthropic

        options = []
        for _form, _score, cid in candidates:
            ci = index.get(cid)
            if ci is not None:
                options.append({"id": cid, "name": ci.canonical_name_en})
        if not options:
            return None

        prompt = (
            f'A recipe lists the ingredient: "{name}".\n'
            f"Which of these canonical ingredients is it, if any?\n"
            f"{json.dumps(options)}\n\n"
            "Return ONLY a JSON object: {\"id\": <the matching id as an integer, "
            "or null if none truly match>}. No prose, no markdown."
        )
        client = anthropic.Anthropic(api_key=api_key)
        resp = client.messages.create(
            model="claude-haiku-4-5",
            max_tokens=64,
            messages=[{"role": "user", "content": prompt}],
        )
        raw = resp.content[0].text.strip()
        raw = re.sub(r"^```[a-z]*\s*|\s*```$", "", raw).strip()
        data = json.loads(raw)
        chosen = data.get("id")
        valid_ids = {c[2] for c in candidates}
        if isinstance(chosen, int) and chosen in valid_ids:
            return chosen
        return None
    except Exception as exc:  # noqa: BLE001 - LLM fallback must never hard-fail resolution
        logger.warning("ingredient_resolver LLM disambiguation failed: %s", exc)
        return None
