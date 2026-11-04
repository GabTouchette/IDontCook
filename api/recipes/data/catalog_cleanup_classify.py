"""One-off: classify the 926 ambiguous canonical names -> base ingredient or null.

Run from api/ with .venv/bin/python manage.py shell < /tmp/classify.py
Writes /tmp/catalog_mapping.json  ({raw_name: clean_name|null}).
"""
import json
import re
from recipes.ingredient_normalizer import normalize_name_and_prep

names = json.load(open("/tmp/ambiguous_names.json"))

DIGIT = re.compile(r"\d")

# Tokens that mark the start of trailing prep/packing cruft -> cut here.
# NB: intentionally excludes "of" (cream OF mushroom soup) and "style".
CUT = {
    "cut", "into", "and", "or", "for", "with", "plus", "about", "soaked",
    "halved", "quartered", "pounded", "patted", "scrubbed", "cleaned", "torn",
    "separated", "removed", "thawed", "skinned", "shelled", "crumbled",
    "casing", "casings", "seeded", "pitted", "washed", "shucked", "deveined",
    "trimmed", "drained", "undrained", "rinsed", "reserved", "discarded",
    "softened", "melted", "warmed", "chilled", "cooled", "cubed", "unwrapped",
    "dissolved", "beaten", "stems", "stem", "skin", "squeezed", "picked",
    "fed", "tied", "broken", "grinds", "several", "outer", "bones", "excess",
    "lengthwise", "crosswise", "diagonally", "thinly", "coarsely",
    "sliced", "chopped", "diced", "minced", "grated", "shredded", "mashed",
    "in", "halves", "halve",
}

# Leading words to drop before collecting the head noun.
LEAD_DROP = {
    "finely", "freshly", "fresh-ground", "firmly", "cold", "cold-pressed",
    "hot", "warm", "chilled", "cooked", "uncooked", "dried", "raw", "prepared",
    "refrigerated", "sifted", "blanched", "good-quality", "loaf", "deli",
    "bulk", "regular", "grilled", "roasted", "toasted", "smoked", "cured",
    "lean", "solid", "fluffy", "stiff", "soft", "very", "thin-sliced",
    "ready-to-bake", "ready-to-cook", "ready-to-eat", "whole",
}

# Measurement / packaging words that are pure cruft at the front.
MEASURE = {"inch", "inches", "pint", "half-pint", "loaf", "cube", "cubes"}

# Explicit non-food junk -> null.
NULLS = {
    "canning jars with lid",
    "half-pint canning jars with lids and ring",
    "sterilized canning jars with lids and ring",
    "bamboo skewers soaked in water 20 minut",
    "bamboo skewers soaked in water for 20 minut",
    "wooden skewers or as needed soaked in water for 15 minut",
    "wooden pop sticks",
    "reynolds® slow cooker liner",
}

# Explicit overrides where rules misfire or brand/packaging needs collapsing.
EXCEPTIONS = {
    "80/20 ground beef": "ground beef",
    "ground chuck or 80% ground beef": "ground beef",
    "uffalo wing sauce": "buffalo wing sauce",
    "eddeos and cut into 1 1/2-inch chunk": "eddoe",
    "cloves": "clove", "cloves or to taste": "clove", "ground cloves": "clove",
    "individually wrapped caramels unwrapped": "caramel",
    "warm water )": "water", "hot tap water": "water",
    "water or amount to cover": "water", "water or enough to cover": "water",
    "hot water or coffee": "water",
    "cabbage for 3 days then thawed overnight in the refrigerator": "cabbage",
    "plus 1 tablespoon jasmine rice": "jasmine rice",
    "fed sourdough starter": "sourdough starter",
    "stevia extract in the raw™": "stevia",
    "makrut lime leav": "makrut lime leaf",
    "kikkoman naturally brewed soy sauce": "soy sauce",
    "eagle brand® sweetened condensed milk": "sweetened condensed milk",
    "argo® baking powder": "baking powder",
    "mazola® corn oil": "corn oil",
    "swanson® chicken broth": "chicken broth",
    "almond breeze vanilla almondmilk": "almond milk",
    "unsweetened vanilla almond breeze almondmilk": "almond milk",
    "boar’s head bold® ichiban teriyaki™ style oven roasted chicken": "chicken",
    "johnsonville® original breakfast sausage": "breakfast sausage",
    "regular flavor jimmy dean pork sausage": "pork sausage",
    "joan of arc dark red kidney bean": "dark red kidney bean",
    "joan of arc spicy chili bean": "chili bean",
    "b&m original baked bean": "baked bean",
    "clamato® tomato cocktail": "tomato cocktail",
    "jell-o chocolate instant pudding": "chocolate instant pudding",
    "cool whip whipped topping thawed": "whipped topping",
    "honey maid graham cracker crumb": "graham cracker crumb",
    "spice islands® pure vanilla extract": "vanilla extract",
    "mccormick pure vanilla extract": "vanilla extract",
    "mccormick pure lemon extract": "lemon extract",
    "kraft lite balsamic vinaigrette dressing": "balsamic vinaigrette",
    "philadelphia chive & onion 1/3 less fat than cream cheese": "cream cheese",
    "bruce's® yams cut sweet potatoes in syrup and mashed": "sweet potato",
}

# Trailing words left after cutting that should also be dropped if dangling.
TRAIL_DROP = {"of", "e.g.", "such", "as", "a", "an", "the", "-", "–", "half",
              "leav", "leaves", "leaf"}


# Repair the old seed plural-corruption ("olives"->"oliv") on surviving tokens.
DEMANGLE = {
    "noodl": "noodle", "cooki": "cookie", "squar": "square", "wedg": "wedge",
    "piec": "piece", "cub": "cube", "cherri": "cherry", "grap": "grape",
    "granul": "granule", "patti": "patty", "oliv": "olive", "clov": "clove",
    "slic": "slice", "chunk": "chunk", "crumb": "crumb", "veggi": "veggie",
    "pastri": "pastry", "berri": "berry", "pattie": "patty",
}


def has_digit(t):
    return bool(DIGIT.search(t))


def reduce(name):
    if name in NULLS:
        return None
    if name in EXCEPTIONS:
        return EXCEPTIONS[name]

    s = name.lower()
    s = re.sub(r"[®™]", " ", s)
    s = re.sub(r"\([^)]*\)", " ", s)      # drop parentheticals
    s = s.replace("®", " ").replace("™", " ")
    tokens = [t for t in re.split(r"\s+", s) if t]

    # Drop leading numeric/measurement/junk AND leading prep (a prep word at the
    # front is a leading modifier, not a boundary — "shucked oysters" -> oyster,
    # "freshly squeezed blood orange juice" -> blood orange juice).
    while tokens and (has_digit(tokens[0]) or tokens[0].strip(".,-") in (LEAD_DROP | MEASURE | CUT)):
        tokens.pop(0)

    out = []
    for t in tokens:
        tt = t.strip(".,")
        if has_digit(tt) or tt in CUT:
            break
        out.append(t)

    # Trim dangling trailing junk (incl. "leaves"/"half" unit words after a noun).
    while out and out[-1].strip(".,-") in TRAIL_DROP:
        out.pop()

    prefix = " ".join(out).strip(" -,–")
    if not prefix:
        return None

    norm, _ = normalize_name_and_prep(prefix)
    cleaned = (norm or prefix).strip()
    if not cleaned:
        return None
    cleaned = " ".join(DEMANGLE.get(w, w) for w in cleaned.split())
    return cleaned or None


mapping = {}
for n in names:
    mapping[n] = reduce(n)

json.dump(mapping, open("/tmp/catalog_mapping.json", "w"), ensure_ascii=False, indent=0)

# Quick self-report
vals = [v for v in mapping.values() if v]
nulls = [k for k, v in mapping.items() if v is None]
print("total:", len(mapping), "| mapped:", len(vals), "| null(junk):", len(nulls))
print("distinct clean targets:", len(set(vals)))
print("\nnull/junk:", nulls)
import collections
big = collections.Counter(vals).most_common(15)
print("\ntop merge targets:", big)
