import json
import os
from collections import Counter, defaultdict
from typing import Set

from django.core.management.base import BaseCommand

from recipes.models import Ingredient, CanonicalIngredient
from recipes.ingredient_normalizer import normalize_name_and_prep


class Command(BaseCommand):
    help = (
        "Scan Ingredients in the DB and append any missing canonical entries to a JSONL file. "
        "Skips names already present in the JSONL file or existing CanonicalIngredient rows."
    )

    def add_arguments(self, parser):
        parser.add_argument(
            "--jsonl-path",
            default="recipes/data/ingredients.jsonl",
            help="Path to the JSONL file to create/append (default: recipes/data/ingredients.jsonl)",
        )
        parser.add_argument(
            "--min-count",
            type=int,
            default=1,
            help="Only include normalized names that appear at least this many times (default: 1)",
        )
        parser.add_argument(
            "--limit",
            type=int,
            default=0,
            help="Maximum number of new entries to write (0 = no limit)",
        )
        parser.add_argument(
            "--examples",
            type=int,
            default=0,
            help="Include up to N example original strings per entry under _examples (default: 0)",
        )
        parser.add_argument(
            "--dry-run",
            action="store_true",
            help="Do not write to file; just report what would be added.",
        )

    def _load_existing_names_from_jsonl(self, path: str) -> Set[str]:
        known: Set[str] = set()
        if not os.path.exists(path):
            return known
        with open(path, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    obj = json.loads(line)
                except json.JSONDecodeError:
                    continue
                for key in ("canonical_name_en", "canonical_name_fr"):
                    name = (obj.get(key) or "").strip().lower()
                    if name:
                        known.add(name)
                # aliases were removed from schema; ignore if present
        return known

    def _load_existing_names_from_db(self) -> Set[str]:
        known: Set[str] = set()
        for ci in CanonicalIngredient.objects.all():
            if ci.canonical_name_en:
                known.add(ci.canonical_name_en.strip().lower())
            if ci.canonical_name_fr:
                known.add(ci.canonical_name_fr.strip().lower())
            # aliases removed; nothing to add here
        return known

    def handle(self, *args, **options):
        jsonl_path = options["jsonl_path"]
        min_count = options["min_count"]
        limit = options["limit"]
        examples_n = options["examples"]
        dry_run = options["dry_run"]

        # Build known set from file and DB
        known = set()
        # Also treat the sample file as a source of known names if it exists
        sample_path = os.path.join("recipes", "data", "ingredients.sample.jsonl")
        known |= self._load_existing_names_from_jsonl(sample_path)
        known |= self._load_existing_names_from_jsonl(jsonl_path)
        known |= self._load_existing_names_from_db()

        # Normalize ingredient names on the fly (the normalized_name column was
        # dropped in favour of the canonical resolver) and aggregate counts +
        # example source strings in Python.
        counts: Counter = Counter()
        examples_map = defaultdict(list)
        raw_names = (
            Ingredient.objects.exclude(name__isnull=True)
            .exclude(name="")
            .values_list("name", flat=True)
            .iterator()
        )
        for raw in raw_names:
            norm, _prep = normalize_name_and_prep(raw)
            norm = (norm or "").strip()
            if not norm:
                continue
            counts[norm] += 1
            if examples_n and raw not in examples_map[norm] and len(examples_map[norm]) < examples_n:
                examples_map[norm].append(raw)

        rows = [
            {"normalized_name": name, "n": n}
            for name, n in counts.items()
            if n >= min_count
        ]
        rows.sort(key=lambda r: (-r["n"], r["normalized_name"]))

        # map full category names → 2-letter codes
        CAT2 = {
            "Produce": "PR",
            "Meat & Seafood": "MS",
            "Dairy & Eggs": "DE",
            "Bakery": "BA",
            "Canned & Jars": "CJ",
            "Dry Goods & Pasta": "DG",
            "Baking": "BK",
            "Spices": "SP",
            "Condiments & Oils": "CO",
            "Frozen": "FR",
            "Beverages": "BE",
            "Household/Other": "HO",
        }

        to_write = []
        for r in rows:
            name = (r["normalized_name"] or "").strip()
            key = name.lower()
            if not name or key in known:
                continue

            # Gather example original strings if requested
            examples_list = examples_map.get(name, []) if examples_n > 0 else []

            doc = {
                # Only the simplified schema fields
                "canonical_name_en": name,
                "canonical_name_fr": None,
                # default to HO code; can be curated later
                "category": CAT2.get("Household/Other", "HO"),
            }

            # Keep non-schema hints under underscored keys for curation/debug (optional)
            if examples_n > 0:
                doc["_examples"] = examples_list
            doc["_count"] = r["n"]
            to_write.append(doc)

            if limit and len(to_write) >= limit:
                break

        if dry_run:
            self.stdout.write(
                f"Dry run: {len(to_write)} new canonical entries would be appended to {jsonl_path}"
            )
            for d in to_write[:10]:
                self.stdout.write(json.dumps(d, ensure_ascii=False))
            if len(to_write) > 10:
                self.stdout.write(f"...and {len(to_write) - 10} more")
            return

        if not to_write:
            self.stdout.write(self.style.SUCCESS("No new entries to write."))
            return

        # Ensure directory exists
        os.makedirs(os.path.dirname(jsonl_path), exist_ok=True)

        # Append to file
        with open(jsonl_path, "a", encoding="utf-8") as f:
            for d in to_write:
                # Only write allowed fields
                out = {
                    "canonical_name_en": d["canonical_name_en"],
                    "canonical_name_fr": d["canonical_name_fr"],
                    "category": d["category"],
                }
                f.write(json.dumps(out, ensure_ascii=False) + "\n")

        self.stdout.write(
            self.style.SUCCESS(
                f"Appended {len(to_write)} new canonical entries to {jsonl_path}"
            )
        )
