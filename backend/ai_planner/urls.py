from django.urls import path
from .views import AiPlannerView

urlpatterns = [
    path('', AiPlannerView.as_view(), name='ai-planner'),
]