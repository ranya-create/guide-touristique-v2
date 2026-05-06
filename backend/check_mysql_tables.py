#!/usr/bin/env python
import pymysql

# Paramètres MySQL
MYSQL_HOST = '127.0.0.1'
MYSQL_USER = 'root'
MYSQL_PASSWORD = ''
MYSQL_DATABASE = 'dbtourist'
MYSQL_PORT = 3306

try:
    print("🔗 Connexion à MySQL...")
    conn = pymysql.connect(
        host=MYSQL_HOST,
        user=MYSQL_USER,
        password=MYSQL_PASSWORD,
        database=MYSQL_DATABASE,
        port=MYSQL_PORT,
        charset='utf8mb4'
    )
    cursor = conn.cursor()
    
    # Lister toutes les tables
    print("\n📊 Tables disponibles dans 'dbtourist':")
    cursor.execute("SHOW TABLES")
    tables = cursor.fetchall()
    
    if tables:
        for table in tables:
            table_name = table[0]
            cursor.execute(f"SELECT COUNT(*) FROM {table_name}")
            count = cursor.fetchone()[0]
            print(f"  - {table_name} ({count} lignes)")
    else:
        print("  ❌ Aucune table trouvée")
    
    conn.close()
    
except Exception as e:
    print(f"❌ Erreur: {e}")
    print("\n💡 Vérifiez que MySQL est en cours d'exécution")
