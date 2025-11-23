const express = require('express');
const path = require('path');
const fs = require('fs');

const app = express();
const PORT = 5000;

app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));
app.use(express.static(path.join(__dirname, 'public')));

const envExample = fs.readFileSync('env.example', 'utf8');
const readme = fs.readFileSync('README.md', 'utf8');
const version = fs.readFileSync('VERSION', 'utf8').trim();

app.get('/', (req, res) => {
  res.render('index', {
    version,
    envExample,
    readme
  });
});

app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'AmneziaWG Documentation Portal' });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`✅ AmneziaWG Documentation Portal running on http://0.0.0.0:${PORT}`);
  console.log(`📚 This is a web-based documentation portal for the AmneziaWG Docker VPN Server`);
  console.log(`⚠️  Note: The actual VPN server requires Docker and cannot run in this environment`);
});
