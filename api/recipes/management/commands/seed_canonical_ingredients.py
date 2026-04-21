import json
from django.core.management.base import BaseCommand
from django.db import transaction
from django.db.models import Q
from recipes.models import CanonicalIngredient


class Command(BaseCommand):
    help = (
        "Seed CanonicalIngredient entries from a JSONL file (one JSON object per line). "
        "Enforces duplicate/singular/plural rules: prefers plural; skips singular if plural exists; "
        "replaces existing singular with plural if encountered."
    )

    def add_arguments(self, parser):
        parser.add_argument(
            "jsonl_path",
            nargs="?",
            default="recipes/data/ingredients.jsonl",
            help="Path to JSONL file with canonical ingredients (default: recipes/data/ingredients.jsonl)",
        )
        parser.add_argument(
            "--update",
            action="store_true",
            help="Update existing entries if they already exist (matched by canonical_name_en)",
        )
        parser.add_argument(
            "--no-prefer-plural",
            action="store_true",
            help="Disable plural-preference logic (by default, plural forms are preferred)",
        )

    @staticmethod
    def _to_singular(phrase: str) -> str:
        """Convert last word of phrase to a simple singular form (basic English heuristics)."""
        if not phrase:
            return phrase
        parts = phrase.strip().split()
        if not parts:
            return phrase
        w = parts[-1]
        lw = w.lower()
        new = w
        if lw.endswith("ies") and len(lw) > 3:
            new = w[:-3] + ("y" if w[-3:].islower() else "y")
        elif any(lw.endswith(suf) for suf in ["ses", "xes", "zes", "ches", "shes"]) and len(lw) > 2:
            new = w[:-2]
        elif lw.endswith("s") and not lw.endswith("ss"):
            new = w[:-1]
        parts[-1] = new
        return " ".join(parts)

    @staticmethod
    def _to_plural(phrase: str) -> str:
        """Convert last word of phrase to a simple plural form (basic English heuristics)."""
        if not phrase:
            return phrase
        parts = phrase.strip().split()
        if not parts:
            return phrase
        w = parts[-1]
        lw = w.lower()
        vowels = set("aeiou")
        new = w
        if lw.endswith("y") and (len(lw) == 1 or lw[-2] not in vowels):
            new = w[:-1] + "ies"
        elif any(lw.endswith(suf) for suf in ["s", "x", "z"]) or any(lw.endswith(suf) for suf in ["ch", "sh"]):
            new = w + "es"
        else:
            new = w + "s"
        parts[-1] = new
        return " ".join(parts)

    def handle(self, *args, **options):
        path = options["jsonl_path"]
        update = options["update"]
        prefer_plural = not bool(options.get("no-prefer-plural"))

        created = 0
        updated = 0
        skipped = 0
        replaced = 0
        total_objects = 0

        def upsert_obj(obj, obj_index: int):
            nonlocal created, updated, skipped, replaced
            name_en = (obj.get("canonical_name_en") or "").strip()
            if not name_en:
                self.stderr.write(self.style.WARNING(f"Skipping object #{obj_index}: missing canonical_name_en"))
                return

            defaults = {
                "canonical_name_fr": obj.get("canonical_name_fr"),
                "category": obj.get("category"),  # 2-letter code
            }

            # Enforce plural/singular rules
            if prefer_plural:
                singular = self._to_singular(name_en)
                plural = self._to_plural(singular)

                # Existing matches (case-insensitive)
                existing_ci = CanonicalIngredient.objects.filter(canonical_name_en__iexact=name_en)
                existing_singular = CanonicalIngredient.objects.filter(canonical_name_en__iexact=singular)
                existing_plural = CanonicalIngredient.objects.filter(canonical_name_en__iexact=plural)

                # If plural exists and incoming is singular => skip
                if name_en.lower() == singular.lower() and existing_plural.exists():
                    skipped += 1
                    return

                # If singular exists and incoming is plural => replace singular with plural
                if name_en.lower() == plural.lower() and existing_singular.exists():
                    with transaction.atomic():
                        count_deleted, _ = existing_singular.delete()
                        obj_qs = CanonicalIngredient.objects.filter(canonical_name_en__iexact=name_en)
                        if obj_qs.exists():
                            obj_qs.update(**defaults)
                            updated += 1
                        else:
                            CanonicalIngredient.objects.create(canonical_name_en=name_en, **defaults)
                            created += 1
                        replaced += count_deleted
                    return

                # Otherwise case-insensitive upsert
                if existing_ci.exists():
                    if update:
                        existing_ci.update(**defaults)
                        updated += 1
                else:
                    CanonicalIngredient.objects.create(canonical_name_en=name_en, **defaults)
                    created += 1
            else:
                # No plural preference: case-insensitive upsert by exact name
                obj_qs = CanonicalIngredient.objects.filter(canonical_name_en__iexact=name_en)
                if obj_qs.exists():
                    if update:
                        obj_qs.update(**defaults)
                        updated += 1
                else:
                    CanonicalIngredient.objects.create(canonical_name_en=name_en, **defaults)
                    created += 1

        try:
            with open(path, "r", encoding="utf-8") as f:
                # Stream and support both JSONL (one object per line) and multi-line pretty JSON objects
                buffer = []
                brace_depth = 0
                for raw_line in f:
                    line = raw_line.strip()
                    if not line:
                        continue
                    # Skip JSON array brackets if present
                    if line in ("[", "]", "[,", "],"):
                        continue
                    # If we're not currently buffering an object and the line doesn't contain '{',
                    # try to parse as a standalone JSON (JSONL mode). Otherwise, start buffering.
                    if brace_depth == 0 and "{" not in line:
                        # JSONL candidate
                        try:
                            obj = json.loads(line)
                        except json.JSONDecodeError as e:
                            # Not a valid standalone JSON, likely a stray comma or similar — skip with message
                            self.stderr.write(self.style.ERROR(f"Invalid JSON on line: {line[:40]}..."))
                            continue
                        total_objects += 1
                        upsert_obj(obj, total_objects)
                        continue

                    # Start or continue buffering a multi-line object
                    brace_depth += line.count("{") - line.count("}")
                    buffer.append(line)
                    if brace_depth == 0 and buffer:
                        # End of object detected
                        blob = "\n".join(buffer).strip().rstrip(",")
                        buffer = []
                        try:
                            obj = json.loads(blob)
                        except json.JSONDecodeError as e:
                            self.stderr.write(self.style.ERROR(f"Invalid JSON object near index {total_objects + 1}: {e}"))
                            continue
                        total_objects += 1
                        upsert_obj(obj, total_objects)

                # In case of unclosed buffer, attempt parse
                if buffer:
                    blob = "\n".join(buffer).strip().rstrip(",")
                    try:
                        obj = json.loads(blob)
                        total_objects += 1
                        upsert_obj(obj, total_objects)
                    except Exception:
                        pass

        except FileNotFoundError:
            self.stderr.write(self.style.ERROR(f"File not found: {path}"))
            return

        self.stdout.write(self.style.SUCCESS(
            f"Seed complete. total_objects={total_objects}, created={created}, updated={updated}, skipped={skipped}, replaced={replaced}"
        ))
