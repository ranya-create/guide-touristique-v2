from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.contrib.auth.models import User
from tourism_app.models import Favori, ListePerso
from .serializers import (
    RegisterSerializer, UserSerializer,
    FavoriSerializer, ListePersoSerializer,
    UserProfileSerializer, ChangePasswordSerializer,  # NOUVEAU
)


@api_view(['POST'])
def register(request):
    serializer = RegisterSerializer(data=request.data)
    if serializer.is_valid():
        user = serializer.save()
        return Response(UserSerializer(user).data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def profil(request):
    return Response(UserSerializer(request.user).data)


# ── NOUVEAU : GET/PATCH /api/users/profile/ ────────────────────
@api_view(['GET', 'PATCH'])
@permission_classes([IsAuthenticated])
def profile_view(request):
    user = request.user

    if request.method == 'GET':
        serializer = UserProfileSerializer(user)
        return Response(serializer.data)

    elif request.method == 'PATCH':
        # Vérifier que le nouveau username n'est pas déjà pris
        new_username = request.data.get('username')
        if new_username and new_username != user.username:
            if User.objects.filter(username=new_username).exists():
                return Response(
                    {'detail': 'Ce nom d\'utilisateur est déjà pris'},
                    status=status.HTTP_400_BAD_REQUEST
                )

        # Vérifier que le nouvel email n'est pas déjà utilisé
        new_email = request.data.get('email')
        if new_email and new_email != user.email:
            if User.objects.filter(email=new_email).exists():
                return Response(
                    {'detail': 'Cet email est déjà utilisé'},
                    status=status.HTTP_400_BAD_REQUEST
                )

        serializer = UserProfileSerializer(user, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# ── NOUVEAU : POST /api/users/change-password/ ─────────────────
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def change_password_view(request):
    serializer = ChangePasswordSerializer(data=request.data)

    if not serializer.is_valid():
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    user = request.user
    old_password = serializer.validated_data['old_password']
    new_password = serializer.validated_data['new_password']

    # Vérifier l'ancien mot de passe
    if not user.check_password(old_password):
        return Response(
            {'detail': 'Mot de passe actuel incorrect'},
            status=status.HTTP_400_BAD_REQUEST
        )

    # Empêcher de réutiliser le même mot de passe
    if user.check_password(new_password):
        return Response(
            {'detail': 'Le nouveau mot de passe doit être différent de l\'ancien'},
            status=status.HTTP_400_BAD_REQUEST
        )

    user.set_password(new_password)
    user.save()
    return Response({'detail': 'Mot de passe changé avec succès'})


# ── Favoris (code existant inchangé) ───────────────────────────
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def liste_favoris(request):
    favoris = Favori.objects.filter(user=request.user)
    return Response(FavoriSerializer(favoris, many=True).data)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def ajouter_favori(request):
    lieu_id = request.data.get('lieu_id')
    favori, created = Favori.objects.get_or_create(
        user=request.user, lieu_id=lieu_id
    )
    if created:
        return Response({'message': 'Ajouté aux favoris'}, status=201)
    return Response({'message': 'Déjà dans les favoris'}, status=200)


@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def supprimer_favori(request, lieu_id):
    Favori.objects.filter(user=request.user, lieu_id=lieu_id).delete()
    return Response({'message': 'Retiré des favoris'})


@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])
def listes(request):
    if request.method == 'GET':
        listes = ListePerso.objects.filter(user=request.user)
        return Response(ListePersoSerializer(listes, many=True).data)
    serializer = ListePersoSerializer(data=request.data)
    if serializer.is_valid():
        serializer.save(user=request.user)
        return Response(serializer.data, status=201)
    return Response(serializer.errors, status=400)


@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def supprimer_liste(request, liste_id):
    ListePerso.objects.filter(id=liste_id, user=request.user).delete()
    return Response({'message': 'Liste supprimée'})