"""Collapse the polluted canonical catalog into clean, deduplicated concepts.

Most rows are raw ingredient lines ("garlic clove finely", "egg lightly beaten")
rather than ingredients. This command reduces each name to its base ingredient
deterministically and merges rows that reduce to the same concept — repointing
every ``Ingredient.canonical`` FK to the survivor and deleting the duplicates.
Names the deterministic pass can't confidently clean are routed to Claude
(``--use-llm``), which returns a base name or marks the row as junk.

Dry-run by default; nothing is mutated without ``--apply``.

    python manage.py clean_canonical_catalog                      # preview deterministic merge
    python manage.py clean_canonical_catalog --use-llm            # preview incl. Claude residue
    python manage.py clean_canonical_catalog --use-llm --apply    # do it
"""

import json
import re

from django.core.management.base import BaseCommand
from django.db import transaction

from recipes.models import CanonicalIngredient, Ingredient
from recipes.catalog_cleaning import deterministic_clean, is_ambiguous
from recipes import ingredient_resolver


class Command(BaseCommand):
    help = "Deduplicate/clean CanonicalIngredient rows (deterministic + optional Claude)."

    def add_arguments(self, parser):
        parser.add_argument("--apply", action="store_true",
                            help="Actually merge/delete (default is a dry-run preview)")
        parser.add_argument("--use-llm", action="store_true",
                            help="Send names the deterministic pass can't clean to Claude")
        parser.add_argument("--mapping-file",
                            help="Path to a JSON object {raw_name: clean_name|null} to use for "
                                 "the ambiguous rows instead of calling the Claude API. Takes "
                                 "precedence over --use-llm. Names absent from the file are left "
                                 "untouched; null marks a row as junk (unlink + delete).")
        parser.add_argument("--llm-batch-size", type=int, default=40,
                            help="Names per Claude classification request")
        parser.add_argument("--limit", type=int, default=0,
                            help="Only consider the first N canonical rows (debug)")
        parser.add_argument("--samples", type=int, default=20,
                            help="How many example merges to print")
        parser.add_argument("--max-group", type=int, default=60,
                            help="Safety: refuse to apply if any single merge group "
                                 "absorbs more than this many rows (signals a bad mapping)")
        parser.add_argument("--force", action="store_true",
                            help="Override the --max-group safety check")

    def handle(self, *args, **options):
        apply = options["apply"]
        use_llm = options["use_llm"]
        batch_size = options["llm_batch_size"]
        limit = options["limit"]
        samples = options["samples"]

        rows = list(CanonicalIngredient.objects.all().order_by("id"))
        if limit:
            rows = rows[:limit]
        total = len(rows)

        # key -> survivor-group; special key None collects junk (to unlink+delete)
        key_for = {}       # ci.id -> clean key (or None for junk)
        ambiguous = []     # (ci, cleaned) needing LLM

        for ci in rows:
            cleaned = deterministic_clean(ci.canonical_name_en)
            if is_ambiguous(ci.canonical_name_en, cleaned):
                ambiguous.append((ci, cleaned))
            else:
                key_for[ci.id] = cleaned

        mapping_file = options.get("mapping_file")
        llm_resolved = llm_junk = 0
        if (mapping_file or use_llm) and ambiguous:
            if mapping_file:
                with open(mapping_file, encoding="utf-8") as fh:
                    mapping = json.load(fh)
                self.stdout.write(f"Loaded {len(mapping)} mappings from {mapping_file}")
            else:
                mapping = self._llm_classify([ci.canonical_name_en for ci, _ in ambiguous], batch_size)
            for ci, cleaned in ambiguous:
                # Only act on names the LLM actually returned. A missing key (batch
                # failed / not answered) MUST leave the row untouched — never merge
                # it under a placeholder, or every unclassified row collapses into
                # one bogus group.
                if ci.canonical_name_en not in mapping:
                    key_for[ci.id] = ci.canonical_name_en.strip().lower()
                    continue
                val = mapping[ci.canonical_name_en]
                if val is None:
                    key_for[ci.id] = None  # junk → unlink + delete
                    llm_junk += 1
                elif isinstance(val, str) and val.strip():
                    key_for[ci.id] = val.strip().lower()
                    llm_resolved += 1
                else:
                    key_for[ci.id] = ci.canonical_name_en.strip().lower()
        else:
            # No LLM: leave ambiguous rows untouched (keyed by their own name) so
            # they're preserved verbatim rather than renamed to a half-clean guess.
            for ci, cleaned in ambiguous:
                key_for[ci.id] = ci.canonical_name_en.strip().lower()

        # Build groups keyed by clean name.
        groups = {}
        junk = []
        by_id = {ci.id: ci for ci in rows}
        for cid, key in key_for.items():
            if key is None:
                junk.append(by_id[cid])
            else:
                groups.setdefault(key, []).append(by_id[cid])

        # Plan the merges.
        merges = []            # (survivor, [losers], key)
        rows_deleted = 0
        for key, members in groups.items():
            if len(members) == 1 and members[0].canonical_name_en.strip().lower() == key:
                continue  # already clean & unique — nothing to do
            survivor = self._pick_survivor(members, key)
            losers = [m for m in members if m.id != survivor.id]
            merges.append((survivor, losers, key))
            rows_deleted += len(losers)

        final_count = total - rows_deleted - len(junk)

        self.stdout.write(self.style.NOTICE(
            f"Catalog cleanup {'(APPLY)' if apply else '(dry-run)'}:\n"
            f"  canonical rows scanned : {total}\n"
            f"  deterministic-clean    : {total - len(ambiguous)}\n"
            f"  ambiguous (to Claude)  : {len(ambiguous)}"
            + (f"  -> resolved {llm_resolved}, junk {llm_junk}" if use_llm else " (left untouched; pass --use-llm)")
            + f"\n  merge groups           : {len(merges)}\n"
            f"  duplicate rows removed : {rows_deleted}\n"
            f"  junk rows removed      : {len(junk)}\n"
            f"  → final catalog size   : ~{final_count}"
        ))

        # Show sample merges (biggest groups first).
        merges.sort(key=lambda m: len(m[1]), reverse=True)
        self.stdout.write("\nExample merges (survivor <- duplicates):")
        for survivor, losers, key in merges[:samples]:
            if not losers:
                continue
            shown = ", ".join(sorted(l.canonical_name_en for l in losers)[:6])
            more = "" if len(losers) <= 6 else f" … (+{len(losers) - 6})"
            self.stdout.write(f"  {key!r} <- {shown}{more}")
        if use_llm and junk:
            self.stdout.write("\nExample junk removed: "
                              + ", ".join(repr(j.canonical_name_en) for j in junk[:10]))

        # Safety guardrail: a real ingredient never has this many raw variants, so
        # an oversized group means the mapping is wrong (e.g. a sentinel collapsing
        # everything). Refuse to touch the DB unless explicitly forced.
        max_group = options["max_group"]
        oversized = [(key, len(losers)) for _s, losers, key in merges if len(losers) > max_group]
        if oversized and not options["force"]:
            worst = ", ".join(f"{k!r} (+{n})" for k, n in sorted(oversized, key=lambda x: -x[1])[:5])
            self.stderr.write(self.style.ERROR(
                f"\nABORTED: {len(oversized)} merge group(s) exceed --max-group={max_group}: {worst}.\n"
                "This usually means the classification is wrong. Nothing was changed. "
                "Inspect the dry-run, fix the input, or pass --force to override."
            ))
            return

        if not apply:
            self.stdout.write(self.style.WARNING("\nDry run — no changes written. Re-run with --apply."))
            return

        self._apply(merges, junk)
        ingredient_resolver.clear_cache()
        self.stdout.write(self.style.SUCCESS(
            f"Applied. Catalog now ~{final_count} rows."
        ))

    @staticmethod
    def _pick_survivor(members, key):
        """Prefer an already-clean member whose name == key; else the shortest."""
        exact = [m for m in members if m.canonical_name_en.strip().lower() == key]
        if exact:
            return min(exact, key=lambda m: m.id)
        return min(members, key=lambda m: (len(m.canonical_name_en), m.id))

    @transaction.atomic
    def _apply(self, merges, junk):
        for survivor, losers, key in merges:
            # Normalise the survivor's name/metadata.
            changed_fields = []
            if survivor.canonical_name_en.strip().lower() != key:
                survivor.canonical_name_en = key
                changed_fields.append("canonical_name_en")
            # Inherit category / FR name from a loser if the survivor lacks them.
            if not survivor.category:
                for m in losers:
                    if m.category:
                        survivor.category = m.category
                        changed_fields.append("category")
                        break
            if not survivor.canonical_name_fr:
                for m in losers:
                    if m.canonical_name_fr:
                        survivor.canonical_name_fr = m.canonical_name_fr
                        changed_fields.append("canonical_name_fr")
                        break
            if changed_fields:
                survivor.save(update_fields=changed_fields)

            loser_ids = [m.id for m in losers]
            if loser_ids:
                Ingredient.objects.filter(canonical_id__in=loser_ids).update(canonical=survivor)
                CanonicalIngredient.objects.filter(id__in=loser_ids).delete()

        # Junk: unlink any ingredients, then delete the row.
        junk_ids = [j.id for j in junk]
        if junk_ids:
            Ingredient.objects.filter(canonical_id__in=junk_ids).update(canonical=None)
            CanonicalIngredient.objects.filter(id__in=junk_ids).delete()

    def _llm_classify(self, names, batch_size):
        """Map each messy name -> base ingredient (str) or None (junk), via Claude."""
        from django.conf import settings
        try:
            import anthropic
        except Exception:
            self.stderr.write(self.style.ERROR("anthropic SDK unavailable; skipping LLM pass."))
            return {}
        api_key = getattr(settings, "ANTHROPIC_API_KEY", None)
        if not api_key:
            self.stderr.write(self.style.ERROR("ANTHROPIC_API_KEY not set; skipping LLM pass."))
            return {}

        client = anthropic.Anthropic(api_key=api_key)
        result = {}
        unique = sorted(set(names))
        for i in range(0, len(unique), batch_size):
            chunk = unique[i:i + batch_size]
            prompt = (
                "You are cleaning a food ingredient catalog. For EACH raw string, return "
                "its base canonical ingredient name: lowercase, singular, no quantities, no "
                "preparation words, no brand names. If a string is not a real food ingredient, "
                "map it to null.\n"
                'Return ONLY a JSON object mapping each input string to its cleaned name or null.\n\n'
                f"{json.dumps(chunk, ensure_ascii=False)}"
            )
            try:
                resp = client.messages.create(
                    model="claude-haiku-4-5",
                    max_tokens=2048,
                    messages=[{"role": "user", "content": prompt}],
                )
                raw = resp.content[0].text.strip()
                raw = re.sub(r"^```[a-z]*\s*|\s*```$", "", raw).strip()
                parsed = json.loads(raw)
                if isinstance(parsed, dict):
                    result.update(parsed)
                self.stdout.write(f"  …Claude classified {min(i + batch_size, len(unique))}/{len(unique)}")
            except Exception as exc:  # noqa: BLE001
                self.stderr.write(f"  LLM batch failed ({exc}); leaving this batch unmerged.")
        return result
