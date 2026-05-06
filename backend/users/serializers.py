from rest_framework import serializers
from django.contrib.auth.models import User
from django.contrib.auth.password_validation import validate_password
from tourism_app.models import Favori, ListePerso, LieuTouristique
from tourism_app.serializers import LieuTouristiqueSerializer


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ('id', 'username', 'email')


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)

    class Meta:
        model = User
        fields = ('username', 'email', 'password')

    def create(self, validated_data):
        user = User.objects.create_user(
            username=validated_data['username'],
            email=validated_data.get('email', ''),
            password=validated_data['password']
        )
        return user


# NOUVEAU : profil complet (GET/PATCH)
class UserProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ('id', 'username', 'email', 'first_name', 'last_name', 'date_joined')
        read_only_fields = ('id', 'date_joined')


# NOUVEAU : changement de mot de passe
class ChangePasswordSerializer(serializers.Serializer):
    old_password = serializers.CharField(required=True, write_only=True)
    new_password = serializers.CharField(required=True, write_only=True)

    def validate_new_password(self, value):
        validate_password(value)
        return value


class FavoriSerializer(serializers.ModelSerializer):
    lieu_detail = LieuTouristiqueSerializer(source='lieu', read_only=True)

    class Meta:
        model = Favori
        fields = ('id', 'lieu', 'lieu_detail', 'date_ajout')


class ListePersoSerializer(serializers.ModelSerializer):
    class Meta:
        model = ListePerso
        fields = ('id', 'nom', 'description', 'date_creation')