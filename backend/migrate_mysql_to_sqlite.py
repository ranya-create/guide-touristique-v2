#!/usr/bin/env python
import os
import django
import pymysql

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'django_config.settings')
django.setup()

from tourism_app.models import LieuTouristique, CategorieLieu

# Paramètres MySQL
MYSQL_HOST = '127.0.0.1'
MYSQL_USER = 'root'
MYSQL_PASSWORD = ''
MYSQL_DATABASE = 'dbtourist'
MYSQL_PORT = 3306

try:
    # Connexion à MySQL
    print("🔗 Connexion à MySQL...")
    conn = pymysql.connect(
        host=MYSQL_HOST,
        user=MYSQL_USER,
        password=MYSQL_PASSWORD,
        database=MYSQL_DATABASE,
        port=MYSQL_PORT,
        charset='utf8mb4'
    )
    cursor = conn.cursor(pymysql.cursors.DictCursor)
    
    cursor.execute("SELECT * FROM tourism_app_categorielieu")
    categories_mysql = cursor.fetchall()
    
    print(f"✅ {len(categories_mysql)} catégories trouvées dans MySQL")
    
    # Importer les catégories d'abord
    print("\n📤 Import des catégories dans SQLite...")
    for cat in categories_mysql:
        try:
            obj, created = CategorieLieu.objects.update_or_create(
                id=cat['id'],
                defaults={'nom': cat['nom']}
            )
            if created:
                print(f"✅ Catégorie créée: {cat['nom']}")
        except Exception as e:
            print(f"❌ Erreur pour catégorie {cat['nom']}: {e}")
    
    # Récupérer tous les lieux de MySQL
    print("\n📥 Extraction des lieux de MySQL...")
    cursor.execute("SELECT * FROM tourism_app_lieutouristique")
    lieux_mysql = cursor.fetchall()
    
    print(f"✅ {len(lieux_mysql)} lieux trouvés dans MySQL")
    
    # Importer dans Django/SQLite
    print("\n📤 Import dans SQLite...")
    for lieu in lieux_mysql:
        try:
            # Récupérer ou créer la catégorie
            categorie = None
            if lieu.get('categorie_id'):
                try:
                    categorie = CategorieLieu.objects.get(id=lieu['categorie_id'])
                except CategorieLieu.DoesNotExist:
                    print(f"⚠️  Catégorie {lieu['categorie_id']} non trouvée, sera null")
            
            # Créer ou mettre à jour le lieu
            obj, created = LieuTouristique.objects.update_or_create(
                id=lieu['id'],
                defaults={
                    'nom': lieu['nom'],
                    'description': lieu['description'] or '',
                    'adresse': lieu['adresse'] or '',
                    'latitude': lieu['latitude'],
                    'longitude': lieu['longitude'],
                    'categorie': categorie,
                    'date_creation': lieu['date_creation']
                }
            )
            if created:
                print(f"✅ Créé: {lieu['nom']}")
            else:
                print(f"🔄 Mis à jour: {lieu['nom']}")
        except Exception as e:
            print(f"❌ Erreur pour {lieu['nom']}: {e}")
    
    conn.close()
    print(f"\n✨ Migration terminée ! {len(lieux_mysql)} lieux importés")
    
except Exception as e:
    print(f"❌ Erreur de connexion MySQL: {e}")
    print("\n💡 Assurez-vous que:")
    print("   - MySQL est en cours d'exécution")
    print("   - La base de données 'dbtourist' existe")
    print("   - Les identifiants sont corrects")
