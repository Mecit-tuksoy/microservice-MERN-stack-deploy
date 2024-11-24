const express = require('express');
const mongoose = require('mongoose');
const bodyParser = require('body-parser');
const cors = require('cors');

const app = express();

// CORS yapılandırması
const corsOptions = {
  origin: process.env.FRONTEND_URL || 'http://frontend-service:3000',
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type'],
  credentials: true,
  optionsSuccessStatus: 200,
};

// CORS middleware kullanımı
app.use(cors(corsOptions));

app.use(bodyParser.json());

// MongoDB bağlantısı
const mongoURI = process.env.MONGO_URI;

if (!mongoURI) {
  console.error('HATA: MONGO_URI çevresel değişkeni tanımlı değil. Lütfen Secret veya ConfigMap ile sağlayın.');
  process.exit(1); // Çıkış yap
}

mongoose
  .connect(mongoURI, {
    useNewUrlParser: true,
    useUnifiedTopology: true,
  })
  .then(() => console.log('MongoDB bağlantısı başarılı'))
  .catch((err) => {
    console.error('MongoDB bağlantı hatası:', err);
    process.exit(1); // Hata durumunda uygulamayı durdur
  });

// Ana sayfa rotası
app.get('/', (req, res) => {
  res.send('Backend çalışıyor!');
});

// Schema ve Model
const contactSchema = new mongoose.Schema({
  name: String,
  phone: String,
});

const Contact = mongoose.model('Contact', contactSchema);

// Tüm kişileri getir
app.get('/contacts', async (req, res) => {
  const contacts = await Contact.find();
  res.json(contacts);
});

// Yeni bir kişi ekle
app.post('/contacts', async (req, res) => {
  const newContact = new Contact(req.body);
  await newContact.save();
  res.status(201).json(newContact);
});

// Sunucuyu başlat
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`Backend çalışıyor: http://localhost:${PORT}`);
});
