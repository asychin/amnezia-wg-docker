// API типы для AmneziaWG Web Interface

export interface ServerStatus {
  running: boolean;
  uptime: number;
  version: string;
  publicIp: string;
  port: number;
  interface: string;
  clients: {
    total: number;
    connected: number;
  };
  traffic: {
    sent: number;
    received: number;
  };
}

export interface Client {
  name: string;
  ip: string;
  publicKey: string;
  createdAt: string;
  lastHandshake?: string;
  connected: boolean;
  traffic: {
    sent: number;
    received: number;
  };
}

export interface ServerConfig {
  interface: string;
  port: number;
  network: string;
  serverIp: string;
  dns: string[];
  publicIp: string;
  obfuscation: {
    jc: number;
    jmin: number;
    jmax: number;
    s1: number;
    s2: number;
    h1: number;
    h2: number;
    h3: number;
    h4: number;
  };
}

export interface LogEntry {
  timestamp: string;
  level: 'info' | 'warn' | 'error' | 'debug';
  message: string;
  source?: string;
}

export interface ConnectionStats {
  timestamp: string;
  connectedClients: number;
  bandwidthIn: number;
  bandwidthOut: number;
  totalTraffic: number;
}

export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  message?: string;
  error?: string;
}

export interface CreateClientRequest {
  name: string;
  ip?: string;
}

export interface ClientConfig {
  name: string;
  config: string;
  qrCode?: string;
}
