from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from django_ratelimit.decorators import ratelimit
from django.utils.decorators import method_decorator
from groq import Groq
import os
import json
from dotenv import load_dotenv

load_dotenv()

@method_decorator(ratelimit(key='ip', rate='10/m', block=True), name='dispatch')
class AiPlannerView(APIView):
    def post(self, request):
        budget = request.data.get('budget')
        duration = request.data.get('duration')
        preferences = request.data.get('preferences', [])
        location = request.data.get('location')

        if not budget or not duration or not location:
            return Response(
                {'error': 'Budget, durée et ville sont obligatoires'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            client = Groq(api_key=os.getenv('GROQ_API_KEY'))

            prompt = f"""
            Génère un programme touristique personnalisé en JSON pour :
            - Ville : {location}
            - Budget total : {budget} MAD
            - Durée : {duration} jour(s)
            - Préférences : {', '.join(preferences)}

            Réponds UNIQUEMENT avec un JSON valide dans ce format exact :
            {{
                "summary": "résumé court du programme",
                "days": [
                    {{
                        "activities": [
                            {{
                                "name": "nom de l'activité",
                                "description": "description courte",
                                "cost": 50
                            }}
                        ]
                    }}
                ]
            }}
            """

            completion = client.chat.completions.create(
                model="llama-3.3-70b-versatile",
                messages=[
                    {
                        "role": "system",
                        "content": "Tu es un guide touristique expert. Réponds uniquement en JSON valide sans aucun texte supplémentaire."
                    },
                    {
                        "role": "user",
                        "content": prompt
                    }
                ],
                temperature=0.7,
                max_tokens=2000,
            )

            response_text = completion.choices[0].message.content
            response_text = response_text.strip()
            if response_text.startswith('```json'):
                response_text = response_text[7:]
            if response_text.startswith('```'):
                response_text = response_text[3:]
            if response_text.endswith('```'):
                response_text = response_text[:-3]

            program = json.loads(response_text.strip())

            return Response({
                'status': 'success',
                'program': program
            })

        except Exception as e:
            print(f"Exception : {str(e)}")
            return Response(
                {'error': f'Erreur serveur : {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )