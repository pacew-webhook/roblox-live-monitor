const express = require('express');
const cors = require('cors');
const app = express();
const PORT = 3000;

app.use(express.json());
app.use(cors());

// 1. Definisikan Secret Key Anda di sini
const SECRET_KEY = "KunciRahasiaFarm2026_!@#"; 

let accountsData = {};

app.post('/api/update-stats', (req, res) => {
    // 2. Tangkap key dari header HTTP
    const clientKey = req.headers['x-api-key']; 
    
    // 3. Cek apakah key cocok
    if (clientKey !== SECRET_KEY) {
        console.log("Ditolak: Ada yang mencoba mengirim data dengan key salah!");
        return res.status(403).send({ error: "Akses Ditolak: Secret Key Tidak Valid" });
    }

    // Jika key benar, lanjutkan menyimpan data
    const { username, status, totalFarm, items } = req.body;
    
    accountsData[username] = {
        status: status || "Offline",
        totalFarm: totalFarm || 0,
        items: items || {},
        lastUpdated: new Date().toISOString()
    };
    
    console.log(`[UPDATE] Data dari ${username} diperbarui.`);
    res.status(200).send({ message: "Data berhasil diterima" });
});

app.get('/api/stats', (req, res) => {
    res.status(200).json(accountsData);
});

app.listen(PORT, () => {
    console.log(`Server berjalan di http://localhost:${PORT}`);
});
