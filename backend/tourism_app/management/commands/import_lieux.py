import requests
from django.core.management.base import BaseCommand
from django.core.files.base import ContentFile
from tourism_app.models import LieuTouristique, CategorieLieu

class Command(BaseCommand):
    help = 'Importe les lieux touristiques avec images depuis OpenStreetMap et Wikipedia'

    def handle(self, *args, **options):
        villes = [
            ('Casablanca', 33.5731, -7.5898),
            ('Rabat', 34.0209, -6.8416),
            ('Marrakech', 31.6295, -7.9811),
            ('Fès', 34.0331, -5.0003),
        ]

        for ville, lat, lon in villes:
            self.stdout.write(f'Importation des lieux de {ville}...')
            self.importer_ville(ville, lat, lon)

        self.stdout.write(self.style.SUCCESS('Importation terminée !'))

    def get_wikipedia_image(self, nom_lieu):
        try:
            search_url = 'https://fr.wikipedia.org/api/rest_v1/page/summary/' + \
                         requests.utils.quote(nom_lieu)
            headers = {'User-Agent': 'GuideTouristique/1.0 (student project)'}
            response = requests.get(search_url, headers=headers, timeout=10)
            if response.status_code == 200:
                data = response.json()
                thumbnail = data.get('thumbnail')
                if thumbnail:
                    image_url = thumbnail.get('source', '').replace(
                        '/200px-', '/800px-'
                    )
                    if image_url:
                        img_response = requests.get(
                            image_url, headers=headers, timeout=15
                        )
                        if img_response.status_code == 200:
                            return img_response.content, image_url
        except Exception:
            pass
        return None, None

    def importer_ville(self, ville, lat, lon):
        query = f"""
        [out:json][timeout:25];
        (
          node["historic"~"mosque|castle|ruins|monument|memorial|fort"](around:8000,{lat},{lon});
          node["tourism"="museum"](around:8000,{lat},{lon});
          node["tourism"="attraction"]["name"](around:8000,{lat},{lon});
          node["amenity"="place_of_worship"]["name"](around:5000,{lat},{lon});
        );
        out body;
        """

        try:
            headers = {
                'User-Agent': 'GuideTouristique/1.0 (student project)',
                'Content-Type': 'application/x-www-form-urlencoded'
            }
            response = requests.post(
                'https://overpass-api.de/api/interpreter',
                data={'data': query},
                headers=headers,
                timeout=30
            )
        except Exception as e:
            self.stdout.write(f'Erreur connexion pour {ville}: {e}')
            return

        if response.status_code != 200:
            self.stdout.write(f'Erreur API pour {ville} - status: {response.status_code}')
            return

        data = response.json()
        elements = data.get('elements', [])
        count = 0

        for element in elements:
            tags = element.get('tags', {})
            nom = tags.get('name:fr') or tags.get('name')

            if not nom or len(nom) < 3:
                continue

            lat_lieu = element.get('lat')
            lon_lieu = element.get('lon')

            if not lat_lieu or not lon_lieu:
                continue

            # Catégorie
            historic = tags.get('historic', '')
            tourism = tags.get('tourism', '')
            amenity = tags.get('amenity', '')

            if tourism == 'museum':
                cat_nom = 'Musée'
            elif historic in ['mosque', 'place_of_worship'] or \
                 amenity == 'place_of_worship':
                cat_nom = 'Mosquée'
            elif historic in ['castle', 'fort', 'ruins']:
                cat_nom = 'Monument'
            elif historic == 'memorial':
                cat_nom = 'Mémorial'
            else:
                cat_nom = 'Attraction'

            categorie, _ = CategorieLieu.objects.get_or_create(nom=cat_nom)

            description = tags.get('description:fr') or \
                          tags.get('description') or \
                          f'{nom} est un site touristique situé à {ville}, Maroc.'

            adresse = tags.get('addr:full') or \
                      tags.get('addr:street') or \
                      f'{ville}, Maroc'

            lieu, created = LieuTouristique.objects.get_or_create(
                nom=nom,
                defaults={
                    'description': description,
                    'adresse': adresse,
                    'latitude': lat_lieu,
                    'longitude': lon_lieu,
                    'categorie': categorie,
                }
            )

            if created:
                count += 1
                self.stdout.write(f'  Recherche image pour: {nom}')
                image_content, image_url = self.get_wikipedia_image(nom)

                if image_content:
                    # Nettoyage de l'extension de fichier
                    ext = image_url.split('.')[-1].split('?')[0].lower()
                    if ext not in ['jpg', 'jpeg', 'png', 'webp']:
                        ext = 'jpg'
                    # Nettoyage du nom de fichier pour Windows
                    clean_name = "".join(c for c in nom[:50] if c.isalnum() or c in (' ', '_')).replace(' ', '_')
                    filename = f"{clean_name}.{ext}"
                    lieu.image.save(
                        filename, ContentFile(image_content), save=True
                    )
                    self.stdout.write(f'  ✓ Image sauvegardée pour {nom}')
                else:
                    self.stdout.write(f'  ✗ Pas d image pour {nom}')

        self.stdout.write(f'{count} lieux ajoutés pour {ville}')