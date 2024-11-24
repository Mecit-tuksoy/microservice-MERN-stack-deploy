import React, { useState, useEffect } from 'react';
import axios from 'axios';

const API_BASE_URL = 'http://54.175.35.178:30001';

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
    if (!name.trim() || !phone.trim()) {
      setError("Ad ve telefon bilgisi boş bırakılamaz.");
      return;
    }
    axios.post(`${API_BASE_URL}/contacts`, { name, phone })
      .then((response) => {
        setContacts([...contacts, response.data]);
        setName('');
        setPhone('');
        setError('');
      })
      .catch((error) => {
        const errorMessage = error.response?.data?.message || "Bir hata oluştu.";
        setError(errorMessage);
      });
  };

  return (
    <div>
      <h1>Telefon Defteri</h1>
      {error && (
        <div style={{ backgroundColor: '#ffcccc', padding: '10px', borderRadius: '5px', marginBottom: '10px' }}>
          {error}
        </div>
      )}
      <form onSubmit={addContact}>
        <input 
          type="text" 
          placeholder="Ad" 
          value={name} 
          onChange={(e) => setName(e.target.value)} 
        />
        <input 
          type="text" 
          placeholder="Telefon" 
          value={phone} 
          onChange={(e) => setPhone(e.target.value)} 
        />
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
