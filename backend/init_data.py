#!/usr/bin/env python
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'django_config.settings')
django.setup()

from tourism_app.models import CategorieLieu, LieuTouristique

# Créer des catégories
cat_monuments, _ = CategorieLieu.objects.get_or_create(nom="Monuments")
cat_musees, _ = CategorieLieu.objects.get_or_create(nom="Musées")
cat_nature, _ = CategorieLieu.objects.get_or_create(nom="Nature")

# Créer des lieux touristiques
lieux_data = [
    {
        "nom": "Tour Eiffel",
        "description": "La Tour Eiffel est un monument de fer puddlé de 330 m de hauteur situé à Paris.",
        "adresse": "5 Avenue Anatole France, 75007 Paris",
        "latitude": 48.8584,
        "longitude": 2.2945,
        "categorie": cat_monuments
    },
    {
        "nom": "Louvre",
        "description": "Le Louvre est le plus grand musée d'art du monde et le plus visité.",
        "adresse": "Rue de Rivoli, 75004 Paris",
        "latitude": 48.8606,
        "longitude": 2.3352,
        "categorie": cat_musees
    },
    {
        "nom": "Montagne Sainte-Victoire",
        "description": "La montagne Sainte-Victoire est une montagne de la région Provence-Alpes-Côte d'Azur.",
        "adresse": "Aix-en-Provence",
        "latitude": 43.5350,
        "longitude": 5.5547,
        "categorie": cat_nature
    },
    {
        "nom": "Notre-Dame de Reims",
        "description": "Cathédrale à Reims, où les rois de France étaient couronnés.",
        "adresse": "Place du Cardinal Luçon, 51100 Reims",
        "latitude": 49.2556,
        "longitude": 4.0344,
        "categorie": cat_monuments
    }
]

for lieu_data in lieux_data:
    LieuTouristique.objects.get_or_create(
        nom=lieu_data["nom"],
        defaults=lieu_data
    )

print("✅ 4 lieux touristiques créés avec succès !")
