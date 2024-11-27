export default {
  transform: {
    "^.+\\.[t|j]sx?$": "babel-jest"
  },
  testEnvironment: "node", 
  transformIgnorePatterns: [
    "/node_modules/(?!supertest|express)/"  // Jest'in `supertest` ve `express` gibi bazı modülleri de dönüştürmesine izin ver
  ]
};
