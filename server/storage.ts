import { drizzle } from 'drizzle-orm/node-postgres';
import { Pool } from 'pg';
import { vpnClients, type VpnClient, type NewVpnClient } from '../shared/schema';
import { eq } from 'drizzle-orm';
import * as dotenv from 'dotenv';

dotenv.config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
});

export const db = drizzle(pool);

export async function getAllClients(): Promise<VpnClient[]> {
  // SECURITY: Возвращаем только безопасные метаданные из БД
  // Приватные ключи НЕ хранятся в БД - только в файлах
  // Возвращаемые поля: id, name, ipAddress, publicKey (клиента), createdAt, updatedAt, enabled, lastHandshake
  return await db.select({
    id: vpnClients.id,
    name: vpnClients.name,
    ipAddress: vpnClients.ipAddress,
    publicKey: vpnClients.publicKey,
    createdAt: vpnClients.createdAt,
    updatedAt: vpnClients.updatedAt,
    enabled: vpnClients.enabled,
    lastHandshake: vpnClients.lastHandshake,
  }).from(vpnClients);
}

export async function getClientByName(name: string): Promise<VpnClient | undefined> {
  // SECURITY: Возвращаем только безопасные метаданные из БД (не читаем файлы конфигурации)
  const results = await db.select({
    id: vpnClients.id,
    name: vpnClients.name,
    ipAddress: vpnClients.ipAddress,
    publicKey: vpnClients.publicKey,
    createdAt: vpnClients.createdAt,
    updatedAt: vpnClients.updatedAt,
    enabled: vpnClients.enabled,
    lastHandshake: vpnClients.lastHandshake,
  }).from(vpnClients).where(eq(vpnClients.name, name));
  return results[0];
}

export async function createClient(client: NewVpnClient): Promise<VpnClient> {
  const results = await db.insert(vpnClients).values(client).returning();
  return results[0];
}

export async function updateClient(name: string, updates: Partial<VpnClient>): Promise<VpnClient | undefined> {
  const results = await db
    .update(vpnClients)
    .set({ ...updates, updatedAt: new Date() })
    .where(eq(vpnClients.name, name))
    .returning();
  return results[0];
}

export async function deleteClient(name: string): Promise<boolean> {
  const results = await db.delete(vpnClients).where(eq(vpnClients.name, name)).returning();
  return results.length > 0;
}

export async function syncClientFromFilesystem(
  name: string,
  ipAddress: string,
  publicKey: string
): Promise<VpnClient> {
  const existing = await getClientByName(name);
  
  if (existing) {
    return await updateClient(name, { ipAddress, publicKey }) || existing;
  }
  
  return await createClient({
    name,
    ipAddress,
    publicKey,
    enabled: true,
  });
}
