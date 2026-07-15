
const express = require('express');
const path = require('path');
const app = express();
const PORT = process.env.PORT || 3000;

// Middleware untuk membaca JSON & menyajikan file statis (frontend)
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// Penyimpanan sementara di memori server (akan ter-reset jika server restart)
let db_accounts = {};

// 1. Endpoint API untuk menerima data dari Script Delta di Roblox
app.post('/api/update', (req, res) => {
    const authHeader = req.headers['authorization'];
    const SECRET_KEY = "MASUKKAN_BEBAS_PASSWORD_API_DISINI"; // Harus sama dengan di script Roblox Anda

    // Validasi Keamanan
    if (authHeader !== SECRET_KEY) {
        return res.status(401).json({ error: 'Kunci otorisasi salah!' });
    }

    const { username, userId, sheckles, inventory } = req.body;

    if (!username) {
        return res.status(400).json({ error: 'Data tidak lengkap (username kosong).' });
    }

    // Simpan atau perbarui data akun di database memori
    db_accounts[username] = {
        userId: userId || "N/A",
        sheckles: sheckles || 0,
        inventory: inventory || {},
        lastUpdated: new Date().toLocaleTimeString('id-ID')
    };

    console.log(`[API] Berhasil memperbarui data untuk akun: ${username}`);
    res.status(200).json({ success: true, message: 'Data berhasil diperbarui di server!' });
});

// 2. Endpoint API untuk Frontend mengambil data terbaru
app.get('/api/accounts', (req, res) => {
    res.json(db_accounts);
});

// Jalankan Server
app.listen(PORT, () => {
    console.log(`Server aktif di port: http://localhost:${PORT}`);
});
