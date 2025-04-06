#!/bin/bash
set -euo pipefail

RAMDISK_SIZE="24G"
TMPFS_MOUNT="/mnt/ramdisk_tmpfs"
CRYPT_FILE="$TMPFS_MOUNT/ramdisk.luks"
CRYPT_NAME="cryptoram"
MOUNT_POINT="/mnt/ramdisk"
MAPPED_DEV="/dev/mapper/$CRYPT_NAME"

echo "[*] Montando tmpfs en $TMPFS_MOUNT con tamaño $RAMDISK_SIZE..."
sudo mkdir -p "$TMPFS_MOUNT"
sudo mount -t tmpfs -o size=$RAMDISK_SIZE tmpfs "$TMPFS_MOUNT"

echo "[*] Creando archivo de contenedor cifrado en RAM..."
sudo dd if=/dev/zero of="$CRYPT_FILE" bs=1M count=24576 status=none

echo "[*] Generando clave temporal de cifrado..."
KEY=$(head -c 4096 /dev/urandom)

echo "[*] Formateando volumen LUKS..."
echo -n "$KEY" | sudo cryptsetup luksFormat --batch-mode "$CRYPT_FILE" -
echo -n "$KEY" | sudo cryptsetup luksOpen "$CRYPT_FILE" "$CRYPT_NAME" -

unset KEY
echo "[*] Clave de cifrado eliminada de la memoria local."

echo "[*] Formateando y montando el volumen cifrado..."
sudo mkfs.ext4 "$MAPPED_DEV" -q
sudo mkdir -p "$MOUNT_POINT"
sudo mount "$MAPPED_DEV" "$MOUNT_POINT"

echo "[*] Creando estructura de carpetas..."
sudo mkdir -p "$MOUNT_POINT"/{home,tmp,var/tmp,var/log,var/cache}
sudo chmod 1777 "$MOUNT_POINT/tmp" "$MOUNT_POINT/var/tmp"

echo "[*] Copiando contenido de /home al RAM disk..."
sudo cp -a /home/. "$MOUNT_POINT/home/"

echo "[*] Montando carpetas del sistema desde el RAM disk..."
sudo mount --bind "$MOUNT_POINT/home" /home
sudo mount --bind "$MOUNT_POINT/tmp" /tmp
sudo mount --bind "$MOUNT_POINT/var/tmp" /var/tmp
sudo mount --bind "$MOUNT_POINT/var/log" /var/log
sudo mount --bind "$MOUNT_POINT/var/cache" /var/cache

echo "[*] Remontando carpetas originales como solo lectura..."
for DIR in /home /tmp /var/tmp /var/log /var/cache; do
    ORIG_MOUNT=$(findmnt -n -o SOURCE --target "$DIR")
    if [ -n "$ORIG_MOUNT" ]; then
        sudo mount -o remount,ro "$ORIG_MOUNT" || echo "[!] No se pudo montar $ORIG_MOUNT como solo lectura"
    fi
done

echo "[✓] RAM disk de 24GB cifrado y operativo. Actividad sensible redirigida a RAM."
