# Nom de l'image
IMAGE_NAME = sqlite-container
TAR_FILE = $(IMAGE_NAME).tar
VOLUME_NAME = sqlite-data

# Construction de l'image avec buildctl
build:
		buildctl build --frontend=dockerfile.v0 --local context=. --local dockerfile=. --output type=image,name=$(IMAGE_NAME),oci-mediatype=application/vnd.oci.image.v1.tar

# Exporter l'image dans un fichier tar
export-image: build
		buildctl build --frontend=dockerfile.v0 --local context=. --local dockerfile=. --output type=image,name=$(IMAGE_NAME),oci-mediatype=application/vnd.oci.image.v1.tar
		mv $(IMAGE_NAME).tar $(TAR_FILE)

# Importer l'image dans containerd
import-image: export-image
		sudo ctr images import $(TAR_FILE)

# Lancer le conteneur avec un volume persistant
run:
		sudo ctr run --rm -t \
			--mount type=volume,source=$(VOLUME_NAME),destination=/data \
			$(IMAGE_NAME) sqlite-instance /bin/sh

# Nettoyer les fichiers intermédiaires
clean:
		rm -f $(TAR_FILE)

# Créer un volume pour la persistance des données
create-volume:
		sudo ctr volume create $(VOLUME_NAME)

# Règles par défaut
all: create-volume run
