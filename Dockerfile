# iso image
FROM alpine:latest  

# install sqlite
RUN apk add --no-cache sqlite  

# file directory
WORKDIR /data  

# Script copy image to container
COPY init.sql /data/init.sql  

# Execute the script to create the database
CMD ["sh", "-c", "sqlite3 /data/database.db < /data/init.sql && tail -f /dev/null"]

