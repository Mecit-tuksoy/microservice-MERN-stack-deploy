export default {
    transform: {
      "^.+\\.[tj]sx?$": "babel-jest", // Babel kullanarak JS/TS dosyalarını dönüştürmek
    },
    testEnvironment: "node", // Node.js ortamında test çalıştırmak
  };
  