import React from 'react';
import { Flex, Text, HStack, Badge, Box } from '@chakra-ui/react';
import { ColorModeButton } from '@/components/ui/color-mode';
import { useServerStatus } from '@/hooks/useServerStatus';
import { LuWifi, LuWifiOff } from 'react-icons/lu';

const Header: React.FC = () => {
  const { data: serverStatus, isLoading } = useServerStatus();

  return (
    <Flex
      h="full"
      align="center"
      justify="space-between"
      px="6"
    >
      {/* Status indicator */}
      <HStack gap="4">
        <HStack gap="2">
          <Box color={serverStatus?.running ? 'green.solid' : 'red.solid'}>
            {serverStatus?.running ? <LuWifi size="18" /> : <LuWifiOff size="18" />}
          </Box>
          <Text fontSize="sm" fontWeight="medium">
            Server Status:
          </Text>
          <Badge
            colorScheme={serverStatus?.running ? 'green' : 'red'}
            variant="subtle"
          >
            {isLoading ? 'Loading...' : serverStatus?.running ? 'Running' : 'Stopped'}
          </Badge>
        </HStack>

        {serverStatus?.running && (
          <HStack gap="4" color="fg.muted" fontSize="sm">
            <Text>
              Clients: {serverStatus.clients.connected}/{serverStatus.clients.total}
            </Text>
            <Text>
              Port: {serverStatus.port}
            </Text>
          </HStack>
        )}
      </HStack>

      {/* Controls */}
      <HStack gap="2">
        <ColorModeButton />
      </HStack>
    </Flex>
  );
};

export default Header;
