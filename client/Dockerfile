# Node.js 18 sürümünü temel al
FROM node:18

# Çalışma dizinini ayarla
WORKDIR /usr/src/app

# package.json ve package-lock.json dosyalarını kopyala
COPY package*.json ./

# Bağımlılıkları yükle
RUN npm install

# Cypress'in çalışması için gerekli olan bağımlılıkları yükle
RUN apt-get update && apt-get install -y libgtk2.0-0 --no-install-recommends 
RUN apt-get install -y libgtk-3-0 --no-install-recommends 
RUN apt-get install -y libgbm-dev --no-install-recommends 
RUN apt-get install -y libnotify-dev --no-install-recommends 
RUN apt-get install -y libgconf-2-4 --no-install-recommends 
RUN apt-get install -y libnss3 --no-install-recommends 
RUN apt-get install -y libxss1 --no-install-recommends 
RUN apt-get install -y libasound2 --no-install-recommends 
RUN apt-get install -y libxtst6 --no-install-recommends 
# RUN apt-get install -y libXcomposite --no-install-recommends 
RUN apt-get install -y xvfb --no-install-recommends 

# Projenin geri kalanını kopyala
COPY . .

# Uygulama için gerekli portu aç
EXPOSE 3000

# Uygulama başlatma komutu
CMD ["npm", "start"]
