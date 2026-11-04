from django.db import models

from accounts.models import CustomUser
from recipes.models import Recipe


class GroceryBag(models.Model):
    """A user's single active grocery bag.

    The bag stores *membership* (which recipes, at what servings) and per-item
    user overrides. The shoppable ingredient list itself is derived on read by
    ``grocery.aggregator.aggregate_ingredients`` — never stored — so it always
    reflects the current recipes. See docs/plans/grocery-bag-implementation.md §4.
    """
    user = models.OneToOneField(
        CustomUser, on_delete=models.CASCADE, related_name="grocery_bag"
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"GroceryBag(user={self.user_id})"


class GroceryBagRecipe(models.Model):
    """A recipe queued into a bag, at a chosen number of servings."""
    bag = models.ForeignKey(
        GroceryBag, on_delete=models.CASCADE, related_name="bag_recipes"
    )
    recipe = models.ForeignKey(Recipe, on_delete=models.CASCADE)
    servings = models.PositiveIntegerField(default=1)
    added_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ("bag", "recipe")
        ordering = ["-added_at"]

    def __str__(self):
        return f"{self.recipe_id} x{self.servings} in bag {self.bag_id}"


class GroceryItemOverride(models.Model):
    """A per-item user action on the computed list.

    ``item_key`` is the aggregator's stable line key (``ci:<id>`` or
    ``name:<norm>`` — see ``ShoppableLine.key``); a single non-null string so the
    uniqueness constraint behaves. ``removed`` hides the line from this bag;
    ``checked`` ticks it off in the shopping UI.
    """
    REMOVED = "removed"
    CHECKED = "checked"
    STATE_CHOICES = [(REMOVED, "Removed"), (CHECKED, "Checked")]

    bag = models.ForeignKey(
        GroceryBag, on_delete=models.CASCADE, related_name="overrides"
    )
    item_key = models.CharField(max_length=300)
    state = models.CharField(max_length=16, choices=STATE_CHOICES)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ("bag", "item_key")

    def __str__(self):
        return f"{self.item_key}={self.state} (bag {self.bag_id})"
