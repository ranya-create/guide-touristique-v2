from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    path('admin/', admin.site.urls),

    # ── Apps existantes ────────────────────────────────────
    path('api/', include('tourism_app.urls')),
    path('api/users/', include('users.urls')),

    # ── Apps de Ranya (ajoutées) ───────────────────────────
    path('api/ai-planner/', include('ai_planner.urls')),
    path('api/ai-program/', include('ai_program.urls')),
    path('api/chatbot/', include('chatbot.urls')),
    path('api/itinerary/', include('itinerary.urls')),

] + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)