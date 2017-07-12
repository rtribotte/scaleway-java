NAME =			selenium-hub
VERSION =		latest
VERSION_ALIASES =
TITLE =			Selenium Hub
DESCRIPTION =		Selemium hub machine
SOURCE_URL =
VENDOR_URL =
DEFAULT_IMAGE_ARCH =	arm64

IMAGE_VOLUME_SIZE =	50G
IMAGE_BOOTSCRIPT =	latest
IMAGE_NAME =		selenium-hub


## Image tools  (https://github.com/scaleway/image-tools)
all:	docker-rules.mk
docker-rules.mk:
	wget -qO - https://j.mp/scw-builder | bash
-include docker-rules.mk
