/**
 * Connection String Format: awgwc://base64url(JSON)
 * 
 * JSON Structure:
 * {
 *   "endpoint": "https://server.example.com:8080",
 *   "server_info": {
 *     "name": "My AmneziaWG Server",
 *     "description": "Production server",
 *     "capabilities": ["vpn_management", "logs_access", "stats_view"]
 *   },
 *   "auth_info": {
 *     "method": "jwt",
 *     "login_endpoint": "/api/v1/auth/login"
 *   }
 * }
 */

export interface ConnectionStringData {
  endpoint: string;
  server_info: {
    name: string;
    description?: string;
    capabilities: string[];
  };
  auth_info: {
    method: string;
    login_endpoint: string;
  };
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
    if (!data.endpoint || !data.server_info || !data.auth_info) {
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
    id: generateConnectionId(data.endpoint),
    name: data.server_info.name,
    description: data.server_info.description,
    endpoint: data.endpoint,
    capabilities: data.server_info.capabilities,
    isConnected: false,
    lastSeen: undefined,
    auth: undefined,
  };
}
