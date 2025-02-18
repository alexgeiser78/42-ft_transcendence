# Nom de l'image construite
IMAGE_NAME = sqlite-container
# Nom du fichier image exporté (sqlite-container.tar)
TAR_FILE = $(IMAGE_NAME).tar
# Nom du volume persistant (sqlite-data)
VOLUME_NAME = sqlite-data
# Nom du conteneur en cours d'exécution (sqlite-instance)
CONTAINER_NAME = sqlite-instance

# Build an OCI-compliant image using buildctl
build:
	buildctl build --frontend=dockerfile.v0 --local context=. --local dockerfile=. --output type=tar,dest=$(TAR_FILE)

# Export the image as a tar file
# Rename the built image to a tar file
export-image: build
	@echo "Image exportée sous le nom $(TAR_FILE)"

# Import the image into containerd
import-image: export-image
	ctr images import $(TAR_FILE)

# Run the container with a persistent volume
# Start a container using containerd with a mounted volume
run:
	ctr run --rm -t \
            --mount type=volume,source=$(VOLUME_NAME),destination=/data \
            $(IMAGE_NAME) $(CONTAINER_NAME) /bin/sh

# Stop and remove the container
# Kill the running container task (if exists)
# Remove the container definition from containerd
stop-container:
	ctr task kill $(CONTAINER_NAME) || echo "Containerd $(CONTAINER_NAME) not found or already stopped"
	ctr containers rm $(CONTAINER_NAME) || echo "Containerd $(CONTAINER_NAME) not found"	

# Remove the persistent volume
remove-volume:
	ctr volume rm $(VOLUME_NAME) || echo "Volume $(VOLUME_NAME) not found"

# Remove the imported image from containerd
remove-image:
	ctr images rm $(IMAGE_NAME) || echo "Image $(IMAGE_NAME) not found"

# Clean up temporary files
clean:
	rm -f $(TAR_FILE)

# Create a volume for persistent data storage
create-volume:
	ctr volume create $(VOLUME_NAME)

# Stop and remove everything (container, volume, image, and temp files)
fclean: stop-container remove-volume remove-image clean

# Default rule: create the volume and start the container
all: create-volume run

# Rebuild: Remove everything, rebuild, and restart the container
re: clean-all build import-image create-volume run

# Display the list of images in containerd
imagecheck:
	ctr images ls

# Help: Display the list of available rules
help:
	@echo "Rules available:"
	@echo "  build: Building the image with buildctl"
	@echo "  export-image: Export the image with tar"
	@echo "  import-image: Import the image in containerd"
	@echo "  run: run the  containerd with a persistant volume"
	@echo "  stop-container: Stop and delete the container"
	@echo "  remove-volume: Delete the persistant volume"
	@echo "  remove-image: Delete the imported image"
	@echo "  clean: destroy the temporary files"
	@echo "  create-volume: Create a volume for the persistant data storage"
	@echo "  fclean: Stop everything and delete (container, volume, image, and temporary files)"
	@echo "  all: Create the volume and start the container"
	@echo "  re: Delete everything, rebuild, and restart the container"
	@echo "  help: Print the list of available rules"
	@echo "  imagecheck: check the list of images in containerd"

.PHONY: create-group add-user-to-group apply-group-changes check-user-groups setup check-groups build export-image import-image run stop-container remove-volume remove-image clean create-volume fclean all re imagecheck help