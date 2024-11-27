module.exports = {
  preset: 'ts-jest', // Eğer TypeScript kullanıyorsanız
  transform: {
    '^.+\\.m?js$': 'babel-jest', // .js ve .mjs dosyalarını Babel ile dönüştür
  },
  testEnvironment: 'node',
  transformIgnorePatterns: [
    '/node_modules/',
  ],
  moduleFileExtensions: ['js', 'json', 'mjs'], // .js, .json ve .mjs dosyalarına izin verir
};
