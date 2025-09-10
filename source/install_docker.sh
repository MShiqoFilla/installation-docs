#!/bin/bash

#Pertama, kita perbarui daftar paket dan instal beberapa paket pendukung agar kita bisa menambahkan repositori baru melalui HTTPS.
sudo apt-get update
sudo apt-get install ca-certificates curl


# Selanjutnya, kita tambahkan kunci GPG resmi Docker. 
# Ini adalah langkah keamanan untuk memastikan perangkat lunak yang kita unduh adalah asli.
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc


# Terakhir, kita daftarkan repositori Docker ke dalam daftar sumber apt kita.
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null


# Kita perbarui lagi daftar paket kita, kali ini apt akan mengenali paket-paket baru dari repositori Docker.
sudo apt-get update


# Sekarang, kita instal paket-paket Docker.
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
# Ini akan menginstal semua yang kita butuhkan: mesin Docker itu sendiri (docker-ce), 
# antarmuka baris perintah (cli), dan beberapa plugin berguna lainnya.


# Uji Coba Pertama: Hello World!
sudo docker run hello-world


# Source:
# https://www.jagoweb.com/kb/knowledge-base-jagoweb/tutorial-install-docker-di-ubuntu/


# Memulai kembali docker
sudo systemctl start docker

# Set docker agar auto start saat boot atau saat WSL dibuka
sudo systemctl enable docker

# Cek status docker
systemcl status docker

# Stop docker
sudo systemctl stop docker
sudo systemctl stop docker.socket
sudo systemctl stop docker.service

# Set docker agar tidak auto restart saat boot atau saat WSL dibuka
sudo systemctl disable docker