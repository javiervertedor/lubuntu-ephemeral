# Lubuntu Ephemeral - Manual de instalación y configuración

Este proyecto convierte una instalación de Lubuntu en un sistema totalmente efímero y orientado a la privacidad, ejecutando todo el entorno sensible en RAM. Al apagar el sistema, todos los datos se eliminan de forma segura.

## 📥 Requisitos previos

- Distribución **Lubuntu** (probado en versiones 22.04+)
- Al menos **32 GB de RAM**
- Acceso root (`sudo`)
- Conexión a internet
- Instalación mínima con espacio libre en `/mnt/ramdisk_tmpfs`

## 🔐 Paso 1: Descargar Tor Browser Portable

Descarga la versión portable de Tor Browser directamente desde el sitio oficial:

```bash
cd ~
wget https://www.torproject.org/dist/torbrowser/13.0.13/tor-browser-linux64-13.0.13_ALL.tar.xz
tar -xf tor-browser-linux64-13.0.13_ALL.tar.xz
mv tor-browser* tor-browser
cd tor-browser
./start-tor-browser.desktop
```

Esto ejecuta Tor Browser desde tu directorio `~/tor-browser`, sin instalación en el sistema.

## 💾 Paso 2: Instalar y configurar el RAM disk efímero

Descarga el script de inicialización desde este repositorio o usa `wget`:

```bash
wget https://raw.githubusercontent.com/javiervertedor/lubuntu-ephemeral/main/setup_ramdisk.sh
chmod +x setup_ramdisk.sh
sudo ./setup_ramdisk.sh
```

Este script:

- Crea un volumen cifrado de 24GB en RAM
- Copia `/home` al RAM disk
- Redirige `/home`, `/tmp`, `/var/tmp`, `/var/log`, `/var/cache` al RAM disk
- Monta sus versiones originales como solo lectura

## 💣 Paso 3: Instalar el script de apagado seguro

Este script elimina de forma segura los datos sensibles al apagar el sistema, incluyendo archivos en RAM y datos residuales en disco.

```bash
wget https://raw.githubusercontent.com/javiervertedor/lubuntu-ephemeral/main/10_secure_shutdown_srm.sh
chmod +x 10_secure_shutdown_srm.sh
sudo mv 10_secure_shutdown_srm.sh /lib/systemd/system-shutdown/10_secure_shutdown
sudo chown root:root /lib/systemd/system-shutdown/10_secure_shutdown
```

El script:

- Usa `srm` para borrar todo el contenido del RAM disk
- Usa `shred` para eliminar datos de `/var/spool` y archivos de red
- Limpia la caché DNS y la memoria RAM/swap

⚠️ Asegúrate de tener el paquete `secure-delete` instalado:

```bash
sudo apt install secure-delete
```

## ✅ Verificación

Para verificar que el sistema está usando el RAM disk:

```bash
mount | grep /mnt/ramdisk
df -h /home /tmp /var/tmp /var/log /var/cache
```

Para probar el script de apagado sin reiniciar:

```bash
sudo /lib/systemd/system-shutdown/10_secure_shutdown
```

## 🛡️ Notas de seguridad

- Todo lo ejecutado o guardado en `/home`, `/tmp`, etc., se borra al apagar
- Usa **solo aplicaciones portables** dentro de tu directorio `/home` para mantener todo contenido en RAM
- No se recomienda usar almacenamiento persistente sin cifrado adicional

## 🧩 Pendiente / Ideas futuras

- Integración con detección de tapa cerrada / batería baja
- Opciones de persistencia cifrada (manual)
- Script systemd para auto-ejecución

---
Proyecto mantenido por [@javiervertedor](https://github.com/javiervertedor)
