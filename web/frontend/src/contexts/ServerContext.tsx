import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { ServerConnection, ConnectionStringData, createServerConnection, parseConnectionString } from '@/utils/connectionString';

interface ServerContextType {
  servers: ServerConnection[];
  currentServer: ServerConnection | null;
  addServer: (connectionString: string) => Promise<{ success: boolean; error?: string }>;
  removeServer: (serverId: string) => void;
  selectServer: (serverId: string) => void;
  connectToServer: (serverId: string, credentials: { username: string; password: string }) => Promise<{ success: boolean; error?: string }>;
  disconnectFromServer: (serverId: string) => void;
  isLoading: boolean;
}

const ServerContext = createContext<ServerContextType | undefined>(undefined);

interface ServerProviderProps {
  children: ReactNode;
}

const STORAGE_KEY = 'amneziawg-servers';

export const ServerProvider: React.FC<ServerProviderProps> = ({ children }) => {
  const [servers, setServers] = useState<ServerConnection[]>([]);
  const [currentServer, setCurrentServer] = useState<ServerConnection | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  // Load servers from localStorage on mount
  useEffect(() => {
    try {
      const savedServers = localStorage.getItem(STORAGE_KEY);
      if (savedServers) {
        const parsedServers = JSON.parse(savedServers) as ServerConnection[];
        // Convert lastSeen strings back to Date objects
        const serversWithDates = parsedServers.map(server => ({
          ...server,
          lastSeen: server.lastSeen ? new Date(server.lastSeen) : undefined,
          auth: server.auth ? {
            ...server.auth,
            expiresAt: server.auth.expiresAt ? new Date(server.auth.expiresAt) : undefined,
          } : undefined,
        }));
        setServers(serversWithDates);
        
        // Set first connected server as current, or first server if none connected
        const connectedServer = serversWithDates.find(s => s.isConnected);
        const firstServer = serversWithDates[0];
        setCurrentServer(connectedServer || firstServer || null);
      }
    } catch (error) {
      console.error('Failed to load servers from localStorage:', error);
    }
  }, []);

  // Save servers to localStorage whenever servers change
  useEffect(() => {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(servers));
    } catch (error) {
      console.error('Failed to save servers to localStorage:', error);
    }
  }, [servers]);

  const addServer = async (connectionString: string): Promise<{ success: boolean; error?: string }> => {
    try {
      setIsLoading(true);
      
      // Parse connection string
      const connectionData: ConnectionStringData = parseConnectionString(connectionString);
      const newServer = createServerConnection(connectionData);

      // Check if server already exists
      const existingServer = servers.find(s => s.id === newServer.id);
      if (existingServer) {
        return { success: false, error: 'Server already exists' };
      }

      // Test connection to server
      try {
        const response = await fetch(`${newServer.endpoint}/api/v1/server/info`, {
          method: 'GET',
          headers: {
            'Content-Type': 'application/json',
          },
          signal: AbortSignal.timeout(10000), // 10 second timeout
        });

        if (!response.ok) {
          throw new Error(`Server responded with status: ${response.status}`);
        }

        const serverInfo = await response.json();
        
        // Update server with actual info from server
        newServer.name = serverInfo.name || newServer.name;
        newServer.description = serverInfo.description || newServer.description;
        newServer.lastSeen = new Date();
        
      } catch (error) {
        console.warn('Failed to connect to server during add:', error);
        // We'll still add the server, but mark it as not connected
      }

      // Add server to list
      setServers(prev => [...prev, newServer]);
      
      // If this is the first server, make it current
      if (servers.length === 0) {
        setCurrentServer(newServer);
      }

      return { success: true };
    } catch (error) {
      return { 
        success: false, 
        error: error instanceof Error ? error.message : 'Failed to add server' 
      };
    } finally {
      setIsLoading(false);
    }
  };

  const removeServer = (serverId: string) => {
    setServers(prev => prev.filter(s => s.id !== serverId));
    
    // If removed server was current, select another one
    if (currentServer?.id === serverId) {
      const remainingServers = servers.filter(s => s.id !== serverId);
      setCurrentServer(remainingServers[0] || null);
    }
  };

  const selectServer = (serverId: string) => {
    const server = servers.find(s => s.id === serverId);
    if (server) {
      setCurrentServer(server);
    }
  };

  const connectToServer = async (serverId: string, credentials: { username: string; password: string }): Promise<{ success: boolean; error?: string }> => {
    const server = servers.find(s => s.id === serverId);
    if (!server) {
      return { success: false, error: 'Server not found' };
    }

    setIsLoading(true);

    try {
      // Attempt to login
      const response = await fetch(`${server.endpoint}/api/v1/auth/login`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(credentials),
      });

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({ error: 'Authentication failed' }));
        return { success: false, error: errorData.error || 'Authentication failed' };
      }

      const authData = await response.json();
      
      // Update server with auth info
      setServers(prev => prev.map(s => 
        s.id === serverId 
          ? {
              ...s,
              isConnected: true,
              lastSeen: new Date(),
              auth: {
                token: authData.access_token,
                refreshToken: authData.refresh_token,
                expiresAt: new Date(Date.now() + (authData.expires_in * 1000)),
              }
            }
          : s
      ));

      return { success: true };
    } catch (error) {
      return { 
        success: false, 
        error: error instanceof Error ? error.message : 'Connection failed' 
      };
    } finally {
      setIsLoading(false);
    }
  };

  const disconnectFromServer = (serverId: string) => {
    setServers(prev => prev.map(s => 
      s.id === serverId 
        ? { ...s, isConnected: false, auth: undefined }
        : s
    ));
  };

  const value: ServerContextType = {
    servers,
    currentServer,
    addServer,
    removeServer,
    selectServer,
    connectToServer,
    disconnectFromServer,
    isLoading,
  };

  return (
    <ServerContext.Provider value={value}>
      {children}
    </ServerContext.Provider>
  );
};

export const useServers = (): ServerContextType => {
  const context = useContext(ServerContext);
  if (context === undefined) {
    throw new Error('useServers must be used within a ServerProvider');
  }
  return context;
};
