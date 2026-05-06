# Guide de Configuration - Projet Tourist Guide

## 📁 Structure du Projet

Ton projet est maintenant organisé de manière claire et professionnelle :

```
tourist_guide/
├── backend/                 ← Django Backend
│   ├── manage.py           (Script principal Django)
│   ├── requirements.txt     (Dépendances Python)
│   ├── django_config/      (Configuration Django)
│   │   ├── settings.py
│   │   ├── urls.py
│   │   ├── asgi.py
│   │   └── wsgi.py
│   ├── tourism_app/        (Application Django principale)
│   │   ├── models.py
│   │   ├── views.py
│   │   ├── serializers.py
│   │   ├── urls.py
│   │   ├── admin.py
│   │   ├── management/
│   │   └── migrations/
│   ├── media/              (Fichiers médias)
│   ├── env/                (Environnement virtuel Python)
│   └── env2/               (Environnement virtuel Python)
│
├── frontend/               ← Flutter App
│   ├── lib/               (Code source Flutter)
│   ├── pubspec.yaml       (Dépendances Flutter)
│   ├── android/           (Configuration Android)
│   ├── ios/               (Configuration iOS)
│   ├── web/               (Configuration Web)
│   ├── windows/           (Configuration Windows)
│   ├── linux/             (Configuration Linux)
│   ├── macos/             (Configuration macOS)
│   └── test/              (Tests Flutter)
│
└── README.md              (Documentation du projet)
```

## 🚀 Comment Lancer le Projet

### 1️⃣ Lancer le Backend Django

```bash
# Aller dans le dossier backend
cd backend

# Activer l'environnement virtuel
env\Scripts\activate

# Lancer le serveur Django
python manage.py runserver

# Le serveur sera accessible à: http://localhost:8000
```

### 2️⃣ Lancer le Frontend Flutter (dans un autre terminal)

```bash
# Aller dans le dossier frontend
cd frontend

# Obtenir les dépendances
flutter pub get

# Lancer l'application sur l'émulateur Android
flutter run

# Ou sur iOS (macOS seulement)
flutter run -d ios

# Ou sur le web
flutter run -d chrome
```

## 📝 Notes Importantes

### Configuration des URL Backend
- **Émulateur Android**: L'app Flutter utilise `http://10.0.2.2:8000` (c'est l'adresse spéciale pour l'émulateur)
- **Téléphone physique**: Remplace par ton adresse IP locale (ex: `http://192.168.x.x:8000`)

### Structure Django
- Le fichier principal de configuration est : `backend/django_config/settings.py`
- L'app principale est : `backend/tourism_app/`
- Les migrations doivent être faites avec : `python manage.py migrate` (depuis le dossier `backend`)

### Structure Flutter  
- Le point d'entrée est : `frontend/lib/main.dart`
- Les écrans sont dans : `frontend/lib/screens/`
- Les services API sont dans : `frontend/lib/services/`

## 🔧 Commandes Utiles

### Backend Django

```bash
cd backend

# Créer une migration après modification des modèles
python manage.py makemigrations

# Appliquer les migrations
python manage.py migrate

# Lancer le serveur en mode développement
python manage.py runserver

# Accéder à l'admin Django
# http://localhost:8000/admin
```

### Frontend Flutter

```bash
cd frontend

# Vérifier les dépendances
flutter pub outdated

# Mettre à jour les dépendances
flutter pub upgrade

# Nettoyer le build
flutter clean

# Reconstruire
flutter pub get
```

## ✅ Vérifier que tout fonctionne

1. **Backend**: Visite `http://localhost:8000` dans ton navigateur
2. **Frontend**: Lance l'app Flutter et vérifie qu'elle se connecte au backend

## 📚 Pour Plus d'Infos

- **Django**: https://docs.djangoproject.com/
- **Flutter**: https://flutter.dev/docs
- **Django REST Framework**: https://www.django-rest-framework.org/

---

**Besoin d'aide?** Asure-toi que :
- ✅ Django est lancé (`python manage.py runserver`)
- ✅ L'émulateur/téléphone a accès à la bonne URL backend
- ✅ Les dépendances sont installées (`pip install -r requirements.txt` et `flutter pub get`)
