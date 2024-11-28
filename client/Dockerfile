# Node.js 18 sürümünü temel al
FROM node:18

# Çalışma dizinini ayarla
WORKDIR /usr/src/app

# package.json ve package-lock.json dosyalarını kopyala
COPY package*.json ./

# Bağımlılıkları yükle
RUN npm install

# Cypress'in çalışması için gerekli olan bağımlılıkları yükle
RUN apt-get update && apt-get install -y \
    libgtk2.0-0 \
    libgtk-3-0 \
    libgbm-dev \
    libnotify-dev \
    libgconf-2-4 \
    libnss3 \
    libxss1 \
    libasound2 \
    libxtst6 \
    libXcomposite1 \
    xvfb \
    --no-install-recommends && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Projenin geri kalanını kopyala
COPY . .

# Uygulama için gerekli portu aç
EXPOSE 3000

# Uygulama başlatma komutu
CMD ["npm", "start"]
