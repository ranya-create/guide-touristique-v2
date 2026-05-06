from django.urls import path
from . import views
from rest_framework_simplejwt.views import (
    TokenObtainPairView,
    TokenRefreshView,
)

urlpatterns = [
    # --- LIEUX ET CATÉGORIES ---
    path('lieux/', views.liste_lieux, name='liste_lieux'),
    path('categories/', views.liste_categories, name='liste_categories'),

    # --- AUTHENTIFICATION ---
    path('auth/register/', views.RegisterView.as_view(), name='auth_register'),
    path('auth/login/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('auth/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),

    # --- FAVORIS ---
    path('favoris/', views.manage_favorites, name='manage_favorites'),
    
    # --- ITINÉRAIRES ---
    path('itinerary/', views.generate_itinerary, name='generate_itinerary'),
]