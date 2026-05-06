from rest_framework import status, permissions, generics, viewsets
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.throttling import UserRateThrottle
from django.contrib.auth.models import User
from rest_framework_simplejwt.views import TokenObtainPairView
from django.core.cache import cache
from django.db.models import Q
import math
import json
import hashlib

from .models import LieuTouristique, Favori, CategorieLieu, ItineraireEnregistre
from .serializers import (
    LieuTouristiqueSerializer, 
    RegisterSerializer, 
    FavoriSerializer,
    CategorieLieuSerializer,
    ItineraireEnregistreSerializer
)

# --- AUTHENTIFICATION ---
class MyTokenObtainPairView(TokenObtainPairView):
    permission_classes = (permissions.AllowAny,)

class RegisterView(generics.CreateAPIView):
    queryset = User.objects.all()
    permission_classes = (permissions.AllowAny,)
    serializer_class = RegisterSerializer

# --- LIEUX ET CATÉGORIES ---
@api_view(['GET'])
def liste_lieux(request):
    query = request.query_params.get('search', '').strip()
    lieux = LieuTouristique.objects.select_related('categorie').all()

    if query:
        lieux = lieux.filter(
            Q(nom__icontains=query)
            | Q(description__icontains=query)
            | Q(adresse__icontains=query)
            | Q(categorie__nom__icontains=query)
        )

    serializer = LieuTouristiqueSerializer(lieux, many=True)
    return Response(serializer.data)

@api_view(['GET'])
def liste_categories(request):
    categories = CategorieLieu.objects.all()
    serializer = CategorieLieuSerializer(categories, many=True)
    return Response(serializer.data)

# --- FAVORIS ---
@api_view(['GET', 'POST'])
@permission_classes([permissions.IsAuthenticated])
def manage_favorites(request):
    if request.method == 'GET':
        favs = Favori.objects.filter(user=request.user)
        serializer = FavoriSerializer(favs, many=True)
        return Response(serializer.data)
    
    elif request.method == 'POST':
        serializer = FavoriSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(user=request.user)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

# --- HELPER: Calcul distance Haversine (optimisé) ---
def calculate_distance(lat1, lon1, lat2, lon2):
    """Calcule la distance en km entre deux points GPS"""
    R = 6371  # Rayon de la Terre en km
    
    lat1_rad = math.radians(lat1)
    lat2_rad = math.radians(lat2)
    delta_lat = math.radians(lat2 - lat1)
    delta_lon = math.radians(lon2 - lon1)
    
    a = math.sin(delta_lat / 2)**2 + math.cos(lat1_rad) * math.cos(lat2_rad) * math.sin(delta_lon / 2)**2
    c = 2 * math.asin(math.sqrt(a))
    
    return R * c

# --- ITINÉRAIRES (Optimisé) ---
@api_view(['POST'])
@permission_classes([permissions.AllowAny])
def generate_itinerary(request):
    """
    Génère un itinéraire entre deux lieux.
    Reçoit: {'origin': 'Lieu A', 'destination': 'Lieu B'}
    Retourne: {'steps': [{'name': '...', 'distance': '...', 'duration': '...'}]}
    """
    origin = request.data.get('origin', '').strip()
    destination = request.data.get('destination', '').strip()
    
    if not origin or not destination:
        return Response(
            {'error': 'Origin et destination requis'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # Vérification entrée
    if len(origin) > 255 or len(destination) > 255:
        return Response(
            {'error': 'Texte trop long'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # Créer une clé de cache
    cache_key = f"itinerary:{hashlib.md5(f'{origin}|{destination}'.encode()).hexdigest()}"
    cached_result = cache.get(cache_key)
    if cached_result:
        return Response(cached_result, status=status.HTTP_200_OK)
    
    try:
        # Chercher les lieux correspondant au nom (icontains pour la flexibilité)
        origin_lieu = LieuTouristique.objects.filter(nom__icontains=origin).first()
        destination_lieu = LieuTouristique.objects.filter(nom__icontains=destination).first()
        
        # Fallback: si pas trouvé, prendre aléatoirement
        if not origin_lieu:
            origin_lieu = LieuTouristique.objects.first()
        if not destination_lieu:
            destination_lieu = LieuTouristique.objects.filter(~Q(id=origin_lieu.id)).first()
        
        if not origin_lieu or not destination_lieu:
            return Response({'steps': []}, status=status.HTTP_200_OK)
        
        # Générer les étapes
        steps = []
        
        # Étape 1: Point de départ
        steps.append({
            'name': origin or origin_lieu.nom,
            'distance': '0 km',
            'duration': '0 min'
        })
        
        # Calculer la distance totale
        current_lat, current_lon = origin_lieu.latitude, origin_lieu.longitude
        destination_lat, destination_lon = destination_lieu.latitude, destination_lieu.longitude
        total_distance = calculate_distance(current_lat, current_lon, destination_lat, destination_lon)
        
        # Récupérer SEULEMENT les lieux intermédiaires utiles (pas tous!)
        # Filtre: lieux qui ne sont pas origin ni destination
        max_radius = total_distance * 1.5  # Rayon de recherche
        
        intermediate_lieux = []
        
        # Requête optimisée: récupérer seulement les colonnes nécessaires
        for lieu in LieuTouristique.objects.exclude(
            id__in=[origin_lieu.id, destination_lieu.id]
        ).values('id', 'nom', 'latitude', 'longitude'):
            # Vérifier si le lieu est approximativement sur le chemin
            dist_origin = calculate_distance(current_lat, current_lon, lieu['latitude'], lieu['longitude'])
            
            # Sauter si trop loin de l'origine
            if dist_origin > max_radius:
                continue
            
            dist_destination = calculate_distance(lieu['latitude'], lieu['longitude'], destination_lat, destination_lon)
            
            # Garder les lieux qui ne dépassent pas trop la route directe
            if dist_origin + dist_destination <= total_distance * 1.3:
                intermediate_lieux.append({
                    'id': lieu['id'],
                    'nom': lieu['nom'],
                    'lat': lieu['latitude'],
                    'lon': lieu['longitude'],
                    'dist_origin': dist_origin
                })
        
        # Trier par distance depuis l'origine ET limiter à 5
        intermediate_lieux.sort(key=lambda x: x['dist_origin'])
        
        # Ajouter les étapes intermédiaires (max 5)
        for lieu in intermediate_lieux[:5]:
            segment_distance = calculate_distance(current_lat, current_lon, lieu['lat'], lieu['lon'])
            
            # Estimer la durée (à pied: ~5 km/h)
            duration_minutes = int((segment_distance / 5) * 60) + 15
            
            steps.append({
                'name': lieu['nom'],
                'distance': f'{segment_distance:.1f} km',
                'duration': f'{duration_minutes} min'
            })
            
            current_lat, current_lon = lieu['lat'], lieu['lon']
        
        # Étape finale: destination
        final_distance = calculate_distance(current_lat, current_lon, destination_lat, destination_lon)
        final_duration = int((final_distance / 5) * 60)
        
        steps.append({
            'name': destination or destination_lieu.nom,
            'distance': f'{final_distance:.1f} km',
            'duration': f'{final_duration} min'
        })
        
        result = {'steps': steps}
        
        # Mettre en cache pour 1 heure
        cache.set(cache_key, result, 3600)
        
        # Sauvegarder l'itinéraire si l'utilisateur est authentifié
        if request.user.is_authenticated:
            ItineraireEnregistre.objects.create(
                user=request.user,
                depart_nom=origin or origin_lieu.nom,
                arrivee_nom=destination or destination_lieu.nom,
                points_gps=json.dumps([(p['lat'], p['lon']) for p in intermediate_lieux]),
                nom=f"Itinéraire {origin} -> {destination}"
            )
        
        return Response(result, status=status.HTTP_200_OK)
    
    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )