#!/bin/bash
exec >> /var/log/game-portal-user-data.log 2>&1
echo "=== user-data start: $(date) ==="

DB_HOST="${db_host}"
DB_PORT="${db_port}"
DB_NAME="${db_name}"
DB_USER="${db_user}"
DB_PASSWORD="${db_password}"

echo "=== Installing Node.js ==="
dnf install -y nodejs
echo "=== node: $(node --version), npm: $(npm --version) ==="

mkdir -p /app

cat > /app/config.json << EOF
{
  "host": "$DB_HOST",
  "port": $DB_PORT,
  "database": "$DB_NAME",
  "user": "$DB_USER",
  "password": "$DB_PASSWORD",
  "ssl": false
}
EOF

cat > /app/package.json << 'PKGJSON'
{
  "name": "game-portal-api",
  "version": "1.0.0",
  "main": "server.js",
  "dependencies": {
    "express": "^4.18.2",
    "pg": "^8.11.3",
    "cors": "^2.8.5"
  }
}
PKGJSON

cat > /app/server.js << 'JSEOF'
const express = require('express');
const { Pool } = require('pg');
const cors = require('cors');
const config = require('./config.json');

const app = express();
app.use(express.json());
app.use(cors());

const pool = new Pool(config);

async function initDB() {
  const client = await pool.connect();
  try {
    await client.query('CREATE TABLE IF NOT EXISTS rankings (id SERIAL PRIMARY KEY, player_name VARCHAR(100) NOT NULL, score INTEGER NOT NULL, created_at TIMESTAMP DEFAULT NOW())');
    await client.query('CREATE TABLE IF NOT EXISTS posts (id SERIAL PRIMARY KEY, title VARCHAR(200) NOT NULL, content TEXT, author VARCHAR(100) NOT NULL DEFAULT \'Anonymous\', created_at TIMESTAMP DEFAULT NOW())');
    await client.query('CREATE TABLE IF NOT EXISTS downloads (id INTEGER PRIMARY KEY DEFAULT 1, count INTEGER DEFAULT 0)');
    await client.query('INSERT INTO downloads (id, count) VALUES (1, 0) ON CONFLICT DO NOTHING');
    console.log('DB initialized');
  } finally {
    client.release();
  }
}

app.get('/health', function(req, res) {
  res.json({ status: 'ok' });
});

app.get('/api/ranking', async function(req, res) {
  try {
    const result = await pool.query('SELECT player_name, score, created_at FROM rankings ORDER BY score DESC LIMIT 10');
    res.json(result.rows);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.post('/api/scores', async function(req, res) {
  try {
    const result = await pool.query('INSERT INTO rankings (player_name, score) VALUES ($1, $2) RETURNING *', [req.body.player_name, req.body.score]);
    res.json(result.rows[0]);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.get('/api/posts', async function(req, res) {
  try {
    const result = await pool.query('SELECT id, title, author, created_at FROM posts ORDER BY created_at DESC');
    res.json(result.rows);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.post('/api/posts', async function(req, res) {
  try {
    const result = await pool.query('INSERT INTO posts (title, content, author) VALUES ($1, $2, $3) RETURNING *', [req.body.title, req.body.content || '', req.body.author || 'Anonymous']);
    res.json(result.rows[0]);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.get('/api/posts/:id', async function(req, res) {
  try {
    const result = await pool.query('SELECT * FROM posts WHERE id = $1', [req.params.id]);
    if (!result.rows.length) return res.status(404).json({ error: 'Not found' });
    res.json(result.rows[0]);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.get('/api/downloads/count', async function(req, res) {
  try {
    const result = await pool.query('SELECT count FROM downloads WHERE id = 1');
    res.json({ count: result.rows[0] ? result.rows[0].count : 0 });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.post('/api/downloads/track', async function(req, res) {
  try {
    const result = await pool.query('UPDATE downloads SET count = count + 1 WHERE id = 1 RETURNING count');
    res.json({ count: result.rows[0].count });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

initDB().then(function() {
  app.listen(3000, function() {
    console.log('Game Portal API running on port 3000');
  });
}).catch(function(err) {
  console.error('DB init failed: ' + err.message);
  process.exit(1);
});
JSEOF

echo "=== npm install ==="
cd /app && npm install --production

echo "=== creating systemd service ==="
cat > /etc/systemd/system/game-portal.service << 'SYSTEMD'
[Unit]
Description=Game Portal API
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/app
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=15
Environment=NODE_ENV=production
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
SYSTEMD

systemctl daemon-reload
systemctl enable game-portal
systemctl start game-portal
echo "=== user-data done: $(date) ==="
