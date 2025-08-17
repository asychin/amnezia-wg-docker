import React from 'react';
import { Box, VStack, HStack, Text, Badge, Separator } from '@chakra-ui/react';
import { Link as RouterLink, useLocation } from 'react-router-dom';
import { 
  LuActivity, 
  LuUsers, 
  LuSettings, 
  LuFileText,
  LuShield,
  LuWifi,
  LuWifiOff
} from 'react-icons/lu';
import { useServers } from '@/contexts/ServerContext';

interface NavItemProps {
  icon: React.ElementType;
  label: string;
  href: string;
  isActive?: boolean;
}

const NavItem: React.FC<NavItemProps> = ({ icon: Icon, label, href, isActive }) => {
  return (
    <RouterLink to={href} style={{ width: '100%', textDecoration: 'none' }}>
      <HStack
        w="full"
        px="4"
        py="3"
        borderRadius="md"
        bg={isActive ? 'blue.subtle' : 'transparent'}
        color={isActive ? 'blue.fg' : 'fg.muted'}
        _hover={{
          bg: isActive ? 'blue.subtle' : 'bg.emphasized',
          color: isActive ? 'blue.fg' : 'fg',
        }}
        transition="all 0.2s"
      >
        <Icon size="18" />
        <Text fontSize="sm" fontWeight="medium">
          {label}
        </Text>
      </HStack>
    </RouterLink>
  );
};

const Sidebar: React.FC = () => {
  const location = useLocation();
  const { currentServer, servers } = useServers();

  const navItems = [
    {
      icon: LuActivity,
      label: 'Dashboard',
      href: '/',
    },
    {
      icon: LuUsers,
      label: 'Clients',
      href: '/clients',
    },
    {
      icon: LuSettings,
      label: 'Settings',
      href: '/settings',
    },
    {
      icon: LuFileText,
      label: 'Logs',
      href: '/logs',
    },
  ];

  return (
    <Box h="full" p="4">
      {/* Logo */}
      <HStack mb="6" px="2">
        <LuShield size="24" color="var(--chakra-colors-blue-solid)" />
        <VStack align="start" gap="0">
          <Text fontSize="lg" fontWeight="bold" color="fg">
            AmneziaWG
          </Text>
          <Text fontSize="xs" color="fg.muted">
            Web Interface
          </Text>
        </VStack>
      </HStack>

      {/* Current Server Info */}
      {servers.length > 0 && (
        <>
          <Box px="2" mb="4">
            <Text fontSize="xs" color="fg.muted" mb="2" fontWeight="medium">
              CURRENT SERVER
            </Text>
            {currentServer ? (
              <VStack align="start" gap="1">
                <HStack gap="2" w="full">
                  <Box color={currentServer.isConnected ? 'green.solid' : 'red.solid'}>
                    {currentServer.isConnected ? <LuWifi size="14" /> : <LuWifiOff size="14" />}
                  </Box>
                  <Text fontSize="sm" fontWeight="medium" truncate flex="1">
                    {currentServer.name}
                  </Text>
                </HStack>
                <Badge 
                  size="sm" 
                  colorScheme={currentServer.isConnected ? 'green' : 'orange'}
                  variant="subtle"
                >
                  {currentServer.isConnected ? 'Connected' : 'Disconnected'}
                </Badge>
                <Text fontSize="xs" color="fg.muted" truncate w="full">
                  {currentServer.endpoint}
                </Text>
              </VStack>
            ) : (
              <Text fontSize="sm" color="fg.muted">
                No server selected
              </Text>
            )}
          </Box>
          <Separator mb="4" />
        </>
      )}

      {/* Navigation */}
      <VStack gap="1" align="stretch">
        {navItems.map((item) => (
          <NavItem
            key={item.href}
            icon={item.icon}
            label={item.label}
            href={item.href}
            isActive={location.pathname === item.href}
          />
        ))}
      </VStack>

      {/* Server Count at Bottom */}
      {servers.length > 1 && (
        <Box px="2" mt="auto" pt="4">
          <Text fontSize="xs" color="fg.muted">
            Managing {servers.length} servers
          </Text>
        </Box>
      )}
    </Box>
  );
};

export default Sidebar;
