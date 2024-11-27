module.exports = {
  transform: {
    // Babel kullanarak .js ve .mjs dosyalarını dönüştür
    "^.+\\.[t|j]sx?$": "babel-jest"
  },
  testEnvironment: "node", // Node.js ortamında test yapacağız
  transformIgnorePatterns: [
    "/node_modules/(?!supertest)/" // supertest gibi bağımlılıkların dönüştürülmesini sağlıyoruz
  ]
};
