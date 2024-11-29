#!/bin/bash

echo "Jenkins kurulumu başlatılıyor..."

# Java'nın yüklü olduğunu kontrol edin, değilse openjdk-17-jdk yükleyin
if ! java -version &>/dev/null; then
  echo "OpenJDK 17 yükleniyor..."
  sudo apt-get update
  sudo apt-get install openjdk-17-jdk -y
else
  echo "Java zaten yüklü."
fi

# Jenkins için GPG anahtarını ekle
echo "Jenkins GPG anahtarı ekleniyor..."
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null

# Jenkins repository'sini ekle
echo "Jenkins repository'si ekleniyor..."
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

# Paket listelerini güncelle ve Jenkins'i yükle
sudo apt-get update
sudo apt-get install jenkins -y

# Jenkins hizmetini başlat
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Kurulum durumunu kontrol et
sudo systemctl status jenkins | head -n 10

echo "Jenkins başarıyla kuruldu. Varsayılan olarak http://<sunucu-ip>:8080 adresinden erişebilirsiniz."
