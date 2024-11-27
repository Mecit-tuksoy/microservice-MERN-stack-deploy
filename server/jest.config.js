export default {
  transform: {
    '^.+\\.(js|jsx|mjs)$': 'babel-jest', // Babel kullanarak ESM'yi dönüştür
  },
  transformIgnorePatterns: [
    '/node_modules/',
  ],
};
