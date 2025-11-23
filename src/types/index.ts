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
