import React, { useState } from 'react';
import {
  HStack,
  VStack,
  Text,
  Button,
  MenuRoot,
  MenuTrigger,
  MenuContent,
  MenuItem,
  MenuSeparator,
  Badge,
  Box,
  IconButton,
  useDisclosure,
} from '@chakra-ui/react';
import { 
  LuServer, 
  LuChevronDown, 
  LuPlus, 
  LuWifi, 
  LuWifiOff,
  LuTrash2,
  LuLogOut,
  LuLogIn,
} from 'react-icons/lu';
import { useServers } from '@/contexts/ServerContext';
import AddServerModal from './AddServerModal';
import ConnectServerModal from './ConnectServerModal';

const ServerSelector: React.FC = () => {
  const { 
    servers, 
    currentServer, 
    selectServer, 
    removeServer, 
    disconnectFromServer 
  } = useServers();
  
  const addModal = useDisclosure();
  const connectModal = useDisclosure();
  const [connectingServerId, setConnectingServerId] = useState<string>('');

  const handleConnectToServer = (serverId: string) => {
    setConnectingServerId(serverId);
    connectModal.onOpen();
  };

  const handleDisconnectFromServer = (serverId: string) => {
    disconnectFromServer(serverId);
  };

  const formatLastSeen = (lastSeen?: Date) => {
    if (!lastSeen) return 'Never';
    const now = new Date();
    const diff = now.getTime() - lastSeen.getTime();
    const minutes = Math.floor(diff / 60000);
    
    if (minutes < 1) return 'Just now';
    if (minutes < 60) return `${minutes}m ago`;
    const hours = Math.floor(minutes / 60);
    if (hours < 24) return `${hours}h ago`;
    const days = Math.floor(hours / 24);
    return `${days}d ago`;
  };

  if (servers.length === 0) {
    return (
      <>
        <Button
          colorScheme="blue"
          size="sm"
          onClick={addModal.onOpen}
        >
          <LuPlus size="16" />
          Add Server
        </Button>
        <AddServerModal isOpen={addModal.open} onClose={addModal.onClose} />
      </>
    );
  }

  return (
    <>
      <HStack gap="2">
        {/* Current Server Display + Selector */}
        <MenuRoot>
          <MenuTrigger asChild>
            <Button variant="outline" size="sm">
              <HStack gap="2">
                <LuServer size="16" />
                <VStack gap="0" align="start">
                  <Text fontSize="sm" fontWeight="medium">
                    {currentServer?.name || 'No server selected'}
                  </Text>
                  {currentServer && (
                    <HStack gap="1">
                      <Box color={currentServer.isConnected ? 'green.solid' : 'red.solid'}>
                        {currentServer.isConnected ? <LuWifi size="12" /> : <LuWifiOff size="12" />}
                      </Box>
                      <Text fontSize="xs" color="fg.muted">
                        {currentServer.isConnected ? 'Connected' : 'Disconnected'}
                      </Text>
                    </HStack>
                  )}
                </VStack>
                <LuChevronDown size="14" />
              </HStack>
            </Button>
          </MenuTrigger>
          
          <MenuContent>
            {/* Server List */}
            {servers.map((server) => (
              <MenuItem 
                key={server.id}
                value={server.id}
                onClick={() => selectServer(server.id)}
                bg={currentServer?.id === server.id ? 'blue.subtle' : 'transparent'}
              >
                <HStack justify="space-between" w="full">
                  <VStack align="start" gap="1">
                    <HStack gap="2">
                      <Box color={server.isConnected ? 'green.solid' : 'red.solid'}>
                        {server.isConnected ? <LuWifi size="14" /> : <LuWifiOff size="14" />}
                      </Box>
                      <Text fontSize="sm" fontWeight="medium">
                        {server.name}
                      </Text>
                      {currentServer?.id === server.id && (
                        <Badge size="sm" colorScheme="blue">Current</Badge>
                      )}
                    </HStack>
                    <Text fontSize="xs" color="fg.muted">
                      {server.endpoint}
                    </Text>
                    <Text fontSize="xs" color="fg.muted">
                      Last seen: {formatLastSeen(server.lastSeen)}
                    </Text>
                  </VStack>
                  
                  <VStack gap="1">
                    {server.isConnected ? (
                      <IconButton
                        aria-label="Disconnect"
                        size="xs"
                        variant="ghost"
                        colorScheme="red"
                        onClick={(e) => {
                          e.stopPropagation();
                          handleDisconnectFromServer(server.id);
                        }}
                      >
                        <LuLogOut size="14" />
                      </IconButton>
                    ) : (
                      <IconButton
                        aria-label="Connect"
                        size="xs"
                        variant="ghost"
                        colorScheme="green"
                        onClick={(e) => {
                          e.stopPropagation();
                          handleConnectToServer(server.id);
                        }}
                      >
                        <LuLogIn size="14" />
                      </IconButton>
                    )}
                    
                    <IconButton
                      aria-label="Remove server"
                      size="xs"
                      variant="ghost"
                      colorScheme="red"
                      onClick={(e) => {
                        e.stopPropagation();
                        removeServer(server.id);
                      }}
                    >
                      <LuTrash2 size="14" />
                    </IconButton>
                  </VStack>
                </HStack>
              </MenuItem>
            ))}
            
            <MenuSeparator />
            
            {/* Add Server */}
            <MenuItem value="add-server" onClick={addModal.onOpen}>
              <HStack>
                <LuPlus size="16" />
                <Text>Add Server</Text>
              </HStack>
            </MenuItem>
          </MenuContent>
        </MenuRoot>
      </HStack>

      {/* Modals */}
      <AddServerModal isOpen={addModal.open} onClose={addModal.onClose} />
      <ConnectServerModal 
        isOpen={connectModal.open} 
        onClose={() => {
          connectModal.onClose();
          setConnectingServerId('');
        }}
        serverId={connectingServerId}
      />
    </>
  );
};

export default ServerSelector;
