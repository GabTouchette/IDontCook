import random
import uuid

from django.utils import timezone
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from .collectors import FeedContext, collect_modules
from .greetings import get_greeting
from .ranking import MOODS, compute_daypart, rank_modules


class HomeFeedView(APIView):
    """GET /api/home/feed/?local_hour=17&weekday=4&mood=rushed

    Returns the plan §1.5 adaptive home feed. Daypart is computed from the
    client-provided local hour — never the server clock.
    """

    permission_classes = [IsAuthenticated]

    def get(self, request):
        local_hour = self._parse_int(request.query_params.get('local_hour'))
        if local_hour is None or not 0 <= local_hour <= 23:
            return Response(
                {'error': 'local_hour is required and must be an integer between 0 and 23.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        weekday = self._parse_int(request.query_params.get('weekday'))
        if weekday is None or not 0 <= weekday <= 6:
            return Response(
                {'error': 'weekday is required and must be an integer between 0 (Monday) and 6 (Sunday).'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        mood = request.query_params.get('mood') or None
        if mood is not None and mood not in MOODS:
            return Response(
                {'error': f"mood must be one of: {', '.join(MOODS)}."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        daypart = compute_daypart(local_hour)
        is_weekend = weekday in (5, 6)
        now = timezone.now()

        # Fresh per-request variety component so refresh / mood re-rank rotate
        # the greeting, prompt, theme and hero pick rather than returning the
        # exact same feed within a day (the day-of-year rotation is the stable
        # base; this is what makes a pull-to-refresh actually feel different).
        ctx = FeedContext(
            user=request.user,
            now=now,
            daypart=daypart,
            is_weekend=is_weekend,
            mood=mood,
            variety_seed=random.randint(0, 10_000),
        )
        candidates = collect_modules(ctx)
        modules = rank_modules(candidates, daypart, is_weekend, mood, saved_count=ctx.saved_count)

        greeting = get_greeting(daypart, mood, seed=ctx.copy_seed)
        blocks = [{'block_type': 'text', 'text': greeting}]
        blocks.extend({'block_type': 'module', 'module': module} for module in modules)

        return Response({
            'feed_id': str(uuid.uuid4()),
            'context': {'daypart': daypart, 'is_weekend': is_weekend, 'mood': mood},
            'greeting': greeting,
            'blocks': blocks,
        })

    @staticmethod
    def _parse_int(value):
        if value is None:
            return None
        try:
            return int(value)
        except (TypeError, ValueError):
            return None
