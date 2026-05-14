from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from django_ratelimit.decorators import ratelimit
from django.utils.decorators import method_decorator
import requests
import os
from dotenv import load_dotenv

load_dotenv()

@method_decorator(ratelimit(key='ip', rate='20/m', block=True), name='dispatch')
class ItineraryView(APIView):
    def post(self, request):
        origin = request.data.get('origin')
        destination = request.data.get('destination')

        if not origin or not destination:
            return Response(
                {'error': 'Le départ et la destination sont obligatoires'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            api_key = os.getenv('ORS_API_KEY')

            geocode_url = 'https://api.openrouteservice.org/geocode/search'

            # Géocodage avec contrainte Maroc
            origin_response = requests.get(geocode_url, params={
                'api_key': api_key,
                'text': origin,
                'size': 1,
                'boundary.country': 'MA'  # Limiter au Maroc
            })
            origin_data = origin_response.json()
            
            # Validation du résultat
            if not origin_data.get('features') or len(origin_data['features']) == 0:
                return Response(
                    {'error': f'Lieu de départ "{origin}" non trouvé au Maroc'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            origin_coords = origin_data['features'][0]['geometry']['coordinates']

            # Géocodage destination avec contrainte Maroc
            dest_response = requests.get(geocode_url, params={
                'api_key': api_key,
                'text': destination,
                'size': 1,
                'boundary.country': 'MA'  # Limiter au Maroc
            })
            dest_data = dest_response.json()
            
            # Validation du résultat
            if not dest_data.get('features') or len(dest_data['features']) == 0:
                return Response(
                    {'error': f'Destination "{destination}" non trouvée au Maroc'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            dest_coords = dest_data['features'][0]['geometry']['coordinates']

            route_url = 'https://api.openrouteservice.org/v2/directions/driving-car'
            headers = {
                'Authorization': api_key,
                'Content-Type': 'application/json'
            }
            body = {
                'coordinates': [origin_coords, dest_coords],
                'format': 'geojson'  # Get coordinates directly instead of encoded polyline
            }

            route_response = requests.post(route_url, json=body, headers=headers)
            route_data = route_response.json()
            
            # Vérifier si une route a été trouvée
            if not route_data.get('routes') or len(route_data['routes']) == 0:
                return Response(
                    {'error': 'Aucune route n\'a pu être calculée entre ces deux lieux'},
                    status=status.HTTP_400_BAD_REQUEST
                )

            segments = route_data['routes'][0]['segments'][0]['steps']
            steps = []

            for i, step in enumerate(segments):
                steps.append({
                    'name': step.get('instruction', f'Étape {i+1}'),
                    'distance': f"{round(step['distance'] / 1000, 1)} km",
                    'duration': f"{round(step['duration'] / 60)} min",
                })

            total = route_data['routes'][0]['summary']

            # Extract route coordinates from geojson geometry
            route_coords = []
            if 'geometry' in route_data['routes'][0] and 'coordinates' in route_data['routes'][0]['geometry']:
                # GeoJSON format: [lng, lat] -> convert to [lat, lng]
                for coord in route_data['routes'][0]['geometry']['coordinates']:
                    route_coords.append([coord[1], coord[0]])  # [lat, lng]

            return Response({
                'status': 'success',
                'origin': origin,
                'destination': destination,
                'total_distance': f"{round(total['distance'] / 1000, 1)} km",
                'total_duration': f"{round(total['duration'] / 60)} min",
                'steps': steps,
                'route': route_coords  # Add the route coordinates
            })

        except Exception as e:
            print(f"Exception : {str(e)}")
            return Response(
                {'error': f'Erreur serveur : {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )