export interface VpnClient {
  id: number;
  name: string;
  ipAddress: string;
  publicKey: string;
  createdAt: string;
  updatedAt: string;
  enabled: boolean;
  lastHandshake: string | null;
}

export interface CreateClientRequest {
  name: string;
  ipAddress?: string;
}

export interface QRCodeResponse {
  qrCode: string;
}

export interface ClientStats {
  endpoint: string | null;
  latestHandshake: number | null;
  transferRx: number;
  transferTx: number;
  connected: boolean;
}

export interface LegacyClient {
  name: string;
  ipAddress: string;
}

export interface LegacyClientsResponse {
  legacyClients: LegacyClient[];
  count: number;
}
