#!/bin/bash

# Menghentikan script jika ada error
set -e

# Variabel
UBUNTU_VERSION="20.04"
IMAGE_URL="http://cdimage.ubuntu.com/ubuntu-base/releases/$UBUNTU_VERSION/release/ubuntu-base-$UBUNTU_VERSION-base-amd64.tar.gz"
TARGET_DIR="/mnt/ubuntu"
DEVICE="/dev/sdX"  # Ganti dengan disk yang sesuai
HOSTNAME="my-ubuntu"
TIMEZONE="Asia/Jakarta"
LOCALE="en_US.UTF-8"
USERNAME="sabdo"  # Ganti dengan nama user
PASSWORD="Palon1Xol"  # Ganti dengan password yang diinginkan

# Fungsi untuk menampilkan pesan informasi
info() {
    echo -e "\e[32m$*\e[0m"
}

# Fungsi untuk menampilkan pesan error dan keluar
error() {
    echo -e "\e[31m$*\e[0m" >&2
    exit 1
}

# Cek apakah script dijalankan sebagai root
if [ "$EUID" -ne 0 ]; then
    error "Jalankan script ini sebagai root!"
fi

# Update dan install dependencies
info "Memperbarui paket dan menginstall debootstrap..."
apt update && apt install -y debootstrap gdisk

# Partisi disk
info "Memformat disk $DEVICE..."
sgdisk --zap-all $DEVICE
sgdisk -n 1:0:+1G -t 1:8300 $DEVICE  # Partisi root
mkfs.ext4 ${DEVICE}1
mount ${DEVICE}1 $TARGET_DIR

# Download dan ekstrak Ubuntu base image
info "Mengunduh dan mengekstrak Ubuntu base image versi $UBUNTU_VERSION..."
debootstrap --arch=amd64 focal $TARGET_DIR $IMAGE_URL

# Bind mount beberapa sistem file untuk chroot
mount --bind /dev $TARGET_DIR/dev
mount --bind /dev/pts $TARGET_DIR/dev/pts
mount --bind /proc $TARGET_DIR/proc
mount --bind /sys $TARGET_DIR/sys

# Mengonfigurasi chroot environment
info "Mengonfigurasi sistem dasar..."
chroot $TARGET_DIR /bin/bash <<EOF
# Set hostname
echo "$HOSTNAME" > /etc/hostname

# Set timezone
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
dpkg-reconfigure -f noninteractive tzdata

# Set locale
apt update
apt install -y locales
locale-gen $LOCALE
update-locale LANG=$LOCALE

# Set up /etc/fstab
echo "UUID=$(blkid -s UUID -o value ${DEVICE}1) / ext4 errors=remount-ro 0 1" > /etc/fstab

# Install kernel dan init system
apt install -y linux-image-generic grub-pc

# Install bootloader
grub-install $DEVICE
update-grub

# Membuat user baru
useradd -m -s /bin/bash -G sudo $USERNAME
echo "$USERNAME:$PASSWORD" | chpasswd

# Membersihkan paket yang tidak diperlukan
apt clean
EOF

# Unmount sistem file
info "Melepas mount point..."
umount -l $TARGET_DIR/dev/pts
umount -l $TARGET_DIR/dev
umount -l $TARGET_DIR/proc
umount -l $TARGET_DIR/sys
umount -l $TARGET_DIR

info "Instalasi Ubuntu $UBUNTU_VERSION selesai. Anda dapat reboot sekarang."