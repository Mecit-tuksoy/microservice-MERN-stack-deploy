FROM node:18

WORKDIR /usr/src/app

COPY package*.json ./

RUN npm install

# Xvfb'yi yükleyin
RUN apt-get update && apt-get install -y xvfb

COPY . .

EXPOSE 3000

CMD ["npm", "start"]
