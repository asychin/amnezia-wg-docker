import express, { Request, Response } from 'express';
import { execFile } from 'child_process';
import { promisify } from 'util';
import cors from 'cors';
import * as fs from 'fs/promises';
import * as path from 'path';
import QRCode from 'qrcode';
import {
  getAllClients,
  getClientByName,
  createClient,
  deleteClient,
  syncClientFromFilesystem,
  markConfigDownloaded,
  getSetting,
  setSetting,
  getAllSettings,
  db
} from './storage';
import archiver from 'archiver';
import { vpnClients } from '../shared/schema';
import { sql } from 'drizzle-orm';

const execFileAsync = promisify(execFile);
const execAsync = promisify(require('child_process').exec);
const router = express.Router();

router.use(cors());
router.use(express.json());

const CLIENTS_DIR = process.env.CLIENTS_DIR || './clients';
const VPN_CONTAINER_NAME = process.env.VPN_CONTAINER_NAME || 'amneziawg-server';

// Execute command in VPN container via docker exec
async function execInVpnContainer(command: string): Promise<{ stdout: string; stderr: string }> {
  const dockerCommand = `docker exec ${VPN_CONTAINER_NAME} ${command}`;
  return execAsync(dockerCommand);
}

/**
 * ⚠️ БЕЗОПАСНОСТЬ: Middleware для авторизации API
 * 
 * Установите переменную окружения API_SECRET для защиты API.
 * Без API_SECRET сервер работает в DEMO режиме (только для разработки!).
 * 
 * Для продакшена ОБЯЗАТЕЛЬНО установите API_SECRET:
 * export API_SECRET="your-secure-random-string-here"
 * 
 * Использование: добавьте заголовок Authorization: Bearer YOUR_API_SECRET
 */
const API_SECRET = process.env.API_SECRET;

function requireAuth(req: Request, res: Response, next: Function) {
  // Если API_SECRET не установлен - работаем в DEMO режиме
  if (!API_SECRET) {
    console.warn('⚠️  WARNING: API_SECRET not set! Running in DEMO mode (INSECURE for production!)');
    next();
    return;
  }
  
  // Проверка заголовка Authorization
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ 
      error: 'Unauthorized',
      message: 'API_SECRET is required. Add Authorization: Bearer YOUR_API_SECRET header.'
    });
  }
  
  const token = authHeader.substring(7); // Убрать "Bearer "
  if (token !== API_SECRET) {
    return res.status(401).json({ error: 'Invalid API secret' });
  }
  
  next();
}

/**
 * Валидация имени клиента (дублирует логику из manage-clients.sh)
 * Защита от:
 * - Command injection
 * - Path traversal  
 * - Недопустимых символов
 */
function isValidClientName(name: string): { valid: boolean; error?: string } {
  // Проверка пустое имя или слишком длинное
  if (!name || name.length === 0) {
    return { valid: false, error: 'Client name cannot be empty' };
  }
  
  if (name.length > 64) {
    return { valid: false, error: 'Client name too long (max 64 characters)' };
  }
  
  // Проверка разрешенных символов - только [A-Za-z0-9_-]
  if (!/^[A-Za-z0-9_-]+$/.test(name)) {
    return { valid: false, error: 'Client name can only contain letters, numbers, underscores and dashes' };
  }
  
  // Проверка что имя НЕ начинается с дефиса (защита от флагов командной строки)
  if (name.startsWith('-')) {
    return { valid: false, error: 'Client name cannot start with a dash' };
  }
  
  // Проверка path traversal
  if (name.includes('..') || name.includes('/')) {
    return { valid: false, error: 'Client name cannot contain .. or /' };
  }
  
  return { valid: true };
}

function isValidIPv4(ip: string): boolean {
  // Строгая валидация - только цифры и точки
  if (!/^[0-9.]+$/.test(ip)) return false;
  
  // Проверка структуры IPv4
  const parts = ip.split('.');
  if (parts.length !== 4) return false;
  
  return parts.every(part => {
    const num = parseInt(part, 10);
    return num >= 0 && num <= 255 && part === num.toString();
  });
}

async function syncClientsFromFilesystem() {
  try {
    try {
      await fs.access(CLIENTS_DIR);
    } catch {
      console.log(`⚠️  Clients directory ${CLIENTS_DIR} does not exist, creating it...`);
      await fs.mkdir(CLIENTS_DIR, { recursive: true });
      console.log('✅ Clients directory created');
      console.log('✅ Filesystem sync completed (no existing clients)');
      return;
    }
    
    const files = await fs.readdir(CLIENTS_DIR);
    const confFiles = files.filter(f => f.endsWith('.conf'));
    
    if (confFiles.length === 0) {
      console.log('✅ Filesystem sync completed (no existing clients)');
      return;
    }
    
    for (const file of confFiles) {
      const clientName = path.basename(file, '.conf');
      const configPath = path.join(CLIENTS_DIR, file);
      const publicKeyPath = path.join(CLIENTS_DIR, `${clientName}_public.key`);
      
      try {
        const config = await fs.readFile(configPath, 'utf-8');
        const publicKey = await fs.readFile(publicKeyPath, 'utf-8');
        
        const ipMatch = config.match(/Address\s*=\s*([0-9.]+)/);
        const ipAddress = ipMatch ? ipMatch[1] : '';
        
        if (ipAddress && publicKey.trim()) {
          await syncClientFromFilesystem(clientName, ipAddress, publicKey.trim());
          console.log(`✅ Synced client: ${clientName}`);
        }
      } catch (err) {
        console.error(`❌ Error syncing client ${clientName}:`, err);
      }
    }
    
    console.log('✅ Filesystem sync completed');
  } catch (err) {
    console.error('❌ Error during filesystem sync:', err);
  }
}

// SECURITY: Возвращает ТОЛЬКО безопасные метаданные из БД
// НЕ возвращает приватные ключи и конфигурационные файлы!
// Возвращаемые данные: id, name, ipAddress, publicKey (клиента), createdAt, updatedAt, enabled
router.get('/clients', async (req: Request, res: Response) => {
  try {
    const clients = await getAllClients();
    // Возвращаем только данные из БД (без чтения файлов конфигурации)
    res.json(clients);
  } catch (error) {
    console.error('Error fetching clients:', error);
    res.status(500).json({ error: 'Failed to fetch clients' });
  }
});

router.get('/clients/:name', async (req: Request, res: Response) => {
  try {
    const { name } = req.params;
    const client = await getClientByName(name);
    
    if (!client) {
      return res.status(404).json({ error: 'Client not found' });
    }
    
    res.json(client);
  } catch (error) {
    console.error('Error fetching client:', error);
    res.status(500).json({ error: 'Failed to fetch client' });
  }
});

router.post('/clients', requireAuth, async (req: Request, res: Response) => {
  try {
    const { name, ipAddress } = req.body;
    
    const validation = isValidClientName(name);
    if (!validation.valid) {
      return res.status(400).json({ error: validation.error });
    }
    
    if (ipAddress && !isValidIPv4(ipAddress)) {
      return res.status(400).json({ error: 'Invalid IP address format. Only IPv4 addresses (0-255.0-255.0-255.0-255) are allowed.' });
    }
    
    const existing = await getClientByName(name);
    if (existing) {
      return res.status(409).json({ error: 'Client already exists' });
    }
    
    const scriptArgs = ipAddress ? `add ${name} ${ipAddress}` : `add ${name}`;
    const { stdout, stderr } = await execInVpnContainer(`/app/scripts/manage-clients.sh ${scriptArgs}`);
    
    console.log('Script output:', stdout);
    if (stderr) console.error('Script stderr:', stderr);
    
    const configPath = path.join(CLIENTS_DIR, `${name}.conf`);
    const publicKeyPath = path.join(CLIENTS_DIR, `${name}_public.key`);
    
    const config = await fs.readFile(configPath, 'utf-8');
    const publicKey = await fs.readFile(publicKeyPath, 'utf-8');
    
    const ipMatch = config.match(/Address\s*=\s*([0-9.]+)/);
    const assignedIp = ipMatch ? ipMatch[1] : ipAddress || '';
    
    const client = await createClient({
      name,
      ipAddress: assignedIp,
      publicKey: publicKey.trim(),
      enabled: true,
    });
    
    res.status(201).json(client);
  } catch (error: any) {
    console.error('Error adding client:', error);
    res.status(500).json({ error: error.message || 'Failed to add client' });
  }
});

router.delete('/clients/:name', requireAuth, async (req: Request, res: Response) => {
  try {
    const { name } = req.params;
    
    const validation = isValidClientName(name);
    if (!validation.valid) {
      return res.status(400).json({ error: validation.error });
    }
    
    const client = await getClientByName(name);
    if (!client) {
      return res.status(404).json({ error: 'Client not found' });
    }
    
    const { stdout, stderr } = await execInVpnContainer(`/app/scripts/manage-clients.sh remove ${name}`);
    
    console.log('Script output:', stdout);
    if (stderr) console.error('Script stderr:', stderr);
    
    await deleteClient(name);
    
    res.json({ success: true, message: `Client ${name} deleted` });
  } catch (error: any) {
    console.error('Error deleting client:', error);
    res.status(500).json({ error: error.message || 'Failed to delete client' });
  }
});

// SECURITY: Этот endpoint возвращает полный конфигурационный файл (включая приватный ключ)
// Это ЯВНОЕ действие пользователя для скачивания конфигурации для импорта в VPN клиент
// НЕ должен вызываться автоматически - только по явному запросу пользователя
router.get('/clients/:name/config', requireAuth, async (req: Request, res: Response) => {
  try {
    const { name } = req.params;
    
    const validation = isValidClientName(name);
    if (!validation.valid) {
      return res.status(400).json({ error: validation.error });
    }
    
    const client = await getClientByName(name);
    if (!client) {
      return res.status(404).json({ error: 'Client not found' });
    }
    
    const configPath = path.join(CLIENTS_DIR, `${name}.conf`);
    const rawConfig = await fs.readFile(configPath, 'utf-8');
    // Strip comment lines from config
    const config = rawConfig
      .split('\n')
      .filter(line => !line.trim().startsWith('#'))
      .join('\n');
    
    res.type('text/plain').send(config);
  } catch (error: any) {
    console.error('Error fetching config:', error);
    res.status(500).json({ error: error.message || 'Failed to fetch config' });
  }
});

// SECURITY: Этот endpoint возвращает QR код с полной конфигурацией (включая приватный ключ)
// Это ЯВНОЕ действие пользователя для генерации QR кода для сканирования в VPN клиенте
// НЕ должен вызываться автоматически - только по явному запросу пользователя
router.get('/clients/:name/qr', requireAuth, async (req: Request, res: Response) => {
  try {
    const { name } = req.params;
    
    const validation = isValidClientName(name);
    if (!validation.valid) {
      return res.status(400).json({ error: validation.error });
    }
    
    const client = await getClientByName(name);
    if (!client) {
      return res.status(404).json({ error: 'Client not found' });
    }
    
    const configPath = path.join(CLIENTS_DIR, `${name}.conf`);
    const rawConfig = await fs.readFile(configPath, 'utf-8');
    // Strip comment lines from config
    const config = rawConfig
      .split('\n')
      .filter(line => !line.trim().startsWith('#'))
      .join('\n');
    
    const qrCodeDataUrl = await QRCode.toDataURL(config);
    
    res.json({ qrCode: qrCodeDataUrl });
  } catch (error: any) {
    console.error('Error generating QR code:', error);
    res.status(500).json({ error: error.message || 'Failed to generate QR code' });
  }
});

// Скачивание ZIP-архива с конфигом и QR-кодом
// Можно скачивать неограниченное количество раз
router.get('/clients/:name/bundle', requireAuth, async (req: Request, res: Response) => {
  try {
    const { name } = req.params;
    
    const validation = isValidClientName(name);
    if (!validation.valid) {
      return res.status(400).json({ error: validation.error });
    }
    
    const client = await getClientByName(name);
    if (!client) {
      return res.status(404).json({ error: 'Client not found' });
    }
    
    const configPath = path.join(CLIENTS_DIR, `${name}.conf`);
    const rawConfig = await fs.readFile(configPath, 'utf-8');
    // Strip comment lines from config
    const config = rawConfig
      .split('\n')
      .filter(line => !line.trim().startsWith('#'))
      .join('\n');
    
    // Generate QR code as PNG buffer
    const qrCodeBuffer = await QRCode.toBuffer(config, { type: 'png', width: 400 });
    
    // Create ZIP archive
    res.setHeader('Content-Type', 'application/zip');
    res.setHeader('Content-Disposition', `attachment; filename="${name}-vpn-config.zip"`);
    
    const archive = archiver('zip', { zlib: { level: 9 } });
    archive.pipe(res);
    
    // Add config file to archive
    archive.append(config, { name: `${name}.conf` });
    
    // Add QR code image to archive
    archive.append(qrCodeBuffer, { name: `${name}-qr.png` });
    
    // Add README with instructions
    const readme = `AmneziaWG VPN Configuration for ${name}
========================================

This archive contains:
- ${name}.conf - VPN configuration file
- ${name}-qr.png - QR code for mobile app

Installation Instructions:
--------------------------

For Desktop (Windows/macOS/Linux):
1. Install AmneziaVPN client from https://amnezia.org
2. Import the ${name}.conf file

For Mobile (iOS/Android):
1. Install AmneziaVPN app from App Store / Google Play
2. Scan the QR code (${name}-qr.png) or import the config file

SECURITY WARNING:
-----------------
This configuration contains your private VPN key.
Keep it secure and do not share with others.

Generated: ${new Date().toISOString()}
`;
    archive.append(readme, { name: 'README.txt' });
    
    await archive.finalize();
  } catch (error: any) {
    console.error('Error generating bundle:', error);
    res.status(500).json({ error: error.message || 'Failed to generate bundle' });
  }
});

router.post('/sync', async (req: Request, res: Response) => {
  try {
    await syncClientsFromFilesystem();
    const clients = await getAllClients();
    res.json({ success: true, clientCount: clients.length });
  } catch (error: any) {
    console.error('Error syncing clients:', error);
    res.status(500).json({ error: error.message || 'Failed to sync clients' });
  }
});

// Get VPN statistics for a specific client
router.get('/clients/:name/stats', async (req: Request, res: Response) => {
  try {
    const { name } = req.params;
    
    const validation = isValidClientName(name);
    if (!validation.valid) {
      return res.status(400).json({ error: validation.error });
    }
    
    const client = await getClientByName(name);
    if (!client) {
      return res.status(404).json({ error: 'Client not found' });
    }
    
    // Get stats from awg show command
    const { stdout } = await execInVpnContainer('awg show awg0 dump');
    const lines = stdout.trim().split('\n');
    
    // Parse the dump output to find this client's stats
    // Format: public_key, preshared_key, endpoint, allowed_ips, latest_handshake, transfer_rx, transfer_tx, persistent_keepalive
    let stats = {
      endpoint: null as string | null,
      latestHandshake: null as number | null,
      transferRx: 0,
      transferTx: 0,
      connected: false
    };
    
    for (const line of lines) {
      const parts = line.split('\t');
      if (parts.length >= 7 && parts[0] === client.publicKey) {
        stats.endpoint = parts[2] !== '(none)' ? parts[2] : null;
        stats.latestHandshake = parts[4] !== '0' ? parseInt(parts[4]) * 1000 : null; // Convert to ms
        stats.transferRx = parseInt(parts[5]) || 0;
        stats.transferTx = parseInt(parts[6]) || 0;
        // Consider connected if handshake was within last 3 minutes
        stats.connected = stats.latestHandshake !== null && 
          (Date.now() - stats.latestHandshake) < 180000;
        break;
      }
    }
    
    res.json(stats);
  } catch (error: any) {
    console.error('Error fetching client stats:', error);
    res.status(500).json({ error: error.message || 'Failed to fetch client stats' });
  }
});

// Get list of legacy clients (flat-file only, not in database)
router.get('/migration/legacy-clients', async (req: Request, res: Response) => {
  try {
    const files = await fs.readdir(CLIENTS_DIR);
    const confFiles = files.filter(f => f.endsWith('.conf'));
    
    const dbClients = await getAllClients();
    const dbClientNames = new Set(dbClients.map(c => c.name));
    
    const legacyClients = [];
    for (const file of confFiles) {
      const clientName = path.basename(file, '.conf');
      if (!dbClientNames.has(clientName)) {
        const configPath = path.join(CLIENTS_DIR, file);
        const config = await fs.readFile(configPath, 'utf-8');
        const ipMatch = config.match(/Address\s*=\s*([0-9.]+)/);
        legacyClients.push({
          name: clientName,
          ipAddress: ipMatch ? ipMatch[1] : 'unknown'
        });
      }
    }
    
    res.json({ legacyClients, count: legacyClients.length });
  } catch (error: any) {
    console.error('Error fetching legacy clients:', error);
    res.status(500).json({ error: error.message || 'Failed to fetch legacy clients' });
  }
});

// Migrate all legacy clients to database
router.post('/migration/migrate-all', requireAuth, async (req: Request, res: Response) => {
  try {
    await syncClientsFromFilesystem();
    const clients = await getAllClients();
    res.json({ success: true, migratedCount: clients.length });
  } catch (error: any) {
    console.error('Error migrating clients:', error);
    res.status(500).json({ error: error.message || 'Failed to migrate clients' });
  }
});

// Settings endpoints
router.get('/settings', async (req: Request, res: Response) => {
  try {
    const settings = await getAllSettings();
    res.json(settings);
  } catch (error: any) {
    console.error('Error fetching settings:', error);
    res.status(500).json({ error: error.message || 'Failed to fetch settings' });
  }
});

router.get('/settings/:key', async (req: Request, res: Response) => {
  try {
    const { key } = req.params;
    const value = await getSetting(key);
    res.json({ key, value });
  } catch (error: any) {
    console.error('Error fetching setting:', error);
    res.status(500).json({ error: error.message || 'Failed to fetch setting' });
  }
});

router.post('/settings/:key', requireAuth, async (req: Request, res: Response) => {
  try {
    const { key } = req.params;
    const { value } = req.body;
    
    if (typeof value !== 'string') {
      return res.status(400).json({ error: 'Value must be a string' });
    }
    
    const setting = await setSetting(key, value);
    res.json(setting);
  } catch (error: any) {
    console.error('Error saving setting:', error);
    res.status(500).json({ error: error.message || 'Failed to save setting' });
  }
});

export { router as apiRouter, syncClientsFromFilesystem };
