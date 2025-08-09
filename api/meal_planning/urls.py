from rest_framework.routers import DefaultRouter
from .views import MealPlanViewSet, PlannedMealViewSet

router = DefaultRouter()
router.register(r'meal-plans', MealPlanViewSet, basename='mealplan')
router.register(r'planned-meals', PlannedMealViewSet, basename='plannedmeal')

urlpatterns = router.urls
