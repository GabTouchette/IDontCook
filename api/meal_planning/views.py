from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated

from .models import MealPlan, PlannedMeal, GroceryList
from .serializers import MealPlanSerializer, PlannedMealSerializer, GroceryListSerializer


class MealPlanViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated]
    serializer_class = MealPlanSerializer

    def get_queryset(self):
        return MealPlan.objects.filter(user=self.request.user).order_by('-week_start_date')

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

    @action(detail=True, methods=['post'])
    def generate(self, request, pk=None):
        # Placeholder for AI generation integration
        return Response({"success": True, "message": "Meal plan generation started"})

    @action(detail=True, methods=['get'])
    def grocery_list(self, request, pk=None):
        meal_plan = self.get_object()
        gl, _ = GroceryList.objects.get_or_create(meal_plan=meal_plan)
        return Response(GroceryListSerializer(gl).data)

    @action(detail=True, methods=['post'], url_path='grocery-list/purchase')
    def purchase_items(self, request, pk=None):
        meal_plan = self.get_object()
        gl, _ = GroceryList.objects.get_or_create(meal_plan=meal_plan)
        purchased = request.data.get('purchased_items', [])
        gl.purchased_items = purchased
        gl.save()
        return Response({"success": True})


class PlannedMealViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated]
    serializer_class = PlannedMealSerializer

    def get_queryset(self):
        return PlannedMeal.objects.filter(meal_plan__user=self.request.user)
