import React from 'react';
import { Box, VStack, HStack, Text, Link as ChakraLink } from '@chakra-ui/react';
import { Link as RouterLink, useLocation } from 'react-router-dom';
import { 
  LuActivity, 
  LuUsers, 
  LuSettings, 
  LuFileText,
  LuShield
} from 'react-icons/lu';

interface NavItemProps {
  icon: React.ElementType;
  label: string;
  href: string;
  isActive?: boolean;
}

const NavItem: React.FC<NavItemProps> = ({ icon: Icon, label, href, isActive }) => {
  return (
    <ChakraLink
      as={RouterLink}
      to={href}
      w="full"
      _hover={{ textDecoration: 'none' }}
    >
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
    </ChakraLink>
  );
};

const Sidebar: React.FC = () => {
  const location = useLocation();

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
      <HStack mb="8" px="2">
        <LuShield size="24" color="var(--chakra-colors-blue-solid)" />
        <VStack align="start" spacing="0">
          <Text fontSize="lg" fontWeight="bold" color="fg">
            AmneziaWG
          </Text>
          <Text fontSize="xs" color="fg.muted">
            Web Interface
          </Text>
        </VStack>
      </HStack>

      {/* Navigation */}
      <VStack spacing="1" align="stretch">
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
    </Box>
  );
};

export default Sidebar;
