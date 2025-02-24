#Using an official Node.js image
FROM node:18

# Definition of the working directory
WORKDIR /app

# Copy the files package.json and package-lock.json
COPY ./fastify-app/package*.json ./fastify-app/

# Install the dependencies
RUN npm install --prefix ./fastify-app

# Copy the source code
COPY ./fastify-app/ ./fastify-app/

# Exposing the port used by Fastify
EXPOSE 3000

# Start the app
CMD ["node", "./fastify-app/index.js"]
