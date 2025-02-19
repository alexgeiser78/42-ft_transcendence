# Utiliser l'image alpine
FROM alpine:latest  

# Installer sqlite
RUN apk add --no-cache sqlite  

# Définir le répertoire de travail
WORKDIR /data  

# Copier le fichier init.sql dans le conteneur
COPY init.sql /data/init.sql  

# Vérifier que /data existe et que init.sql est bien copié
RUN echo "Vérification de /data" && ls -l /data

# Exécuter le script pour créer la base de données
CMD ["sh", "-c", "sqlite3 /data/database.db < /data/init.sql && tail -f /dev/null"]
