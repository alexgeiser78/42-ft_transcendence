# Variables
IMAGE_NAME = sqlite-container
TAR_FILE = $(IMAGE_NAME).tar
VOLUME_NAME = /home/alex/42/trans/sqlite-data
CONTAINER_NAME = sqlite-instance
USER = alex  # Remplace par ton vrai utilisateur si besoin

# Build an OCI-compliant image
build:
	@echo "Building the image..."
	sudo buildctl build --frontend=dockerfile.v0 --local context=. --local dockerfile=. --output type=oci,dest=$(TAR_FILE) --no-cache
	sudo chown 777 $(TAR_FILE)

# Export the image as a tar file
export-image: build
	@echo "Image exportée sous le nom $(TAR_FILE)"

# Import the image into containerd with base-name for correct naming
import-image: export-image
	@echo "Importing image into containerd..."
	sudo ctr images import --base-name $(IMAGE_NAME):latest $(TAR_FILE)
	@echo "Liste des images importées :"
	ctr images ls

# Create volume directory
create-volume-dir:
	@echo "Creating volume directory $(VOLUME_NAME) if it doesn't exist..."
	@mkdir -p $(VOLUME_NAME)
	sudo chown 777 $(VOLUME_NAME)

# Run the container
run: create-volume-dir
	@echo "Lancement du conteneur avec l'image $(IMAGE_NAME):latest..."
	sudo ctr run --rm -t \
		--mount type=bind,src=$(VOLUME_NAME),dst=/data \
		$(IMAGE_NAME):latest $(CONTAINER_NAME) /bin/sh

# Stop container
stop-container:
	@echo "Arrêt du conteneur $(CONTAINER_NAME)..."
	ctr task kill $(CONTAINER_NAME) || echo "Container $(CONTAINER_NAME) not found or already stopped"
	ctr containers rm $(CONTAINER_NAME) || echo "Container $(CONTAINER_NAME) not found"

# Remove image
remove-image:
	@echo "Suppression de l'image $(IMAGE_NAME):latest..."
	ctr images rm $(IMAGE_NAME):latest || echo "Image $(IMAGE_NAME) not found"

# Clean temporary files
clean:
	@echo "Nettoyage des fichiers temporaires..."
	rm -f $(TAR_FILE)

# Full cleanup
fclean: stop-container remove-image clean
	rm -rf $(VOLUME_NAME)

# Default rule
all: run

# Rebuild everything
re: fclean build import-image run

# Check images
imagecheck:
	@echo "Liste des images dans containerd :"
	ctr images ls

# Help
help:
	@echo "Commandes disponibles :"
	@echo "  build         - Construire l'image avec buildctl"
	@echo "  export-image  - Exporter l'image au format tar"
	@echo "  import-image  - Importer l'image dans containerd"
	@echo "  run           - Lancer le conteneur"
	@echo "  stop-container - Arrêter et supprimer le conteneur"
	@echo "  remove-image  - Supprimer l'image"
	@echo "  clean         - Nettoyer les fichiers temporaires"
	@echo "  fclean        - Tout supprimer (container, image, fichiers)"
	@echo "  imagecheck    - Vérifier les images dans containerd"
	@echo "  help          - Afficher cette aide"
