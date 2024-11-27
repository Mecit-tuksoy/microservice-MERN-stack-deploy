// jest.config.js
export default {
  testEnvironment: "node",
  transform: {
    "^.+\\.mjs$": "babel-jest", // ES6 modüllerini Babel ile dönüştür
  },
  extensionsToTreatAsEsm: [".js"], // Jest'in JS dosyalarını ESM olarak işlemesini sağla
};
