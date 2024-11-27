# 1. Base image olarak resmi Node.js imajını kullan
FROM node:18

# 2. Çalışma dizinini ayarla
WORKDIR /usr/src/app

# 3. package.json ve package-lock.json dosyalarını kopyala
COPY package*.json ./

# 4. Bağımlılıkları yükle
RUN npm install

# 5. Uygulama dosyalarını kopyala (npm install'dan sonra kopyalanmalı)
COPY . .

# 6. Test bağımlılıklarını yükle
RUN npm install --save-dev jest

# 7. Uygulamanın çalışacağı portu belirle
EXPOSE 5050

# 8. Testleri çalıştır
RUN npm test

# 9. Uygulamayı başlat
CMD ["npm", "start"]
