# Docker Image Name
IMAGE_NAME = fastify-sqlite

# Port used for the app
PORT = 3000

# catch the name of the OS user
USER = $(shell whoami)

# Directory for the SQLite database
DB_DIR = /home/$(USER)/sgoinfre/supertrans

# Path to the SQLite database
DB_PATH = $(DB_DIR)/database.sqlite

# build the docker image
build:
	docker build -t $(IMAGE_NAME) .

# start the container
run:
	# Create the database file if it doesn't exist
	[ -f $(DB_PATH) ] || touch $(DB_PATH)

	# Set proper permissions on the SQLite file
	chmod 666 $(DB_PATH)

	# Run the container
	docker network create --driver bridge custom_network
	docker run --rm -it --network custom_network -p $(PORT):$(PORT) -v $(DB_PATH):/app/database.sqlite $(IMAGE_NAME)



# Start the docker-compose
compose-up:
	docker-compose up --build -d

# Stop the docker-compose
compose-down:
	docker-compose down

# clean the container and the used images
clean:
	docker system prune -f

# fclean command to remove the database.sqlite file
fclean: stop clean
	@read -p "Are you sure you want to delete the database.sqlite file and its contents? (y/n): " confirm; \
	if [ "$$confirm" = "y" ]; then \
		rm -f $(DB_PATH); \
		echo "Database file deleted."; \
	else \
		echo "Operation canceled."; \
	fi

# Print the logs of the container
logs:
	docker-compose logs -f

# stop the container
stop:
	@container_id=$(shell docker ps -q -f "ancestor=$(IMAGE_NAME)") && \
	if [ -n "$$container_id" ]; then \
		docker stop $$container_id; \
	else \
		echo "No running container found for $(IMAGE_NAME)"; \
	fi

# Remove the docker image
remove:
	docker rm $(shell docker ps -aq -f "ancestor=$(IMAGE_NAME)")

# Create the database directory if necessary
re: stop fclean build run

list:
	docker ps -a

# disponible commands
help:
	@echo "Available commands:"
	@echo "  make build         → Build the Docker Image"
	@echo "  make run           → Execute the Docker container"
	@echo "  make compose-up    → Start with Docker-compose"
	@echo "  make compose-down  → Stop with Docker-compose"
	@echo "  make clean         → Clean the used containers"
	@echo "  make logs          → Print the logs"
	@echo "  make remove        → Delete the Docker Image"
	@echo "  make re            → Full reload"
	@echo "  make list          → List of the Images"
	