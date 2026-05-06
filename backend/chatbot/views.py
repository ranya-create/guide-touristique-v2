from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from django_ratelimit.decorators import ratelimit
from django.utils.decorators import method_decorator
from groq import Groq
import os
from dotenv import load_dotenv

load_dotenv()

@method_decorator(ratelimit(key='ip', rate='30/m', block=True), name='dispatch')
class ChatbotView(APIView):
    def post(self, request):
        message = request.data.get('message')
        history = request.data.get('history', [])

        if not message:
            return Response(
                {'error': 'Le message est obligatoire'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            client = Groq(api_key=os.getenv('GROQ_API_KEY'))

            messages = [
                {
                    "role": "system",
                    "content": """Tu es un guide touristique expert du Maroc. 
                    Tu aides les touristes à découvrir les meilleurs endroits, 
                    restaurants, hôtels et activités. Tu réponds en français 
                    de manière amicale et détaillée."""
                }
            ]

            for msg in history:
                messages.append({
                    "role": msg['role'],
                    "content": msg['content']
                })

            messages.append({
                "role": "user",
                "content": message
            })

            completion = client.chat.completions.create(
                model="llama-3.3-70b-versatile",
                messages=messages,
                temperature=0.7,
                max_tokens=1000,
            )

            response_text = completion.choices[0].message.content

            return Response({
                'status': 'success',
                'response': response_text
            })

        except Exception as e:
            print(f"Exception : {str(e)}")
            return Response(
                {'error': f'Erreur serveur : {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )