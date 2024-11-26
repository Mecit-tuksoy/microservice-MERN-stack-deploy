# 1. Base image olarak resmi Node.js imajını kullan
FROM node:18

# 2. Çalışma dizinini ayarla
WORKDIR /usr/src/app

# 3. package.json ve package-lock.json dosyalarını kopyala
COPY package*.json ./

# 4. Bağımlılıkları yükle
RUN npm install

# 5. Uygulama dosyalarını kopyala
COPY . .

# 6. Uygulamanın çalışacağı portu belirle
EXPOSE 3000

# 7. Uygulamayı başlat
CMD ["npm", "start"]
