import React, { useState, useEffect } from 'react';
import axios from 'axios';
import API_BASE_URL from './config.js';

function App() {
  const [contacts, setContacts] = useState([]);
  const [name, setName] = useState('');
  const [phone, setPhone] = useState('');
  const [error, setError] = useState('');

  useEffect(() => {
    axios.get(`${API_BASE_URL}/contacts`) 
      .then((response) => {
        setContacts(response.data);
      })
      .catch((error) => {
        console.error("API Hatası:", error);
        setError("Veri yüklenirken bir hata oluştu. Lütfen tekrar deneyin.");
      });
  }, []);

  const addContact = (e) => {
    e.preventDefault();
    axios.post(`${API_BASE_URL}/contacts`, { name, phone }) // Güncel URL kullanılıyor
      .then((response) => {
        setContacts([...contacts, response.data]);
        setName('');
        setPhone('');
      })
      .catch((error) => {
        console.error("Veri ekleme hatası:", error);
        setError("Yeni kişi eklerken bir hata oluştu. Lütfen tekrar deneyin.");
      });
  };

  return (
    <div>
      <h1>Telefon Defteri</h1>
      {error && <div style={{ color: 'red' }}>{error}</div>}
      <form onSubmit={addContact}>
        <input type="text" placeholder="Ad" value={name} onChange={(e) => setName(e.target.value)} />
        <input type="text" placeholder="Telefon" value={phone} onChange={(e) => setPhone(e.target.value)} />
        <button type="submit">Ekle</button>
      </form>
      <ul>
        {contacts.map((contact) => (
          <li key={contact._id}>{contact.name} - {contact.phone}</li>
        ))}
      </ul>
    </div>
  );
}

export default App;
