# Variables
IMAGE_NAME = sqlite-container
TAR_FILE = $(IMAGE_NAME).tar
VOLUME_NAME = /home/ageiser/sgoinfre/supertrans/sqlite-data
CONTAINER_NAME = sqlite-instance

# Building the image with buildkit and rootless
build:
	@echo "Building the image..."
	buildctl --addr unix:///home/ageiser/.buildkit/test.sock build --frontend=dockerfile.v0 --local context=. --local dockerfile=. --output type=oci,dest=$(TAR_FILE) --no-cache

# Import the image in containerd in rootless mode with an explicite tag
import-image:
	@echo "Importing image into containerd..."
	ctr --address /home/ageiser/.containerd/containerd.sock images import --base-name $(IMAGE_NAME) --digests --all-platforms $(TAR_FILE)
	@echo "Tagging image as $(IMAGE_NAME):latest..."
	ctr --address /home/ageiser/.containerd/containerd.sock images tag $$(ctr --address /home/ageiser/.containerd/containerd.sock images ls -q | grep "$(IMAGE_NAME)@sha256") $(IMAGE_NAME):latest
	@echo "Images list after import :"
	ctr --address /home/ageiser/.containerd/containerd.sock images ls

# Exporting the image inot a .tar file
export-image:
	@echo "Exporting the image..."
	ctr --address /home/ageiser/.containerd/containerd.sock images export sqlite-container.tar $(IMAGE_NAME):latest
	@echo "Image exported to sqlite-container.tar"

# Créer le volume (un répertoire local en tant que volume)
create-volume-dir:
	@echo "Creating volume directory $(VOLUME_NAME) if it doesn't exist..."
	mkdir -p $(VOLUME_NAME)
	chown ageiser:2022_barcelona /home/ageiser/sgoinfre/supertrans/sqlite-data

# Lancer le conteneur avec containerd (ou compatible avec OCI)
run: create-volume-dir
	@echo "Running the container with containerd..."
	ctr --address /home/ageiser/.containerd/containerd.sock run --rm --net-host --mount type=bind,source=$(VOLUME_NAME),destination=/data sqlite-container:latest sqlite-instance /bin/sh -c "echo 'Container started' && tail -f /dev/null"
	@echo "Container running with containerd."

# Arrêter et supprimer le conteneur
# Arrêter et supprimer le conteneur
stop-container:
	@echo "Stopping container $(CONTAINER_NAME)..."
	-ctr --address /home/ageiser/.containerd/containerd.sock task kill $(CONTAINER_NAME)
	-ctr --address /home/ageiser/.containerd/containerd.sock tasks rm $(CONTAINER_NAME)
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
	@echo "  build         - Build the image with BuildKit in Rootless mode"
	@echo "  import-image  - Import the image into containerd"
	@echo "  export-image  - Export the built image"
	@echo "  run           - Run the container with BuildKit"
	@echo "  stop-container - Stop and remove the container"
	@echo "  remove-image  - Remove the built image"
	@echo "  clean         - Clean temporary files"
	@echo "  fclean        - Clean everything (container, image, files)"
	@echo "  imagecheck    - List images in containerd"
	@echo "  help          - Display this help"
	@echo "  re            - Rebuild everything"

# Reconstruire tout (nettoyer, construire l'image, importer, et lancer)
re:  build import-image export-image run re imagecheck clean fclean
