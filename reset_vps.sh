#!/bin/bash

# Pastikan script dijalankan sebagai root
if [ "$(id -u)" -ne 0 ]; then
   echo "Script ini harus dijalankan sebagai root." 1>&2
   exit 1
fi

# Verifikasi sebelum memulai
echo "PERINGATAN: Script ini akan menghapus semua data di VPS dan mengembalikan ke kondisi seperti baru."
read -p "Apakah Anda yakin ingin melanjutkan? [y/N]: " confirm

# Cek apakah pengguna mengonfirmasi dengan 'y' atau 'Y'
if [[ $confirm != "y" && $confirm != "Y" ]]; then
   echo "Proses dibatalkan. Tidak ada perubahan yang dilakukan."
   exit 0
fi

echo "Mulai proses reset VPS..."

# Update dan upgrade sistem
echo "Update dan upgrade sistem..."
apt-get update -y && apt-get upgrade -y

# Hapus aplikasi yang umum diinstall
echo "Menghapus aplikasi yang terinstall..."
apt-get purge -y apache2 nginx mysql-server php postfix

# Hapus pengguna yang tidak diperlukan (ubah 'nama_pengguna' sesuai dengan pengguna yang ada)
echo "Menghapus pengguna yang tidak diperlukan..."
deluser --remove-home nama_pengguna

# Membersihkan semua direktori home pengguna kecuali root
echo "Menghapus direktori home pengguna lain..."
find /home/* -delete

# Hapus direktori www (direktori web)
echo "Menghapus file di /var/www/..."
rm -rf /var/www/*

# Hapus log sistem
echo "Membersihkan log sistem..."
find /var/log -type f -delete

# Hapus database MySQL (jika ada)
echo "Menghapus semua database MySQL..."
rm -rf /var/lib/mysql/*

# Hapus konfigurasi jaringan (opsional, jika ingin reset jaringan)
echo "Menghapus konfigurasi jaringan..."
rm -rf /etc/network/interfaces
rm -rf /etc/netplan/*

# Menghapus direktori konfigurasi aplikasi
echo "Menghapus konfigurasi aplikasi di /etc/..."
find /etc/ -name "*" -type f -delete

# Menghapus cache sistem
echo "Menghapus cache sistem..."
rm -rf /var/cache/*

# Membersihkan paket-paket yang tidak diperlukan
echo "Membersihkan paket-paket yang tidak diperlukan..."
apt-get autoremove -y && apt-get clean

# Setel ulang password root (opsional)
echo "Setel ulang password root (opsional)..."
echo "root:new_password" | chpasswd

# Reboot sistem
echo "Reboot VPS dalam 10 detik..."
sleep 10
reboot
