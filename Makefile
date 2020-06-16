TEMP_DIR_NAME = $(shell head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20 ; echo '')
BUILD_DIR := ./build/$(TEMP_DIR_NAME)

create: pre-create mount-and-unpack-fs create-docker-image post-create

pre-create: create-build-dir download-vyos

create-build-dir:
	@echo "Create build directory"
	mkdir $(BUILD_DIR)
	mkdir $(BUILD_DIR)/unsquashfs
	mkdir $(BUILD_DIR)/rootfs

download-vyos:
	@echo "Download last VyOS image"
	curl --output $(BUILD_DIR)/vyos-latest.iso `python3 vyos-latest.py`

mount-and-unpack-fs:
	mount -o loop $(BUILD_DIR)/vyos-latest.iso $(BUILD_DIR)/rootfs
	unsquashfs -f -d $(BUILD_DIR)/unsquashfs/ $(BUILD_DIR)/rootfs/live/filesystem.squashfs

create-docker-image:
	tar -C $(BUILD_DIR)/unsquashfs -c . | docker import - vyos

post-create: unmount-fs clean-build-dir

unmount-fs:
	umount $(BUILD_DIR)/rootfs

clean-build-dir:
	@echo "Clean build directory"
	rm -rf $(BUILD_DIR)/

# Dependency
dependency: dependency-python dependency-system

dependency-python: 
	@echo "Install dependency for python"
	python3 -m pip install lxml

dependency-system:
	@echo "Install system dependency"
	apt-get install -y squashfs-tools python-bs4