import { useMemo } from 'react';
import { useServers } from '@/contexts/ServerContext';
import { 
  createApiInstance, 
  createServerApi, 
  createClientsApi, 
  createLogsApi, 
  createStatsApi 
} from '@/services/api';

export const useCurrentServerApi = () => {
  const { currentServer } = useServers();

  const apis = useMemo(() => {
    if (!currentServer || !currentServer.isConnected) {
      return null;
    }

    const apiInstance = createApiInstance(
      currentServer.endpoint,
      currentServer.auth?.token
    );

    return {
      server: createServerApi(apiInstance),
      clients: createClientsApi(apiInstance),
      logs: createLogsApi(apiInstance, currentServer.endpoint),
      stats: createStatsApi(apiInstance),
      instance: apiInstance,
    };
  }, [currentServer]);

  return {
    apis,
    currentServer,
    isConnected: currentServer?.isConnected || false,
    hasServer: !!currentServer,
  };
};
