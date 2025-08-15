import React, { ReactNode } from 'react';
import { Box, Flex } from '@chakra-ui/react';
import Sidebar from './Sidebar';
import Header from './Header';

interface LayoutProps {
  children: ReactNode;
}

const Layout: React.FC<LayoutProps> = ({ children }) => {
  return (
    <Flex minH="100vh" direction="row">
      {/* Sidebar */}
      <Box
        w="240px"
        bg="bg.subtle"
        borderRightWidth="1px"
        borderColor="border.muted"
        display={{ base: 'none', md: 'block' }}
        position="fixed"
        h="100vh"
        overflowY="auto"
      >
        <Sidebar />
      </Box>

      {/* Main content */}
      <Flex flex="1" direction="column" ml={{ base: 0, md: '240px' }}>
        {/* Header */}
        <Box
          h="60px"
          bg="bg"
          borderBottomWidth="1px"
          borderColor="border.muted"
          position="sticky"
          top="0"
          zIndex="sticky"
        >
          <Header />
        </Box>

        {/* Page content */}
        <Box flex="1" p="6" bg="bg.subtle">
          {children}
        </Box>
      </Flex>
    </Flex>
  );
};

export default Layout;
