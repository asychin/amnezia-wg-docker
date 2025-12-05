import type { VpnClient, CreateClientRequest, QRCodeResponse, ClientStats, LegacyClientsResponse } from '../types';

const API_BASE = '/api';

export async function fetchClients(): Promise<VpnClient[]> {
  const response = await fetch(`${API_BASE}/clients`);
  if (!response.ok) {
    throw new Error('Failed to fetch clients');
  }
  return response.json();
}

export async function createClient(data: CreateClientRequest): Promise<VpnClient> {
  const response = await fetch(`${API_BASE}/clients`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(data),
  });
  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.error || 'Failed to create client');
  }
  return response.json();
}

export async function deleteClient(name: string): Promise<void> {
  const response = await fetch(`${API_BASE}/clients/${name}`, {
    method: 'DELETE',
  });
  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.error || 'Failed to delete client');
  }
}

export async function fetchClientQR(name: string): Promise<QRCodeResponse> {
  const response = await fetch(`${API_BASE}/clients/${name}/qr`);
  if (!response.ok) {
    throw new Error('Failed to fetch QR code');
  }
  return response.json();
}

export async function fetchClientConfig(name: string): Promise<string> {
  const response = await fetch(`${API_BASE}/clients/${name}/config`);
  if (!response.ok) {
    throw new Error('Failed to fetch config');
  }
  return response.text();
}

export async function syncClients(): Promise<void> {
  const response = await fetch(`${API_BASE}/sync`, {
    method: 'POST',
  });
  if (!response.ok) {
    throw new Error('Failed to sync clients');
  }
}

export async function fetchClientStats(name: string): Promise<ClientStats> {
  const response = await fetch(`${API_BASE}/clients/${name}/stats`);
  if (!response.ok) {
    throw new Error('Failed to fetch client stats');
  }
  return response.json();
}

export async function fetchLegacyClients(): Promise<LegacyClientsResponse> {
  const response = await fetch(`${API_BASE}/migration/legacy-clients`);
  if (!response.ok) {
    throw new Error('Failed to fetch legacy clients');
  }
  return response.json();
}

export async function migrateAllClients(): Promise<{ success: boolean; migratedCount: number }> {
  const response = await fetch(`${API_BASE}/migration/migrate-all`, {
    method: 'POST',
  });
  if (!response.ok) {
    throw new Error('Failed to migrate clients');
  }
  return response.json();
}

export function downloadConfig(name: string, config: string): void {
  const blob = new Blob([config], { type: 'text/plain' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `${name}.conf`;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
}

export function downloadQRCode(name: string, qrCodeDataUrl: string): void {
  const a = document.createElement('a');
  a.href = qrCodeDataUrl;
  a.download = `${name}-qr.png`;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
}

export async function downloadBundle(name: string): Promise<{ success: boolean; error?: string }> {
  const response = await fetch(`${API_BASE}/clients/${name}/bundle`);
  
  if (!response.ok) {
    const error = await response.json();
    return { 
      success: false, 
      error: error.message || error.error || 'Failed to download bundle' 
    };
  }
  
  const blob = await response.blob();
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `${name}-vpn-config.zip`;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
  
  return { success: true };
}
