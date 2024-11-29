#!/bin/bash

echo "Prometheus kurulumu başlatılıyor..."

# Gerekli kullanıcı ve grubu oluştur
sudo useradd --no-create-home --shell /bin/false prometheus

# Gerekli dizinleri oluştur
sudo mkdir /etc/prometheus
sudo mkdir /var/lib/prometheus

# Prometheus binary dosyalarını indir
wget https://github.com/prometheus/prometheus/releases/download/v3.0.0/prometheus-3.0.0.linux-amd64.tar.gz

# Arşivi çıkart ve gerekli dosyaları taşı
tar -xvzf prometheus-3.0.0.linux-amd64.tar.gz
cd prometheus-3.0.0.linux-amd64
sudo mv prometheus promtool /usr/local/bin/
sudo mv consoles console_libraries /etc/prometheus/
sudo mv prometheus.yml /etc/prometheus/
sudo rm -rf prometheus-3.0.0.linux-amd64.tar.gz
sudo rm -rf prometheus-3.0.0.linux-amd64

# İzinleri ayarla
sudo chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus /usr/local/bin/prometheus /usr/local/bin/promtool

# Prometheus hizmet dosyasını oluştur
cat <<EOL | sudo tee /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus Monitoring System
Documentation=https://prometheus.io/docs/introduction/overview/
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \\
  --config.file=/etc/prometheus/prometheus.yml \\
  --storage.tsdb.path=/var/lib/prometheus \\
  --web.console.templates=/etc/prometheus/consoles \\
  --web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target
EOL

# Hizmet dosyasını yükle ve başlat
sudo systemctl daemon-reload
sudo systemctl enable prometheus
sudo systemctl start prometheus

# Kurulum doğrulama
sudo systemctl status prometheus | head -n 10
prometheus --version

echo "Prometheus başarıyla yüklendi ve çalıştırıldı."
