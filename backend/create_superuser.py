#!/usr/bin/env python
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'django_config.settings')
django.setup()

from django.contrib.auth.models import User

# Créer un superutilisateur par défaut
username = 'admin'
email = 'admin@example.com'
password = 'admin123'

if not User.objects.filter(username=username).exists():
    User.objects.create_superuser(username, email, password)
    print(f"✅ Superutilisateur créé !")
    print(f"   Username: {username}")
    print(f"   Password: {password}")
    print(f"   Accès: http://127.0.0.1:8000/admin/")
else:
    print(f"⚠️  L'utilisateur '{username}' existe déjà")
