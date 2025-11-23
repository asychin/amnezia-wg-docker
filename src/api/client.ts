import type { VpnClient, CreateClientRequest, QRCodeResponse } from '../types';

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
