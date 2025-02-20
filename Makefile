# Variables
IMAGE_NAME = sqlite-container
TAR_FILE = $(IMAGE_NAME).tar
VOLUME_NAME = /home/ageiser/sgoinfre/supertrans/sqlite-data
CONTAINER_NAME = sqlite-instance

# Construire l'image avec BuildKit
build:
	@echo "Building the image..."
	buildctl --addr unix:///home/ageiser/.buildkit/test.sock build --frontend=dockerfile.v0 --local context=. --local dockerfile=. --output type=oci,dest=$(TAR_FILE) --no-cache

# Exporter l'image (l'image est déjà construite dans TAR_FILE)
export-image: build
	@echo "Image exported to $(TAR_FILE)"

# Importer l'image dans containerd en mode rootless avec un tag explicite
import-image: export-image
	@echo "Importing image into containerd..."
	ctr --address /home/ageiser/.containerd/containerd.sock images import $(TAR_FILE)
	@echo "Image imported into containerd"
	@echo "Tagging image as latest..."
	ctr --address /home/ageiser/.containerd/containerd.sock images tag $(IMAGE_NAME):latest $(IMAGE_NAME):latest

# Créer le volume (un répertoire local en tant que volume)
create-volume-dir:
	@echo "Creating volume directory $(VOLUME_NAME) if it doesn't exist..."
	mkdir -p $(VOLUME_NAME)

# Lancer le conteneur avec containerd (ou compatible avec OCI)
run: create-volume-dir import-image
	@echo "Running the container with containerd..."
	ctr --address /home/ageiser/.containerd/containerd.sock run --rm --net-host --mount type=bind,source=$(VOLUME_NAME),target=/data $(IMAGE_NAME):latest $(CONTAINER_NAME) /bin/sh -c "echo 'Container started' && tail -f /dev/null"
	@echo "Container running with containerd."

# Arrêter et supprimer le conteneur
# Arrêter et supprimer le conteneur
stop-container:
	@echo "Stopping container $(CONTAINER_NAME)..."
	ctr --address /home/ageiser/.containerd/containerd.sock task kill $(CONTAINER_NAME)
	ctr --address /home/ageiser/.containerd/containerd.sock container rm $(CONTAINER_NAME)
	@echo "Container stopped and removed."

# Supprimer l'image construite
remove-image:
	@echo "Removing image $(IMAGE_NAME):latest..."
	ctr --address /home/ageiser/.containerd/containerd.sock images rm $(IMAGE_NAME):latest
	@echo "Image removed."

# Nettoyage des fichiers temporaires
clean:
	@echo "Cleaning temporary files..."
	rm -f $(TAR_FILE)

# Tout nettoyer (conteneur, image, fichiers temporaires)
fclean: stop-container remove-image clean
	rm -rf $(VOLUME_NAME)

# Vérifier les images disponibles dans containerd (ou autre moteur)
imagecheck:
	@echo "Listing images in containerd..."
	ctr --address /home/ageiser/.containerd/containerd.sock images ls
	@echo "Image list displayed."


# Aide
help:
	@echo "Available commands:"
	@echo "  build         - Build the image with BuildKit"
	@echo "  export-image  - Export the built image"
	@echo "  import-image  - Import the image into containerd"
	@echo "  run           - Run the container with BuildKit"
	@echo "  stop-container - Stop and remove the container"
	@echo "  remove-image  - Remove the built image"
	@echo "  clean         - Clean temporary files"
	@echo "  fclean        - Clean everything (container, image, files)"
	@echo "  imagecheck    - List images in containerd"
	@echo "  help          - Display this help"
	@echo "  re            - Rebuild everything"

# Reconstruire tout (nettoyer, construire l'image, importer, et lancer)
re: fclean build import-image run
