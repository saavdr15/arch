#!/bin/bash

# Script básico para instalar Arch Linux en un disco de 200 GB
# ¡Cuidado! Revisa las configuraciones antes de ejecutarlo.

# Variables
DISK="/dev/sda"           # Cambia esto al disco correcto
HOSTNAME="mi-archlinux"   # Nombre del equipo
LOCALE="es_ES.UTF-8"      # Configuración de idioma
TIMEZONE="Europe/Madrid"  # Cambia a tu zona horaria

# Paso 1: Comprobar conexión a Internet
echo "Comprobando conexión a Internet..."
ping -c 3 google.com || { echo "Error: No hay conexión a Internet."; exit 1; }

# Paso 2: Actualizar el reloj
timedatectl set-ntp true

# Paso 3: Particionar el disco
echo "Particionando el disco..."
parted $DISK --script mklabel gpt
parted $DISK --script mkpart ESP fat32 1MiB 513MiB
parted $DISK --script set 1 esp on
parted $DISK --script mkpart primary linux-swap 513MiB 8705MiB
parted $DISK --script mkpart primary ext4 8705MiB 100%

# Paso 4: Formatear particiones
echo "Formateando particiones..."
mkfs.fat -F32 "${DISK}1"             # Partición EFI
mkswap "${DISK}2"                    # Partición Swap
mkfs.ext4 "${DISK}3"                 # Partición raíz

# Paso 5: Activar swap y montar particiones
echo "Montando particiones..."
swapon "${DISK}2"
mount "${DISK}3" /mnt
mkdir /mnt/boot
mount "${DISK}1" /mnt/boot

# Paso 6: Instalar el sistema base
echo "Instalando el sistema base..."
pacstrap /mnt base linux linux-firmware

# Paso 7: Generar fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Paso 8: Configuración del sistema
echo "Configurando el sistema..."
arch-chroot /mnt /bin/bash <<EOF
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc
echo "$LOCALE UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=$LOCALE" > /etc/locale.conf
echo "$HOSTNAME" > /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1 localhost" >> /etc/hosts
echo "127.0.1.1 $HOSTNAME.localdomain $HOSTNAME" >> /etc/hosts
passwd <<EOPASS
root123
root123
EOPASS
pacman -S grub efibootmgr --noconfirm
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
EOF

# Paso 9: Finalizar
echo "Desmontando y reiniciando..."
umount -R /mnt
reboot
