# Utiliser Alpine comme base
FROM alpine:latest  

# Installer SQLite
RUN apk add --no-cache sqlite  

# Définir le répertoire de travail
WORKDIR /data  

# Copier le script SQL dans l’image
COPY init.sql /data/init.sql  

# Exécuter SQLite avec le script au démarrage
CMD ["sh", "-c", "sqlite3 /data/database.db < /data/init.sql && tail -f /dev/null"]

