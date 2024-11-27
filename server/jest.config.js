export default {
  setupFiles: ["<rootDir>/loadEnvironment.mjs"],
  testEnvironment: "node",
  transform: {
    "^.+\\.mjs$": "babel-jest", // Babel ile .mjs dosyalarını dönüştür
  },
};
