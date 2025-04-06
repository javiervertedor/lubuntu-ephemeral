#!/bin/bash
set -e
sudo mkdir -p /mnt/ramdisk
sudo chown root:root /mnt/ramdisk
sudo chmod 755 /mnt/ramdisk

RAMDISK_SIZE="24G"
TMPFS_MOUNT="/mnt/ramdisk_tmpfs"
CRYPT_NAME="cryptoram"
CRYPT_MOUNT="/mnt/ramdisk"
MAPPED_DEV="/dev/mapper/$CRYPT_NAME"

# Carpetas a mover
declare -A DIRS_TO_MOVE=(
  ["/home"]="$CRYPT_MOUNT/home"
  ["/tmp"]="$CRYPT_MOUNT/tmp"
  ["/var/tmp"]="$CRYPT_MOUNT/var/tmp"
  ["/var/log"]="$CRYPT_MOUNT/var/log"
)

# Crear tmpfs
sudo mkdir -p "$TMPFS_MOUNT"
sudo mount -t tmpfs -o size=$RAMDISK_SIZE tmpfs "$TMPFS_MOUNT"

# Crear contenedor cifrado en RAM
sudo dd if=/dev/zero of=$TMPFS_MOUNT/cryptfile.img bs=1M count=$((24 * 1024)) status=none

# Generar clave efímera en RAM
KEY=$(head -c 4096 /dev/urandom | base64)

# Configurar LUKS
echo "$KEY" | base64 -d | sudo cryptsetup luksFormat --batch-mode "$TMPFS_MOUNT/cryptfile.img" -
echo "$KEY" | base64 -d | sudo cryptsetup luksOpen "$TMPFS_MOUNT/cryptfile.img" "$CRYPT_NAME" -
unset KEY

# Formatear volumen y montar
sudo mkfs.ext4 "$MAPPED_DEV"
sudo mkdir -p "$CRYPT_MOUNT"
sudo mount "$MAPPED_DEV" "$CRYPT_MOUNT"

# Mover carpetas
for SRC in "${!DIRS_TO_MOVE[@]}"; do
  DST="${DIRS_TO_MOVE[$SRC]}"
  if [ -d "$SRC" ]; then
    echo "Moviendo $SRC a $DST..."
    sudo mkdir -p "$DST"
    sudo rsync -a "$SRC/" "$DST/"
    sudo mount --bind "$DST" "$SRC"
  fi
done

echo "[+] Entorno RAM cifrado activo. Todos los datos son efímeros."
