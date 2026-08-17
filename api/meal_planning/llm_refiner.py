from __future__ import annotations

from dataclasses import dataclass
from typing import Dict, List, Optional, Tuple, Any
import json
import os

from ai_chatbot.api import AnthropicService


@dataclass(frozen=True)
class SlotSpec:
    day: int
    meal_type: str  # 'breakfast' | 'lunch' | 'dinner' | 'snack'
    current_recipe_id: int
    candidate_ids: List[int]


@dataclass(frozen=True)
class RecipeInfo:
    id: int
    is_saved: bool
    is_own: bool
    cooking_time: Optional[int]
    tags: List[str]


class LLMRefiner:
    """
    Placeholder refiner that mimics an LLM patcher contract.
    In production, wire this to your LLM provider with function-calling/tooling
    and keep this interface stable.
    """

    def refine(
        self,
        *,
        description: str,
        slots: List[SlotSpec],
        recipes: Dict[int, RecipeInfo],
        focus_on_saved: bool = True,
    ) -> Dict[Tuple[int, str], int]:
        """
        Returns a mapping {(day, meal_type) -> recipe_id} as replacement choices.
        Only IDs from the provided candidate_ids for each slot are allowed.
        This stub prefers:
          - saved → own → others (if focus_on_saved)
          - quick meals if description hints at speed
          - otherwise leaves baseline unchanged
        """
        want_quick = any(k in description.lower() for k in [
            'quick', 'fast', '30-min', '30 min', 'under 30', 'rapid', 'express'
        ])

        out: Dict[Tuple[int, str], int] = {}
        used: set[int] = set()

        for s in slots:
            key = (int(s.day), s.meal_type.lower())
            cands = [rid for rid in s.candidate_ids if rid in recipes]
            if not cands:
                continue

            def score(rid: int) -> Tuple[int, int, int]:
                info = recipes.get(rid)
                if not info:
                    return (0, 0, 0)
                saved_boost = 2 if (focus_on_saved and info.is_saved) else 0
                own_boost = 1 if info.is_own else 0
                quick_boost = 0
                if want_quick:
                    try:
                        t = info.cooking_time or 0
                        if t <= 30:
                            quick_boost = 2
                        elif t <= 45:
                            quick_boost = 1
                    except Exception:
                        pass
                # Higher tuple means better
                return (saved_boost + own_boost + quick_boost, - (info.cooking_time or 0), 0)

            # Rank by heuristic score, then prefer not-yet-used
            ranked = sorted(cands, key=score, reverse=True)
            choice = None
            for rid in ranked:
                if rid not in used:
                    choice = rid
                    break
            if choice is None:
                choice = ranked[0]
            used.add(choice)
            # Only propose change if different from baseline
            if choice != s.current_recipe_id:
                out[key] = choice

        return out


class AnthropicRefiner:
    """
    Anthropic-backed refiner producing a list of safe operations:
    - {"op": "replace", "day": int, "meal_type": str, "recipe_id": int}
    - {"op": "remove", "day": int, "meal_type": str}
    - {"op": "swap", "a": {"day": int, "meal_type": str}, "b": {"day": int, "meal_type": str}}

    The server remains the source of truth and validates every op
    against provided slot candidate IDs and existing plan slots.
    """

    def __init__(self, *, model: Optional[str] = None, temperature: float = 0.1, timeout_s: int = 12):
        # Prefer specific env var, fall back to a default small model
        self.model = model or os.getenv('MEAL_PLAN_REFINER_MODEL', 'claude-haiku-4-5')
        self.temperature = temperature
        self.timeout_s = timeout_s
        self._svc = AnthropicService()

    def refine_ops(
        self,
        *,
        description: str,
        slots: List[SlotSpec],
        recipes: Dict[int, RecipeInfo],
        focus_on_saved: bool = True,
    ) -> List[Dict[str, Any]]:
        # Build compact JSON payload
        payload = {
            "description": description or "",
            "focus_on_saved": bool(focus_on_saved),
            "slots": [
                {
                    "day": int(s.day),
                    "meal_type": str(s.meal_type).lower(),
                    "current_recipe_id": int(s.current_recipe_id),
                    "candidate_ids": [int(cid) for cid in s.candidate_ids],
                }
                for s in slots
            ],
            "recipes": {
                int(rid): {
                    "id": int(info.id),
                    "is_saved": bool(info.is_saved),
                    "is_own": bool(info.is_own),
                    "cooking_time": (int(info.cooking_time) if info.cooking_time is not None else None),
                    "tags": list(info.tags or []),
                }
                for rid, info in recipes.items()
            },
        }

        system = (
            "You are a meal-plan refiner. Output ONLY valid JSON (no markdown). "
            "You can propose safe operations over provided slots and candidates. "
            "Operations allowed: replace, remove, swap. "
            "Rules: \n"
            "- replace: choose recipe_id from the slot's candidate_ids only.\n"
            "- remove: you may clear a slot if it improves variety or fits the description better.\n"
            "- swap: you may swap recipes between two existing slots to better fit meal types or description.\n"
            "- Never invent recipe IDs. Never reference slots not in the list.\n"
            "- Prefer saved recipes if focus_on_saved=true. Favor quicker recipes if the description asks for speed.\n"
            "- Keep changes minimal.\n"
        )

        user = (
            "Return a JSON array of operations. Example: "
            "[{\"op\":\"replace\",\"day\":0,\"meal_type\":\"dinner\",\"recipe_id\":123},"
            " {\"op\":\"swap\",\"a\":{\"day\":1,\"meal_type\":\"lunch\"},\"b\":{\"day\":2,\"meal_type\":\"dinner\"}}]"\
        )

        # Call Anthropic messages (non-streaming). This runs synchronously inside
        # the meal-plan generate request, so bound the wall-clock: the SDK
        # default is a 600s timeout x 2 retries. `self.timeout_s` was previously
        # stored but never applied — pass it via with_options, and cap retries so
        # worst-case blocking is ~timeout_s x (max_retries + 1), not minutes.
        try:
            response = self._svc.client.with_options(
                timeout=self.timeout_s, max_retries=1,
            ).messages.create(
                model=self.model,
                max_tokens=2048,
                system=system,
                messages=[
                    {"role": "user", "content": json.dumps(payload) + "\n\n" + user},
                ],
            )
            content = response.content[0].text.strip()
            # Strip accidental fences
            content = content.strip().removeprefix("```json").removesuffix("```").strip()
            ops = json.loads(content)
            if isinstance(ops, list):
                return ops
        except Exception:
            return []
        return []

    # Back-compat: allow replace-only mapping if callers use refine()
    def refine(
        self,
        *,
        description: str,
        slots: List[SlotSpec],
        recipes: Dict[int, RecipeInfo],
        focus_on_saved: bool = True,
    ) -> Dict[Tuple[int, str], int]:
        out: Dict[Tuple[int, str], int] = {}
        ops = self.refine_ops(
            description=description, slots=slots, recipes=recipes, focus_on_saved=focus_on_saved
        )
        for op in ops:
            if isinstance(op, dict) and op.get('op') == 'replace':
                d = int(op.get('day'))
                mt = str(op.get('meal_type')).lower()
                rid = int(op.get('recipe_id'))
                out[(d, mt)] = rid
        return out


def get_refiner() -> object:
    """Factory returning an Anthropic-backed refiner when enabled, else the stub."""
    use_llm = os.getenv('MEAL_PLAN_REFINER_ENABLED', 'false').lower() in ('1', 'true', 'yes', 'on')
    api_key_present = os.getenv('ANTHROPIC_API_KEY')
    if use_llm and api_key_present:
        try:
            return AnthropicRefiner()
        except Exception:
            return LLMRefiner()
    return LLMRefiner()
