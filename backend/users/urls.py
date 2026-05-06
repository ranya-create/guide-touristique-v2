from django.urls import path
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from . import views

urlpatterns = [
    # Existants (inchangés)
    path('register/', views.register),
    path('login/', TokenObtainPairView.as_view()),
    path('token/refresh/', TokenRefreshView.as_view()),
    path('profil/', views.profil),
    path('favoris/', views.liste_favoris),
    path('favoris/ajouter/', views.ajouter_favori),
    path('favoris/<int:lieu_id>/', views.supprimer_favori),
    path('listes/', views.listes),
    path('listes/<int:liste_id>/', views.supprimer_liste),

    # NOUVEAUX
    path('profile/', views.profile_view),           # GET / PATCH
    path('change-password/', views.change_password_view),  # POST
]