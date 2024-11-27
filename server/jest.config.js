export default {
  setupFiles: ["<rootDir>/loadEnvironment.mjs"],  // loadEnvironment.mjs dosyasını setupFiles'a dahil edin
  extensionsToTreatAsEsm: [],  // .mjs uzantısını extensionsToTreatAsEsm'ye eklemeyin
  testEnvironment: "node",  // Node ortamında testleri çalıştır
};
