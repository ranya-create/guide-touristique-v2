from django.db import models
from django.contrib.auth.models import User # Import important !

# --- TES MODÈLES ACTUELS (Gardés tels quels) ---

class CategorieLieu(models.Model):
    nom = models.CharField(max_length=100)
    def __str__(self): return self.nom
    class Meta:
        verbose_name = 'Catégorie'
        verbose_name_plural = 'Catégories'

class LieuTouristique(models.Model):
    nom = models.CharField(max_length=200)
    description = models.TextField()
    adresse = models.CharField(max_length=300, blank=True)
    latitude = models.FloatField()
    longitude = models.FloatField()
    image = models.ImageField(upload_to='lieux/', blank=True, null=True)
    categorie = models.ForeignKey(CategorieLieu, on_delete=models.SET_NULL, null=True, blank=True, related_name='lieux')
    date_creation = models.DateTimeField(auto_now_add=True)

    def __str__(self): return self.nom
    class Meta:
        verbose_name = 'Lieu Touristique'
        verbose_name_plural = 'Lieux Touristiques'

# --- LES NOUVEAUX MODÈLES POUR L'UTILISATEUR (CRUD) ---

class ListePerso(models.Model):
    """Pour que l'utilisateur crée ses propres dossiers de lieux"""
    nom = models.CharField(max_length=100)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='listes')
    description = models.TextField(blank=True)
    date_creation = models.DateTimeField(auto_now_add=True)

    def __str__(self): return f"{self.nom} ({self.user.username})"

class Favori(models.Model):
    """Lien entre un utilisateur et un lieu (Cœur rouge)"""
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='favoris')
    lieu = models.ForeignKey(LieuTouristique, on_delete=models.CASCADE)
    liste = models.ForeignKey(ListePerso, on_delete=models.SET_NULL, null=True, blank=True, related_name='elements')
    date_ajout = models.DateTimeField(auto_now_add=True)

    class Meta:
        # Empêche d'ajouter deux fois le même lieu aux favoris globaux
        unique_together = ('user', 'lieu') 

class ItineraireEnregistre(models.Model):
    """Pour sauvegarder un trajet calculé"""
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='itineraires')
    nom = models.CharField(max_length=200, default="Mon itinéraire")
    depart_nom = models.CharField(max_length=255)
    arrivee_nom = models.CharField(max_length=255)
    # On stocke les coordonnées du chemin en texte (JSON) pour le redessiner sur Flutter
    points_gps = models.TextField() 
    date_enregistrement = models.DateTimeField(auto_now_add=True)

    def __str__(self): return f"Itinéraire de {self.user.username}"