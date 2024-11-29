#!/bin/bash

echo "Grafana kurulumu başlatılıyor..."

# Gerekli bağımlılıkları yükle
sudo apt-get update
sudo apt-get install -y software-properties-common

# Grafana GPG anahtarını ekle
sudo wget -q -O /usr/share/keyrings/grafana.key https://packages.grafana.com/gpg.key

# Grafana reposunu ekle
echo "deb [signed-by=/usr/share/keyrings/grafana.key] https://packages.grafana.com/oss/deb stable main" | sudo tee /etc/apt/sources.list.d/grafana.list

# Paket listelerini güncelle
sudo apt-get update

# Grafana'yı yükle
sudo apt-get install -y grafana

# Grafana'yı başlat ve enable yap
sudo systemctl start grafana-server
sudo systemctl enable grafana-server

# Kurulumun tamamlandığını doğrula
grafana-cli --version
sudo systemctl status grafana-server | head -n 10

echo "Grafana başarıyla yüklendi ve başlatıldı."
