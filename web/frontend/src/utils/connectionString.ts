/**
 * Connection String Format: awgwc://base64url(JSON)
 * 
 * JSON Structure (Backend format):
 * {
 *   "version": "1.0",
 *   "name": "My AmneziaWG Server",
 *   "api_endpoint": "https://server.example.com:8080/api/v1",
 *   "server_info": {
 *     "id": "uuid",
 *     "location": "Moscow",
 *     "public_key_fingerprint": "sha256:..."
 *   },
 *   "capabilities": ["clients", "logs", "stats", "config"],
 *   "auth": {
 *     "method": "jwt",
 *     "refresh_endpoint": "/auth/refresh"
 *   },
 *   "created_at": "2025-08-17T09:59:49.718264712Z",
 *   "expires_at": "2025-09-16T09:59:49.718264712Z"
 * }
 */

export interface ConnectionStringData {
  version: string;
  name: string;
  api_endpoint: string;
  server_info: {
    id: string;
    location: string;
    public_key_fingerprint: string;
  };
  capabilities: string[];
  auth: {
    method: string;
    refresh_endpoint: string;
  };
  created_at: string;
  expires_at: string;
}

export interface ServerConnection {
  id: string;
  name: string;
  description?: string;
  endpoint: string;
  capabilities: string[];
  isConnected: boolean;
  lastSeen?: Date;
  auth?: {
    token?: string;
    refreshToken?: string;
    expiresAt?: Date;
  };
}

/**
 * Parse connection string from awgwc:// format
 */
export function parseConnectionString(connectionString: string): ConnectionStringData {
  if (!connectionString.startsWith('awgwc://')) {
    throw new Error('Invalid connection string format. Must start with awgwc://');
  }

  try {
    // Remove prefix and decode base64url
    const base64Data = connectionString.substring(8); // Remove 'awgwc://'
    const jsonData = atob(base64Data.replace(/-/g, '+').replace(/_/g, '/'));
    const data = JSON.parse(jsonData) as ConnectionStringData;

    // Validate required fields
    if (!data.version || !data.name || !data.api_endpoint || !data.server_info || !data.auth) {
      throw new Error('Invalid connection string data structure');
    }

    return data;
  } catch (error) {
    if (error instanceof SyntaxError) {
      throw new Error('Invalid connection string: malformed JSON data');
    }
    throw new Error(`Failed to parse connection string: ${error instanceof Error ? error.message : 'Unknown error'}`);
  }
}

/**
 * Generate connection string ID from endpoint
 */
export function generateConnectionId(endpoint: string): string {
  // Use URL host + port as unique identifier
  try {
    const url = new URL(endpoint);
    return `${url.host}:${url.port || (url.protocol === 'https:' ? '443' : '80')}`;
  } catch {
    // Fallback to simple hash if URL parsing fails
    return btoa(endpoint).replace(/[^a-zA-Z0-9]/g, '').substring(0, 16);
  }
}

/**
 * Validate connection string format
 */
export function validateConnectionString(connectionString: string): { isValid: boolean; error?: string } {
  try {
    parseConnectionString(connectionString);
    return { isValid: true };
  } catch (error) {
    return { 
      isValid: false, 
      error: error instanceof Error ? error.message : 'Unknown validation error' 
    };
  }
}

/**
 * Create ServerConnection from ConnectionStringData
 */
export function createServerConnection(data: ConnectionStringData): ServerConnection {
  return {
    id: generateConnectionId(data.api_endpoint),
    name: data.name,
    description: data.server_info.location,
    endpoint: data.api_endpoint,
    capabilities: data.capabilities,
    isConnected: false,
    lastSeen: undefined,
    auth: undefined,
  };
}
