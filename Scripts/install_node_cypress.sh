#!/bin/bash

# NVM ortamını kontrol et ve yükle
echo "Node.js ve npm kurulumu başlatılıyor..."
if [ ! -d "$HOME/.nvm" ]; then
  echo "NVM kurulumu yapılıyor..."
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
fi

# NVM ortamını yükle
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Node.js'i yükle
echo "En son Node.js sürümü yükleniyor..."
nvm install node

# Node.js ve npm sürümlerini kontrol et
echo "Node.js sürümü: $(node -v)"
echo "npm sürümü: $(npm -v)"

# Sistem bağımlılıklarını yükle
echo "Cypress için gerekli sistem kütüphaneleri yükleniyor..."
sudo apt update
sudo apt upgrade -y
sudo apt install -y libxss1 libgtk2.0-0 libgtk-3-0 libnotify-dev libgconf-2-4 libnss3 libasound2 xvfb

# Cypress kurulumu
echo "Cypress kurulumu başlatılıyor..."
CYPRESS_PROJECT_DIR=~/cypress_project
mkdir -p "$CYPRESS_PROJECT_DIR"
cd "$CYPRESS_PROJECT_DIR"

# npm projesi başlat ve Cypress'i yükle
npm init -y
npm install cypress --save-dev

echo "Node.js ve Cypress kurulumu tamamlandı."
