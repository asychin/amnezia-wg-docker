import { pgTable, serial, varchar, timestamp, boolean } from 'drizzle-orm/pg-core';

export const vpnClients = pgTable('vpn_clients', {
  id: serial('id').primaryKey(),
  name: varchar('name', { length: 255 }).notNull().unique(),
  ipAddress: varchar('ip_address', { length: 50 }).notNull(),
  publicKey: varchar('public_key', { length: 255 }).notNull(),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
  enabled: boolean('enabled').default(true).notNull(),
  lastHandshake: timestamp('last_handshake'),
  configDownloadedAt: timestamp('config_downloaded_at'),
});

export type VpnClient = typeof vpnClients.$inferSelect;
export type NewVpnClient = typeof vpnClients.$inferInsert;
