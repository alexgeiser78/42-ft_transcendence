# Nom de l'image
IMAGE_NAME = sqlite-container
TAR_FILE = $(IMAGE_NAME).tar
VOLUME_NAME = sqlite-data
CONTAINER_NAME = sqlite-instance

# Construction de l'image avec buildctl
build:
		sudo buildctl build --frontend=dockerfile.v0 --local context=. --local dockerfile=. --output type=image,name=$(IMAGE_NAME),oci-mediatype=application/vnd.oci.image.v1.tar

# Exporter l'image dans un fichier tar
export-image: build
		mv $(IMAGE_NAME).tar $(TAR_FILE)

# Importer l'image dans containerd
import-image: export-image
		sudo ctr images import $(TAR_FILE)

# Lancer le conteneur avec un volume persistant
run:
		sudo ctr run --rm -t \
			--mount type=volume,source=$(VOLUME_NAME),destination=/data \
			$(IMAGE_NAME) $(CONTAINER_NAME) /bin/sh

# Arrêter et supprimer le conteneur
stop-container:
		sudo ctr task kill $(CONTAINER_NAME)
		sudo ctr containers rm $(CONTAINER_NAME)

# Supprimer le volume persistant
remove-volume:
		sudo ctr volume rm $(VOLUME_NAME)

# Supprimer l'image
remove-image:
		sudo ctr images rm $(IMAGE_NAME)

# Nettoyer les fichiers intermédiaires
clean:
		rm -f $(TAR_FILE)

# Créer un volume pour la persistance des données
create-volume:
		sudo ctr volume create $(VOLUME_NAME)

# Pour arrêter et nettoyer tout, utiliser la cible "clean-all"
clean-all: stop-container remove-volume remove-image clean

# Règles par défaut
all: create-volume run
