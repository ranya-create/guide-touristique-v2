from django.contrib import admin
from .models import LieuTouristique, CategorieLieu

@admin.register(CategorieLieu)
class CategorieLieuAdmin(admin.ModelAdmin):
    list_display = ('nom',)

@admin.register(LieuTouristique)
class LieuTouristiqueAdmin(admin.ModelAdmin):
    list_display = ('nom', 'categorie', 'latitude', 'longitude')
    list_filter = ('categorie',)
    search_fields = ('nom', 'description')