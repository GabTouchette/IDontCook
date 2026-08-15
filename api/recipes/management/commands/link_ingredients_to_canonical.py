from django.core.management.base import BaseCommand
from django.db.models import Q
from recipes.models import Ingredient, CanonicalIngredient


class Command(BaseCommand):
    help = "Link existing Ingredient rows to CanonicalIngredient by exact normalized_name or aliases (case-insensitive)."

    def add_arguments(self, parser):
        parser.add_argument("--dry-run", action="store_true", help="Don't save changes")
        parser.add_argument("--limit", type=int, default=0, help="Limit processed rows (0 = all)")

    def handle(self, *args, **options):
        dry = options["dry_run"]
        limit = options["limit"]

        qs = Ingredient.objects.all().order_by("id")
        if limit:
            qs = qs[:limit]

        linked = 0
        scanned = 0

        # Build a lookup map for faster alias checks
        alias_map = {}
        for ci in CanonicalIngredient.objects.all():
            names = set([ci.canonical_name_en.lower()])
            for a in (ci.aliases_en or []):
                if a:
                    names.add(str(a).lower())
            for a in (ci.aliases_fr or []):
                if a:
                    names.add(str(a).lower())
            for n in names:
                alias_map.setdefault(n, []).append(ci.id)

        for ing in qs.iterator():
            scanned += 1
            name = (ing.normalized_name or ing.name or "").strip().lower()
            if not name:
                continue

            ci_id = None

            # Exact canonical_name_en match first
            ci = CanonicalIngredient.objects.filter(canonical_name_en__iexact=name).first()
            if ci:
                ci_id = ci.id
            else:
                # Alias match
                id_list = alias_map.get(name)
                if id_list:
                    ci_id = id_list[0]

            if ci_id:
                if not dry:
                    ing.canonical_id = ci_id
                    ing.save(update_fields=["canonical"])
                linked += 1

            if scanned % 500 == 0:
                self.stdout.write(f"Scanned {scanned}, linked {linked}")

        self.stdout.write(self.style.SUCCESS(f"Done. Scanned {scanned}, linked {linked}"))
