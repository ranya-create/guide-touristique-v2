from rest_framework import serializers
from django.contrib.auth.models import User
from .models import LieuTouristique, CategorieLieu, Favori, ListePerso, ItineraireEnregistre

# Serializer pour les catégories
class CategorieLieuSerializer(serializers.ModelSerializer):
    class Meta:
        model = CategorieLieu
        fields = '__all__'

# Serializer pour les lieux (ton code existant)
class LieuTouristiqueSerializer(serializers.ModelSerializer):
    categorie_nom = serializers.ReadOnlyField(source='categorie.nom')
    class Meta:
        model = LieuTouristique
        fields = '__all__'

# Serializer pour l'INSCRIPTION (Username, Email, Password, First/Last Name)
class RegisterSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ('username', 'password', 'email', 'first_name', 'last_name')
        extra_kwargs = {
            'password': {'write_only': True},
            'email': {'required': True},
            'first_name': {'required': True},
            'last_name': {'required': True}
        }

    def create(self, validated_data):
        # create_user gère automatiquement le hachage du mot de passe
        user = User.objects.create_user(**validated_data)
        return user

# Serializer pour les FAVORIS
class FavoriSerializer(serializers.ModelSerializer):
    class Meta:
        model = Favori
        fields = '__all__'
        read_only_fields = ['user'] # L'utilisateur est défini par le token

# Serializer pour les ITINÉRAIRES
class ItineraireEnregistreSerializer(serializers.ModelSerializer):
    class Meta:
        model = ItineraireEnregistre
        fields = '__all__'
        read_only_fields = ['user', 'date_enregistrement']