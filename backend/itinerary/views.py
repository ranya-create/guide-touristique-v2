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

            origin_response = requests.get(geocode_url, params={
                'api_key': api_key,
                'text': origin,
                'size': 1
            })
            origin_data = origin_response.json()
            origin_coords = origin_data['features'][0]['geometry']['coordinates']

            dest_response = requests.get(geocode_url, params={
                'api_key': api_key,
                'text': destination,
                'size': 1
            })
            dest_data = dest_response.json()
            dest_coords = dest_data['features'][0]['geometry']['coordinates']

            route_url = 'https://api.openrouteservice.org/v2/directions/driving-car'
            headers = {
                'Authorization': api_key,
                'Content-Type': 'application/json'
            }
            body = {
                'coordinates': [origin_coords, dest_coords]
            }

            route_response = requests.post(route_url, json=body, headers=headers)
            route_data = route_response.json()

            segments = route_data['routes'][0]['segments'][0]['steps']
            steps = []

            for i, step in enumerate(segments):
                steps.append({
                    'name': step.get('instruction', f'Étape {i+1}'),
                    'distance': f"{round(step['distance'] / 1000, 1)} km",
                    'duration': f"{round(step['duration'] / 60)} min",
                })

            total = route_data['routes'][0]['summary']

            return Response({
                'status': 'success',
                'origin': origin,
                'destination': destination,
                'total_distance': f"{round(total['distance'] / 1000, 1)} km",
                'total_duration': f"{round(total['duration'] / 60)} min",
                'steps': steps
            })

        except Exception as e:
            print(f"Exception : {str(e)}")
            return Response(
                {'error': f'Erreur serveur : {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )