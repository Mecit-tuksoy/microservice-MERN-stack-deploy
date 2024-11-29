#!/bin/bash

# Node Exporter versiyon ve indirilecek dosya bilgileri
NODE_EXPORTER_VERSION="1.8.1"
NODE_EXPORTER_TAR="node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz"
NODE_EXPORTER_URL="https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/${NODE_EXPORTER_TAR}"

# Yükleme dizini
INSTALL_DIR="/usr/local/bin"
SERVICE_FILE="/etc/systemd/system/node_exporter.service"

# Node Exporter'ı indir
echo "Node Exporter indiriliyor..."
wget -q $NODE_EXPORTER_URL -O /tmp/$NODE_EXPORTER_TAR

# Dosyayı çıkart
echo "Node Exporter çıkartılıyor..."
tar -xzf /tmp/$NODE_EXPORTER_TAR -C /tmp

# Node Exporter'ı doğru yere taşı (sudo ile)
echo "Node Exporter'ı /usr/local/bin dizinine taşıyoruz..."
sudo mv /tmp/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter $INSTALL_DIR/

# Node Exporter servis dosyasını oluştur (sudo ile)
echo "Node Exporter servisi oluşturuluyor..."
sudo bash -c "cat <<EOL > $SERVICE_FILE
[Unit]
Description=Prometheus Node Exporter
After=network.target

[Service]
ExecStart=$INSTALL_DIR/node_exporter
User=nobody
Group=nogroup
Restart=always

[Install]
WantedBy=multi-user.target
EOL"

# Systemd'yi yeniden yükleyip servisi başlat (sudo ile)
echo "Node Exporter servisi başlatılıyor..."
sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter

# Kurulumun tamamlandığını bildirme
echo "Node Exporter başarıyla kuruldu. Varsayılan olarak http://<sunucu-ip>:9100 adresinden erişebilirsiniz."

# Node Exporter versiyon bilgisini kontrol et
$INSTALL_DIR/node_exporter --version
