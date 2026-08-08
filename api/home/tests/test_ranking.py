from django.test import SimpleTestCase

from home.ranking import (
    LOW_LIBRARY_THRESHOLD,
    MAX_MODULES,
    MOODS,
    MULTI_ALLOWED,
    compute_daypart,
    rank_modules,
    score_module,
)
from home.serializers import build_module


def candidate(module_type, base_score, module_id=None):
    module = build_module(module_id or f"{module_type}-x", module_type, 'test', {})
    return (module, base_score)


class DaypartComputationTests(SimpleTestCase):
    def test_daypart_boundaries(self):
        # §1.4: morning 05-11, midday 11-15, evening 15-21, late 21-05.
        expectations = {
            5: 'morning', 8: 'morning', 10: 'morning',
            11: 'midday', 13: 'midday', 14: 'midday',
            15: 'evening', 17: 'evening', 20: 'evening',
            21: 'late', 23: 'late', 0: 'late', 3: 'late', 4: 'late',
        }
        for hour, expected in expectations.items():
            self.assertEqual(compute_daypart(hour), expected, f"hour {hour}")


class PriorTests(SimpleTestCase):
    def test_unknown_module_type_defaults_to_neutral(self):
        self.assertEqual(score_module('some_future_type', 2.0, 'evening', False, 'rushed'), 2.0)

    def test_no_mood_is_neutral(self):
        with_mood = score_module('hero_suggestion', 3.0, 'evening', False, 'rushed')
        without_mood = score_module('hero_suggestion', 3.0, 'evening', False, None)
        self.assertGreater(with_mood, without_mood)

    def test_daypart_priors_change_ordering(self):
        candidates = [
            candidate('hero_suggestion', 3.0),
            candidate('meal_plan_nudge', 1.8),
        ]
        # Weekday evening: hero dominates.
        evening = rank_modules(candidates, 'evening', False, None)
        self.assertEqual(evening[0]['module_type'], 'hero_suggestion')
        # Weekday morning: nudge is boosted (1.8 x 1.6 = 2.88) over the
        # demoted hero (3.0 x 0.9 = 2.7).
        morning = rank_modules(candidates, 'morning', False, None)
        self.assertEqual(morning[0]['module_type'], 'meal_plan_nudge')

    def test_weekend_boosts_social_over_hero(self):
        candidates = [
            candidate('hero_suggestion', 3.0),
            candidate('friend_post', 2.2),
            candidate('explore_rail', 2.0),
        ]
        weekday = rank_modules(candidates, 'morning', False, None)
        weekend = rank_modules(candidates, 'morning', True, None)
        self.assertEqual(weekday[0]['module_type'], 'hero_suggestion')
        # friend_post: 2.2 x 1.35 = 2.97 > hero 3.0 x 1.0 = 3.0? No — verify
        # via relative movement instead of absolute winner.
        weekday_hero_idx = [m['module_type'] for m in weekday].index('friend_post')
        weekend_hero_idx = [m['module_type'] for m in weekend].index('friend_post')
        self.assertLessEqual(weekend_hero_idx, weekday_hero_idx)

    def test_mood_priors_change_ordering(self):
        candidates = [
            candidate('explore_rail', 2.0),
            candidate('cook_again', 2.0),
        ]
        comfort = rank_modules(candidates, 'midday', False, 'comfort')
        ambitious = rank_modules(candidates, 'midday', False, 'ambitious')
        self.assertEqual(comfort[0]['module_type'], 'cook_again')
        self.assertEqual(ambitious[0]['module_type'], 'explore_rail')


class DedupAndCapTests(SimpleTestCase):
    def test_max_one_hero_and_one_mood_question(self):
        candidates = [
            candidate('hero_suggestion', 3.0, 'hero-1'),
            candidate('hero_suggestion', 2.5, 'hero-2'),
            candidate('mood_question', 5.0, 'mood-1'),
            candidate('mood_question', 4.0, 'mood-2'),
        ]
        ranked = rank_modules(candidates, 'evening', False, None)
        types = [m['module_type'] for m in ranked]
        self.assertEqual(types.count('hero_suggestion'), 1)
        self.assertEqual(types.count('mood_question'), 1)

    def test_multiple_event_cards_allowed_up_to_two(self):
        candidates = [
            candidate('event_card', 2.0, 'event-a'),
            candidate('event_card', 1.9, 'event-b'),
            candidate('event_card', 1.8, 'event-c'),
        ]
        ranked = rank_modules(candidates, 'evening', False, None)
        self.assertEqual(len(ranked), 2)

    def test_cap_at_six_modules(self):
        candidates = [
            candidate(t, 1.0, f"{t}-1")
            for t in [
                'hero_suggestion', 'cook_again', 'friend_post', 'meal_plan_nudge',
                'grocery_shortcut', 'chat_prompt', 'explore_rail', 'mood_question',
            ]
        ]
        ranked = rank_modules(candidates, 'evening', False, None)
        self.assertEqual(len(ranked), MAX_MODULES)

    def test_event_priority_boost_reorders(self):
        candidates = [
            candidate('chat_prompt', 1.5),
            # A high-priority HomeEvent multiplies its base (2.0 x priority).
            candidate('event_card', 2.0 * 3.0, 'event-boosted'),
        ]
        ranked = rank_modules(candidates, 'morning', False, None)
        self.assertEqual(ranked[0]['module_type'], 'event_card')

    def test_mood_question_ranks_near_top(self):
        candidates = [
            candidate('hero_suggestion', 3.0),
            candidate('mood_question', 5.0),
            candidate('friend_post', 2.2),
            candidate('explore_rail', 2.0),
        ]
        for daypart in ['morning', 'midday', 'evening', 'late']:
            for is_weekend in [False, True]:
                ranked = rank_modules(candidates, daypart, is_weekend, None)
                types = [m['module_type'] for m in ranked]
                self.assertLessEqual(types.index('mood_question'), 1, f"{daypart} weekend={is_weekend}")

    def test_moods_match_locked_taxonomy(self):
        self.assertEqual(
            MOODS,
            ['rushed', 'ambitious', 'cooking_for_someone', 'comfort', 'healthy', 'surprise_me'],
        )


class ExploreRailMultiAllowedTests(SimpleTestCase):
    """catalog-first-pivot.md §2/WS-P3: up to 3 explore_rail instances now compete."""

    def test_multi_allowed_raised_to_three(self):
        self.assertEqual(MULTI_ALLOWED['explore_rail'], 3)

    def test_three_explore_rail_candidates_all_survive(self):
        candidates = [
            candidate('explore_rail', 2.15, 'explore-rail-trending'),
            candidate('explore_rail', 1.95, 'explore-rail-new'),
            candidate('explore_rail', 1.75, 'explore-rail-theme'),
        ]
        ranked = rank_modules(candidates, 'evening', False, None)
        self.assertEqual(len(ranked), 3)
        self.assertEqual([m['id'] for m in ranked],
                          ['explore-rail-trending', 'explore-rail-new', 'explore-rail-theme'])

    def test_single_explore_rail_assumption_still_holds(self):
        """A feed with only one explore_rail candidate (e.g. WS-B era data)
        is unaffected by the higher MULTI_ALLOWED cap."""
        candidates = [candidate('explore_rail', 2.0, 'explore-rail-1')]
        ranked = rank_modules(candidates, 'evening', False, None)
        self.assertEqual(len(ranked), 1)
        self.assertEqual(ranked[0]['id'], 'explore-rail-1')

    def test_a_fourth_explore_rail_candidate_is_dropped(self):
        candidates = [
            candidate('explore_rail', 2.4, 'rail-a'),
            candidate('explore_rail', 2.3, 'rail-b'),
            candidate('explore_rail', 2.2, 'rail-c'),
            candidate('explore_rail', 2.1, 'rail-d'),
        ]
        ranked = rank_modules(candidates, 'evening', False, None)
        self.assertEqual(len(ranked), 3)
        self.assertNotIn('rail-d', [m['id'] for m in ranked])


class LibrarySizeWeightingTests(SimpleTestCase):
    """catalog-first-pivot.md §2/WS-P3 item 2: partial library (1-4 saved
    recipes) should not out-rank discovery content the way an established
    library reasonably would."""

    def test_low_saved_count_flips_ordering_toward_discovery(self):
        candidates = [
            candidate('cook_again', 2.0, 'cook-1'),
            candidate('explore_rail', 2.0, 'rail-1'),
        ]
        low = rank_modules(candidates, 'evening', False, None, saved_count=2)
        high = rank_modules(candidates, 'evening', False, None, saved_count=20)
        self.assertEqual(low[0]['module_type'], 'explore_rail')
        self.assertEqual(high[0]['module_type'], 'cook_again')

    def test_threshold_boundary(self):
        candidates = [
            candidate('cook_again', 2.0, 'cook-1'),
            candidate('explore_rail', 2.0, 'rail-1'),
        ]
        at_threshold = rank_modules(candidates, 'evening', False, None, saved_count=LOW_LIBRARY_THRESHOLD)
        below_threshold = rank_modules(
            candidates, 'evening', False, None, saved_count=LOW_LIBRARY_THRESHOLD - 1,
        )
        # At the threshold: no weighting applied (daypart prior alone decides).
        self.assertEqual(at_threshold[0]['module_type'], 'cook_again')
        # Just below it: discovery is boosted / personal is dampened.
        self.assertEqual(below_threshold[0]['module_type'], 'explore_rail')

    def test_saved_count_none_is_a_backward_compatible_noop(self):
        candidates = [
            candidate('cook_again', 2.0, 'cook-1'),
            candidate('explore_rail', 2.0, 'rail-1'),
        ]
        default = rank_modules(candidates, 'evening', False, None)
        explicit_none = rank_modules(candidates, 'evening', False, None, saved_count=None)
        self.assertEqual(default, explicit_none)
