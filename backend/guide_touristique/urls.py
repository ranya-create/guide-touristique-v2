from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/itinerary/', include('itinerary.urls')),
    path('api/ai-program/', include('ai_planner.urls')),
    path('api/chatbot/', include('chatbot.urls')),
]