import React from 'react';
import {
  Box,
  Card,
  Flex,
  Grid,
  Heading,
  HStack,
  Text,
  Badge,
  Button,
  SimpleGrid,
} from '@chakra-ui/react';
import { Chart, useChart } from '@chakra-ui/charts';
import { Line, LineChart, CartesianGrid, XAxis, YAxis, Tooltip, Area, AreaChart } from 'recharts';
import { useServerStatus, useServerControl } from '@/hooks/useServerStatus';
import { useClients } from '@/hooks/useClients';
import { useServers } from '@/contexts/ServerContext';
import { NoServersState, DisconnectedServerState } from '@/components/ServerStates';
import { LuPlay, LuSquare, LuRotateCcw, LuUsers, LuActivity, LuHardDrive } from 'react-icons/lu';
import { formatDistanceToNow } from 'date-fns';
import { ru } from 'date-fns/locale';

const Dashboard: React.FC = () => {
  const { servers } = useServers();
  const { data: serverStatus, isLoading: statusLoading } = useServerStatus();
  const { isLoading: clientsLoading } = useClients();
  const { startServer, stopServer, restartServer, isConnected } = useServerControl();

  // Show no servers state if no servers are added
  if (servers.length === 0) {
    return <NoServersState />;
  }

  // Show disconnected state if server is selected but not connected
  if (!isConnected) {
    return <DisconnectedServerState />;
  }

  // Моковые данные для графиков (позже заменим на реальные данные)
  const connectionData = [
    { time: '00:00', clients: 5, traffic: 120 },
    { time: '04:00', clients: 3, traffic: 80 },
    { time: '08:00', clients: 12, traffic: 300 },
    { time: '12:00', clients: 18, traffic: 450 },
    { time: '16:00', clients: 22, traffic: 520 },
    { time: '20:00', clients: 15, traffic: 350 },
  ];

  const trafficData = [
    { time: '00:00', sent: 45, received: 75 },
    { time: '04:00', sent: 25, received: 55 },
    { time: '08:00', sent: 125, received: 175 },
    { time: '12:00', sent: 200, received: 250 },
    { time: '16:00', sent: 250, received: 270 },
    { time: '20:00', sent: 150, received: 200 },
  ];

  const connectionChart = useChart({
    data: connectionData,
    series: [{ name: 'clients', color: 'blue.solid' }],
  });

  const trafficChart = useChart({
    data: trafficData,
    series: [
      { name: 'sent', color: 'green.solid' },
      { name: 'received', color: 'purple.solid' },
    ],
  });

  const formatBytes = (bytes: number) => {
    if (bytes === 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  };

  return (
    <Box>
      {/* Header */}
      <Flex justify="space-between" align="center" mb="6">
        <Box>
          <Heading size="lg" mb="1">
            Dashboard
          </Heading>
          <Text color="fg.muted">
            AmneziaWG Server Management Overview
          </Text>
        </Box>
        
        {/* Server Controls */}
        <HStack gap="2">
          <Button
            size="sm"
            variant="outline"
            colorPalette="green"
            onClick={() => startServer.mutate()}
            loading={startServer.isLoading}
            disabled={serverStatus?.running}
          >
            <LuPlay />
            Start
          </Button>
          <Button
            size="sm"
            variant="outline"
            colorPalette="red"
            onClick={() => stopServer.mutate()}
            loading={stopServer.isLoading}
            disabled={!serverStatus?.running}
          >
            <LuSquare />
            Stop
          </Button>
          <Button
            size="sm"
            variant="outline"
            colorPalette="orange"
            onClick={() => restartServer.mutate()}
            loading={restartServer.isLoading}
            disabled={!serverStatus?.running}
          >
            <LuRotateCcw />
            Restart
          </Button>
        </HStack>
      </Flex>

      {/* Status Cards */}
      <SimpleGrid columns={{ base: 1, md: 2, lg: 4 }} gap="6" mb="8">
        {/* Server Status Card */}
        <Card.Root>
          <Card.Body>
            <HStack justify="space-between">
              <Box>
                <Text fontSize="sm" color="fg.muted" mb="1">
                  Server Status
                </Text>
                <Badge
                  colorScheme={serverStatus?.running ? 'green' : 'red'}
                  variant="subtle"
                  size="lg"
                >
                  {statusLoading ? 'Loading...' : serverStatus?.running ? 'Running' : 'Stopped'}
                </Badge>
                {serverStatus?.running && serverStatus.uptime && (
                  <Text fontSize="xs" color="fg.muted" mt="1">
                    Uptime: {formatDistanceToNow(new Date(Date.now() - serverStatus.uptime * 1000), { locale: ru })}
                  </Text>
                )}
              </Box>
              <Box color={serverStatus?.running ? 'green.solid' : 'gray.muted'}>
                <LuActivity size="24" />
              </Box>
            </HStack>
          </Card.Body>
        </Card.Root>

        {/* Clients Card */}
        <Card.Root>
          <Card.Body>
            <HStack justify="space-between">
              <Box>
                <Text fontSize="sm" color="fg.muted" mb="1">
                  Connected Clients
                </Text>
                <Text fontSize="2xl" fontWeight="bold">
                  {clientsLoading ? '...' : `${serverStatus?.clients.connected || 0}/${serverStatus?.clients.total || 0}`}
                </Text>
                <Text fontSize="xs" color="fg.muted">
                  Total clients
                </Text>
              </Box>
              <Box color="blue.solid">
                <LuUsers size="24" />
              </Box>
            </HStack>
          </Card.Body>
        </Card.Root>

        {/* Traffic Sent Card */}
        <Card.Root>
          <Card.Body>
            <HStack justify="space-between">
              <Box>
                <Text fontSize="sm" color="fg.muted" mb="1">
                  Traffic Sent
                </Text>
                <Text fontSize="2xl" fontWeight="bold">
                  {serverStatus ? formatBytes(serverStatus.traffic.sent) : '0 B'}
                </Text>
                <Text fontSize="xs" color="fg.muted">
                  Total sent
                </Text>
              </Box>
              <Box color="green.solid">
                <LuHardDrive size="24" />
              </Box>
            </HStack>
          </Card.Body>
        </Card.Root>

        {/* Traffic Received Card */}
        <Card.Root>
          <Card.Body>
            <HStack justify="space-between">
              <Box>
                <Text fontSize="sm" color="fg.muted" mb="1">
                  Traffic Received
                </Text>
                <Text fontSize="2xl" fontWeight="bold">
                  {serverStatus ? formatBytes(serverStatus.traffic.received) : '0 B'}
                </Text>
                <Text fontSize="xs" color="fg.muted">
                  Total received
                </Text>
              </Box>
              <Box color="purple.solid">
                <LuHardDrive size="24" />
              </Box>
            </HStack>
          </Card.Body>
        </Card.Root>
      </SimpleGrid>

      {/* Charts */}
      <Grid templateColumns={{ base: '1fr', lg: '1fr 1fr' }} gap="6">
        {/* Connections Chart */}
        <Card.Root>
          <Card.Header>
            <Card.Title>Connected Clients (24h)</Card.Title>
            <Card.Description>
              Number of connected clients over time
            </Card.Description>
          </Card.Header>
          <Card.Body>
            <Chart.Root maxH="sm" chart={connectionChart}>
              <LineChart data={connectionChart.data}>
                <CartesianGrid stroke={connectionChart.color('border.muted')} vertical={false} />
                <XAxis
                  axisLine={false}
                  dataKey={connectionChart.key('time')}
                  stroke={connectionChart.color('border')}
                />
                <YAxis
                  axisLine={false}
                  tickLine={false}
                  tickMargin={10}
                  stroke={connectionChart.color('border')}
                />
                <Tooltip
                  animationDuration={100}
                  cursor={false}
                  content={<Chart.Tooltip />}
                />
                {connectionChart.series.map((item) => (
                  <Line
                    key={item.name}
                    isAnimationActive={false}
                    dataKey={connectionChart.key(item.name)}
                    stroke={connectionChart.color(item.color)}
                    strokeWidth={2}
                    dot={false}
                  />
                ))}
              </LineChart>
            </Chart.Root>
          </Card.Body>
        </Card.Root>

        {/* Traffic Chart */}
        <Card.Root>
          <Card.Header>
            <Card.Title>Traffic Overview (24h)</Card.Title>
            <Card.Description>
              Data sent and received over time
            </Card.Description>
          </Card.Header>
          <Card.Body>
            <Chart.Root maxH="sm" chart={trafficChart}>
              <AreaChart data={trafficChart.data}>
                <CartesianGrid stroke={trafficChart.color('border.muted')} vertical={false} />
                <XAxis
                  axisLine={false}
                  dataKey={trafficChart.key('time')}
                  stroke={trafficChart.color('border')}
                />
                <YAxis
                  axisLine={false}
                  tickLine={false}
                  tickMargin={10}
                  stroke={trafficChart.color('border')}
                  tickFormatter={(value) => `${value} MB`}
                />
                <Tooltip
                  animationDuration={100}
                  cursor={false}
                  content={<Chart.Tooltip />}
                />
                {trafficChart.series.map((item) => (
                  <Area
                    key={item.name}
                    isAnimationActive={false}
                    dataKey={trafficChart.key(item.name)}
                    fill={trafficChart.color(item.color)}
                    fillOpacity={0.2}
                    stroke={trafficChart.color(item.color)}
                    stackId="a"
                  />
                ))}
              </AreaChart>
            </Chart.Root>
          </Card.Body>
        </Card.Root>
      </Grid>
    </Box>
  );
};

export default Dashboard;
