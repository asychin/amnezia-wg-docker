package vpn

import (
	"bufio"
	"context"
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"

	"amneziawg-web-api/internal/models"

	"github.com/sirupsen/logrus"
)

type VPNService struct {
	docker      *DockerConnector
	projectPath string
	logger      *logrus.Logger
}

func NewVPNService(containerName, projectPath string, logger *logrus.Logger) (*VPNService, error) {
	docker, err := NewDockerConnector(containerName, projectPath, logger)
	if err != nil {
		return nil, err
	}

	return &VPNService{
		docker:      docker,
		projectPath: projectPath,
		logger:      logger,
	}, nil
}

// GetServerStatus gets current VPN server status
func (v *VPNService) GetServerStatus(ctx context.Context) (*models.VPNServerStatus, error) {
	status := &models.VPNServerStatus{
		Running:   false,
		Version:   "1.0.0",
		Interface: "awg0",
		Port:      51820,
		PublicIP:  "",
		Clients: models.ClientsStatus{
			Total:     0,
			Connected: 0,
		},
		Traffic: models.TrafficStats{
			Sent:     0,
			Received: 0,
		},
	}

	// Check if container is running
	running, err := v.docker.IsContainerRunning(ctx)
	if err != nil {
		v.logger.WithError(err).Error("Failed to check container status")
		return status, nil
	}

	status.Running = running

	if !running {
		return status, nil
	}

	// Get container info for uptime
	containerInfo, err := v.docker.GetContainerInfo(ctx)
	if err == nil {
		status.Uptime = int64(time.Since(containerInfo.Created).Seconds())
	}

	// Get AWG interface info
	awgResult, err := v.docker.GetAWGShow(ctx, "awg0")
	if err == nil && awgResult.ExitCode == 0 {
		v.parseAWGOutput(awgResult.StdOut, status)
	}

	// Get clients list
	clients, err := v.GetClients(ctx)
	if err == nil {
		status.Clients.Total = len(clients)
		for _, client := range clients {
			if client.Connected {
				status.Clients.Connected++
			}
			status.Traffic.Sent += client.Traffic.Sent
			status.Traffic.Received += client.Traffic.Received
		}
	}

	// Get server config for port and public IP
	config, err := v.GetServerConfig(ctx)
	if err == nil {
		status.Port = config.Port
		status.Interface = config.Interface
		status.PublicIP = config.PublicIP
	}

	return status, nil
}

// GetServerConfig gets VPN server configuration
func (v *VPNService) GetServerConfig(ctx context.Context) (*models.VPNServerConfig, error) {
	config := &models.VPNServerConfig{
		Interface: "awg0",
		Port:      51820,
		Network:   "10.13.13.0/24",
		ServerIP:  "10.13.13.1",
		DNS:       []string{"8.8.8.8", "8.8.4.4"},
		PublicIP:  "auto",
		Obfuscation: models.ObfuscationConfig{
			Jc:   7,
			Jmin: 50,
			Jmax: 1000,
			S1:   86,
			S2:   574,
			H1:   1,
			H2:   2,
			H3:   3,
			H4:   4,
		},
	}

	// Read configuration from .env file
	envPath := fmt.Sprintf("%s/.env", v.projectPath)
	if file, err := os.Open(envPath); err == nil {
		defer file.Close()
		scanner := bufio.NewScanner(file)
		
		for scanner.Scan() {
			line := strings.TrimSpace(scanner.Text())
			if line == "" || strings.HasPrefix(line, "#") {
				continue
			}

			parts := strings.SplitN(line, "=", 2)
			if len(parts) != 2 {
				continue
			}

			key := strings.TrimSpace(parts[0])
			value := strings.TrimSpace(parts[1])

			switch key {
			case "AWG_INTERFACE":
				config.Interface = value
			case "AWG_PORT":
				if port, err := strconv.Atoi(value); err == nil {
					config.Port = port
				}
			case "AWG_NET":
				config.Network = value
			case "AWG_SERVER_IP":
				config.ServerIP = value
			case "AWG_DNS":
				config.DNS = strings.Split(value, ",")
				for i := range config.DNS {
					config.DNS[i] = strings.TrimSpace(config.DNS[i])
				}
			case "SERVER_PUBLIC_IP":
				config.PublicIP = value
			case "AWG_JC":
				if val, err := strconv.Atoi(value); err == nil {
					config.Obfuscation.Jc = val
				}
			case "AWG_JMIN":
				if val, err := strconv.Atoi(value); err == nil {
					config.Obfuscation.Jmin = val
				}
			case "AWG_JMAX":
				if val, err := strconv.Atoi(value); err == nil {
					config.Obfuscation.Jmax = val
				}
			case "AWG_S1":
				if val, err := strconv.Atoi(value); err == nil {
					config.Obfuscation.S1 = val
				}
			case "AWG_S2":
				if val, err := strconv.Atoi(value); err == nil {
					config.Obfuscation.S2 = val
				}
			case "AWG_H1":
				if val, err := strconv.Atoi(value); err == nil {
					config.Obfuscation.H1 = val
				}
			case "AWG_H2":
				if val, err := strconv.Atoi(value); err == nil {
					config.Obfuscation.H2 = val
				}
			case "AWG_H3":
				if val, err := strconv.Atoi(value); err == nil {
					config.Obfuscation.H3 = val
				}
			case "AWG_H4":
				if val, err := strconv.Atoi(value); err == nil {
					config.Obfuscation.H4 = val
				}
			}
		}
	}

	return config, nil
}

// UpdateServerConfig updates VPN server configuration
func (v *VPNService) UpdateServerConfig(ctx context.Context, config *models.VPNServerConfig) error {
	envPath := fmt.Sprintf("%s/.env", v.projectPath)
	
	// Read existing .env file
	var lines []string
	if file, err := os.Open(envPath); err == nil {
		defer file.Close()
		scanner := bufio.NewScanner(file)
		for scanner.Scan() {
			lines = append(lines, scanner.Text())
		}
	}

	// Update values
	updateEnvValue := func(key, value string) {
		found := false
		for i, line := range lines {
			if strings.HasPrefix(strings.TrimSpace(line), key+"=") {
				lines[i] = fmt.Sprintf("%s=%s", key, value)
				found = true
				break
			}
		}
		if !found {
			lines = append(lines, fmt.Sprintf("%s=%s", key, value))
		}
	}

	updateEnvValue("AWG_INTERFACE", config.Interface)
	updateEnvValue("AWG_PORT", strconv.Itoa(config.Port))
	updateEnvValue("AWG_NET", config.Network)
	updateEnvValue("AWG_SERVER_IP", config.ServerIP)
	updateEnvValue("AWG_DNS", strings.Join(config.DNS, ","))
	updateEnvValue("SERVER_PUBLIC_IP", config.PublicIP)
	updateEnvValue("AWG_JC", strconv.Itoa(config.Obfuscation.Jc))
	updateEnvValue("AWG_JMIN", strconv.Itoa(config.Obfuscation.Jmin))
	updateEnvValue("AWG_JMAX", strconv.Itoa(config.Obfuscation.Jmax))
	updateEnvValue("AWG_S1", strconv.Itoa(config.Obfuscation.S1))
	updateEnvValue("AWG_S2", strconv.Itoa(config.Obfuscation.S2))
	updateEnvValue("AWG_H1", strconv.Itoa(config.Obfuscation.H1))
	updateEnvValue("AWG_H2", strconv.Itoa(config.Obfuscation.H2))
	updateEnvValue("AWG_H3", strconv.Itoa(config.Obfuscation.H3))
	updateEnvValue("AWG_H4", strconv.Itoa(config.Obfuscation.H4))

	// Write updated file
	content := strings.Join(lines, "\n")
	if err := os.WriteFile(envPath, []byte(content), 0644); err != nil {
		return fmt.Errorf("failed to update server config: %w", err)
	}

	v.logger.Info("Server config updated successfully")
	return nil
}

// GetClients gets list of VPN clients
func (v *VPNService) GetClients(ctx context.Context) ([]models.VPNClient, error) {
	var clients []models.VPNClient

	// Get clients list using manage-clients.sh script
	result, err := v.docker.ManageClientScript(ctx, "list")
	if err != nil {
		return clients, fmt.Errorf("failed to get clients list: %w", err)
	}

	if result.ExitCode != 0 {
		return clients, fmt.Errorf("client list command failed: %s", result.StdErr)
	}

	// Parse output
	lines := strings.Split(result.StdOut, "\n")
	for _, line := range lines {
		line = strings.TrimSpace(line)
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}

		// Parse client info - adjust format based on actual script output
		fields := strings.Fields(line)
		if len(fields) >= 3 {
			client := models.VPNClient{
				Name:      fields[0],
				IP:        fields[1],
				Connected: fields[2] == "connected",
				CreatedAt: time.Now(), // Could be parsed from script output
				Traffic: models.TrafficStats{
					Sent:     0,
					Received: 0,
				},
			}
			clients = append(clients, client)
		}
	}

	return clients, nil
}

// CreateClient creates a new VPN client
func (v *VPNService) CreateClient(ctx context.Context, req *models.CreateVPNClientRequest) (*models.VPNClient, error) {
	var args []string
	args = append(args, req.Name)
	
	if req.IP != "" {
		args = append(args, req.IP)
	}

	result, err := v.docker.ManageClientScript(ctx, "add", args...)
	if err != nil {
		return nil, fmt.Errorf("failed to create client: %w", err)
	}

	if result.ExitCode != 0 {
		return nil, fmt.Errorf("client creation failed: %s", result.StdErr)
	}

	v.logger.WithField("client", req.Name).Info("Client created successfully")

	return &models.VPNClient{
		Name:      req.Name,
		IP:        req.IP,
		Connected: false,
		CreatedAt: time.Now(),
		Traffic: models.TrafficStats{
			Sent:     0,
			Received: 0,
		},
	}, nil
}

// DeleteClient deletes a VPN client
func (v *VPNService) DeleteClient(ctx context.Context, name string) error {
	result, err := v.docker.ManageClientScript(ctx, "remove", name)
	if err != nil {
		return fmt.Errorf("failed to delete client: %w", err)
	}

	if result.ExitCode != 0 {
		return fmt.Errorf("client deletion failed: %s", result.StdErr)
	}

	v.logger.WithField("client", name).Info("Client deleted successfully")
	return nil
}

// GetClientConfig gets configuration for a specific client
func (v *VPNService) GetClientConfig(ctx context.Context, name string) (*models.VPNClientConfig, error) {
	result, err := v.docker.ManageClientScript(ctx, "show", name)
	if err != nil {
		return nil, fmt.Errorf("failed to get client config: %w", err)
	}

	if result.ExitCode != 0 {
		return nil, fmt.Errorf("get client config failed: %s", result.StdErr)
	}

	return &models.VPNClientConfig{
		Name:   name,
		Config: result.StdOut,
	}, nil
}

// GetClientQRCode gets QR code for a specific client
func (v *VPNService) GetClientQRCode(ctx context.Context, name string) (string, error) {
	result, err := v.docker.ManageClientScript(ctx, "qr", name)
	if err != nil {
		return "", fmt.Errorf("failed to get client QR code: %w", err)
	}

	if result.ExitCode != 0 {
		return "", fmt.Errorf("get client QR code failed: %s", result.StdErr)
	}

	return result.StdOut, nil
}

// GetLogs gets VPN server logs
func (v *VPNService) GetLogs(ctx context.Context, tail string) (string, error) {
	return v.docker.GetContainerLogs(ctx, tail)
}

// Close closes the VPN service
func (v *VPNService) Close() error {
	return v.docker.Close()
}

// parseAWGOutput parses output from 'awg show' command
func (v *VPNService) parseAWGOutput(output string, status *models.VPNServerStatus) {
	lines := strings.Split(output, "\n")
	for _, line := range lines {
		line = strings.TrimSpace(line)
		if strings.Contains(line, "listening port:") {
			parts := strings.Split(line, ":")
			if len(parts) >= 2 {
				if port, err := strconv.Atoi(strings.TrimSpace(parts[1])); err == nil {
					status.Port = port
				}
			}
		}
		// Add more parsing logic as needed
	}
}
