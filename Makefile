# Nom de l'utilisateur à ajouter au groupe containerd
USER_NAME = alex
GROUP_NAME = containerd

# Créer le groupe containerd s'il n'existe pas déjà
create-group:
	@if ! getent group $(GROUP_NAME) > /dev/null; then \
		echo "Création du groupe $(GROUP_NAME)..."; \
		sudo groupadd $(GROUP_NAME); \
	else \
		echo "Le groupe $(GROUP_NAME) existe déjà."; \
	fi

# Ajouter l'utilisateur au groupe containerd
add-user-to-group:
	@if id -nG $(USER_NAME) | grep -qw $(GROUP_NAME); then \
		echo "$(USER_NAME) est déjà dans le groupe $(GROUP_NAME)."; \
	else \
		echo "Ajout de $(USER_NAME) au groupe $(GROUP_NAME)..."; \
		sudo usermod -aG $(GROUP_NAME) $(USER_NAME); \
	fi

# Appliquer les modifications du groupe (reconnexion de l'utilisateur)
apply-group-changes:
	@echo "Déconnexion et reconnexion pour appliquer les changements du groupe $(GROUP_NAME)."
	@echo "Une fois connecté à nouveau, vous pourrez exécuter containerd sans sudo."

# Afficher le statut des groupes de l'utilisateur
check-user-groups:
	@echo "Vérification des groupes de $(USER_NAME)..."
	id -nG $(USER_NAME)

# Règles par défaut
setup: create-group add-user-to-group apply-group-changes
	@echo "Setup complet! Déconnectez-vous et reconnectez-vous pour que les changements prennent effet."

# Vérification : Afficher les groupes de l'utilisateur
check-groups:
	@echo "Vérification des groupes de $(USER_NAME) :"
	id -nG $(USER_NAME)

#------------

IMAGE_NAME = sqlite-container # Nom de l'image construite
TAR_FILE = $(IMAGE_NAME).tar # Nom du fichier image exporté (sqlite-container.tar)
VOLUME_NAME = sqlite-data # Nom du volume persistant (sqlite-data)
CONTAINER_NAME = sqlite-instance # Nom du conteneur en cours d'exécution (sqlite-instance)

# Build an OCI-compliant image using buildctl
build:
	umask 0022
	buildctl build --frontend=dockerfile.v0 --local context=. --local dockerfile=. --output type=tar,dest=$(TAR_FILE)

# Export the image as a tar file
# Rename the built image to a tar file
export-image: build
	chown alex:alex $(TAR_FILE)
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
	ctr task kill $(CONTAINER_NAME) || echo "Conteneur $(CONTAINER_NAME) non trouvé ou déjà arrêté"
	ctr containers rm $(CONTAINER_NAME) || echo "Conteneur $(CONTAINER_NAME) non trouvé"

# Remove the persistent volume
remove-volume:
	ctr volume rm $(VOLUME_NAME) || echo "Volume $(VOLUME_NAME) non trouvé"

# Remove the imported image from containerd
remove-image:
	ctr images rm $(IMAGE_NAME) || echo "Image $(IMAGE_NAME) non trouvée"

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
	@echo "Règles disponibles :"
	@echo "  build: Construire l'image avec buildctl"
	@echo "  export-image: Exporter l'image sous forme de fichier tar"
	@echo "  import-image: Importer l'image dans containerd"
	@echo "  run: Lancer le conteneur avec un volume persistant"
	@echo "  stop-container: Arrêter et supprimer le conteneur"
	@echo "  remove-volume: Supprimer le volume persistant"
	@echo "  remove-image: Supprimer l'image importée"
	@echo "  clean: Nettoyer les fichiers temporaires"
	@echo "  create-volume: Créer un volume pour le stockage persistant des données"
	@echo "  clean-all: Tout arrêter et supprimer (conteneur, volume, image, et fichiers temporaires)"
	@echo "  all: Créer le volume et démarrer le conteneur"
	@echo "  re: Tout supprimer, reconstruire, et redémarrer le conteneur"
	@echo "  help: Afficher la liste des règles disponibles"
	@echo "  imagecheck: Vérifier la liste des images disponibles"

.PHONY: create-group add-user-to-group apply-group-changes check-user-groups setup check-groups build export-image import-image run stop-container remove-volume remove-image clean create-volume fclean all re imagecheck help