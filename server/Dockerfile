FROM node:18

# Uygulama dizinine geçiş yap
WORKDIR /usr/src/app

# package.json dosyasını kopyala ve bağımlılıkları yükle
COPY package*.json ./
RUN npm install

# Uygulama dosyalarını kopyala
COPY . .

# Testler için gerekli modülleri yükle
RUN npm install --save-dev jest supertest babel-jest @babel/core @babel/preset-env

# Uygulamanın çalışacağı portu belirle
EXPOSE 5050

# Varsayılan komut
CMD ["npm", "start"]