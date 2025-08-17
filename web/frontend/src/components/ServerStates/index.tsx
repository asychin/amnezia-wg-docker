import React from 'react';
import {
  Box,
  Button,
  Center,
  VStack,
  HStack,
  Text,
  Heading,
  useDisclosure,
} from '@chakra-ui/react';
import { 
  LuWifiOff, 
  LuPlus, 
  LuServer, 
  LuAlertCircle,
  LuWifi 
} from 'react-icons/lu';
import { useServers } from '@/contexts/ServerContext';
import AddServerModal from '@/components/AddServerModal';
import ConnectServerModal from '@/components/ConnectServerModal';

/**
 * Компонент для отображения состояния "Нет добавленных серверов"
 */
export const NoServersState: React.FC = () => {
  const addModal = useDisclosure();

  return (
    <>
      <Center minH="60vh">
        <VStack gap="6" textAlign="center" maxW="md">
          <VStack gap="4">
            <Box color="fg.muted">
              <LuWifiOff size="64" />
            </Box>
            <VStack gap="2">
              <Heading size="lg" color="fg.emphasized">
                No Servers Connected
              </Heading>
              <Text color="fg.muted" textAlign="center">
                Get started by adding your first AmneziaWG server using a connection string.
                You can manage multiple servers from this interface.
              </Text>
            </VStack>
          </VStack>
          <Button
            size="lg"
            colorScheme="blue"
            onClick={addModal.onOpen}
          >
            <LuPlus size="20" />
            Add Your First Server
          </Button>
        </VStack>
      </Center>
      <AddServerModal isOpen={addModal.open} onClose={addModal.onClose} />
    </>
  );
};

/**
 * Компонент для отображения состояния "Сервер выбран, но не подключен"
 */
export const DisconnectedServerState: React.FC = () => {
  const { currentServer } = useServers();
  const connectModal = useDisclosure();
  
  return (
    <>
      <Center minH="60vh">
        <VStack gap="6" textAlign="center" maxW="md">
          <VStack gap="4">
            <Box color="orange.solid">
              <LuServer size="64" />
            </Box>
            <VStack gap="2">
              <Heading size="lg" color="fg.emphasized">
                Server Disconnected
              </Heading>
              <Text color="fg.muted" textAlign="center">
                You have selected "{currentServer?.name}" but are not currently connected.
                Please authenticate to access server management features.
              </Text>
            </VStack>
          </VStack>
          <HStack gap="3">
            <Button 
              colorScheme="blue" 
              size="lg"
              onClick={connectModal.onOpen}
            >
              <LuWifi size="20" />
              Connect to Server
            </Button>
            <Text fontSize="sm" color="fg.muted">
              or select a different server from the header
            </Text>
          </HStack>
        </VStack>
      </Center>
      {currentServer && (
        <ConnectServerModal 
          isOpen={connectModal.open} 
          onClose={connectModal.onClose}
          serverId={currentServer.id}
        />
      )}
    </>
  );
};

/**
 * Компонент для отображения состояния ошибки подключения
 */
export const ErrorState: React.FC<{ 
  title?: string; 
  message?: string;
  onRetry?: () => void;
}> = ({ 
  title = "Connection Error", 
  message = "Failed to connect to the server. Please check your connection and try again.",
  onRetry 
}) => {
  return (
    <Center minH="60vh">
      <VStack gap="6" textAlign="center" maxW="md">
        <VStack gap="4">
          <Box color="red.solid">
            <LuAlertCircle size="64" />
          </Box>
          <VStack gap="2">
            <Heading size="lg" color="fg.emphasized">
              {title}
            </Heading>
            <Text color="fg.muted" textAlign="center">
              {message}
            </Text>
          </VStack>
        </VStack>
        {onRetry && (
          <Button colorScheme="blue" onClick={onRetry}>
            Retry Connection
          </Button>
        )}
      </VStack>
    </Center>
  );
};

/**
 * High-Order Component для защиты страниц
 * Проверяет состояние подключения и отображает соответствующие состояния
 */
export const withServerConnection = <P extends object>(
  Component: React.ComponentType<P>
) => {
  return (props: P) => {
    const { servers, currentServer } = useServers();

    // Нет добавленных серверов
    if (servers.length === 0) {
      return <NoServersState />;
    }

    // Сервер выбран, но не подключен
    if (currentServer && !currentServer.isConnected) {
      return <DisconnectedServerState />;
    }

    // Нет выбранного сервера (не должно происходить, но на всякий случай)
    if (!currentServer) {
      return <NoServersState />;
    }

    // Все хорошо, показываем компонент
    return <Component {...props} />;
  };
};
