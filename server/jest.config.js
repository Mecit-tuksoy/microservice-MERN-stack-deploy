export default {
  testEnvironment: "node",
  transform: {
    "^.+\\.[tj]sx?$": "babel-jest", // Babel ile dosyaları dönüştür
  },
};
