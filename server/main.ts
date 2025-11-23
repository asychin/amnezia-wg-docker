import express from 'express';
import path from 'path';
import fs from 'fs';
import { apiRouter, syncClientsFromFilesystem } from './api';
import * as dotenv from 'dotenv';
import { db } from './storage';
import { sql } from 'drizzle-orm';

dotenv.config();

const app = express();
const port = Number(process.env.API_PORT || 3001);

app.use(express.json());

app.use('/api', apiRouter);

app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, '../views'));

const envExample = fs.readFileSync('env.example', 'utf8');
const readme = fs.readFileSync('README.md', 'utf8');
const version = fs.readFileSync('VERSION', 'utf8').trim();

app.get('/docs', (req, res) => {
  res.render('index', {
    version,
    envExample,
    readme
  });
});

app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'AmneziaWG VPN Management API' });
});

if (process.env.NODE_ENV === 'production') {
  app.use(express.static(path.join(__dirname, '../dist')));
  
  app.get('*', (req, res) => {
    res.sendFile(path.join(__dirname, '../dist/index.html'));
  });
} else {
  app.use(express.static(path.join(__dirname, '../public')));
}

async function initializeDatabase() {
  try {
    console.log('🔄 Initializing database...');
    await db.execute(sql`SELECT 1`);
    console.log('✅ Database connection established');
    
    console.log('🔄 Syncing clients from filesystem...');
    await syncClientsFromFilesystem();
    console.log('✅ Clients synced');
  } catch (error) {
    console.error('❌ Database initialization error:', error);
    process.exit(1);
  }
}

app.listen(port, '0.0.0.0', async () => {
  console.log(`✅ AmneziaWG API Server running on http://0.0.0.0:${port}`);
  console.log(`📚 Documentation portal: http://0.0.0.0:${port}/docs`);
  console.log(`🔌 API endpoints: http://0.0.0.0:${port}/api/*`);
  
  await initializeDatabase();
});
