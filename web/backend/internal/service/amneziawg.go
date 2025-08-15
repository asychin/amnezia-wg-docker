package service

import (
	"bufio"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"strconv"
	"strings"
	"time"

	"amneziawg-web-api/internal/config"
	"amneziawg-web-api/internal/models"

	"github.com/sirupsen/logrus"
)

type AmneziaWGService struct {
	config *config.AmneziaWGConfig
	logger *logrus.Logger
}

func NewAmneziaWGService(cfg config.AmneziaWGConfig) *AmneziaWGService {
	return &AmneziaWGService{
		config: &cfg,
		logger: logrus.New(),
	}
}

// Server Status
func (s *AmneziaWGService) GetServerStatus() (*models.ServerStatus, error) {
	status := &models.ServerStatus{
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

	// Проверяем статус сервера через docker compose
	cmd := exec.Command("docker", "compose", "ps", "--format", "json")
	cmd.Dir = "/home/blacksazha/amnezia-wg-docker"
	
	output, err := cmd.Output()
	if err != nil {
		s.logger.WithError(err).Error("Failed to check server status")
		return status, nil // Возвращаем статус "stopped" вместо ошибки
	}

	// Парсим вывод docker compose ps
	var containers []map[string]interface{}
	if err := json.Unmarshal(output, &containers); err == nil {
		for _, container := range containers {
			if name, ok := container["Name"].(string); ok && strings.Contains(name, "amneziawg-server") {
				if state, ok := container["State"].(string); ok && state == "running" {
					status.Running = true
					
					// Получаем uptime
					if createdAt, ok := container["CreatedAt"].(string); ok {
						if t, err := time.Parse(time.RFC3339, createdAt); err == nil {
							status.Uptime = int64(time.Since(t).Seconds())
						}
					}
					break
				}
			}
		}
	}

	if status.Running {
		// Получаем информацию о клиентах
		clients, _ := s.GetClients()
		status.Clients.Total = len(clients)
		
		// Подсчитываем подключенных клиентов и трафик
		for _, client := range clients {
			if client.Connected {
				status.Clients.Connected++
			}
			status.Traffic.Sent += client.Traffic.Sent
			status.Traffic.Received += client.Traffic.Received
		}

		// Получаем конфигурацию сервера
		if config, err := s.GetServerConfig(); err == nil {
			status.Port = config.Port
			status.Interface = config.Interface
			status.PublicIP = config.PublicIP
		}
	}

	return status, nil
}

// Server Control
func (s *AmneziaWGService) StartServer() error {
	cmd := exec.Command("make", "up")
	cmd.Dir = "/home/blacksazha/amnezia-wg-docker"
	
	if err := cmd.Run(); err != nil {
		s.logger.WithError(err).Error("Failed to start server")
		return fmt.Errorf("failed to start server: %w", err)
	}
	
	s.logger.Info("Server started successfully")
	return nil
}

func (s *AmneziaWGService) StopServer() error {
	cmd := exec.Command("make", "down")
	cmd.Dir = "/home/blacksazha/amnezia-wg-docker"
	
	if err := cmd.Run(); err != nil {
		s.logger.WithError(err).Error("Failed to stop server")
		return fmt.Errorf("failed to stop server: %w", err)
	}
	
	s.logger.Info("Server stopped successfully")
	return nil
}

func (s *AmneziaWGService) RestartServer() error {
	cmd := exec.Command("make", "restart")
	cmd.Dir = "/home/blacksazha/amnezia-wg-docker"
	
	if err := cmd.Run(); err != nil {
		s.logger.WithError(err).Error("Failed to restart server")
		return fmt.Errorf("failed to restart server: %w", err)
	}
	
	s.logger.Info("Server restarted successfully")
	return nil
}

// Client Management
func (s *AmneziaWGService) GetClients() ([]models.Client, error) {
	var clients []models.Client

	// Получаем список клиентов через make client-list
	cmd := exec.Command("make", "client-list")
	cmd.Dir = "/home/blacksazha/amnezia-wg-docker"
	
	output, err := cmd.Output()
	if err != nil {
		s.logger.WithError(err).Error("Failed to get clients list")
		return clients, fmt.Errorf("failed to get clients list: %w", err)
	}

	// Парсим вывод команды
	lines := strings.Split(string(output), "\n")
	for _, line := range lines {
		line = strings.TrimSpace(line)
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}

		// Простой парсинг - предполагаем формат: "name ip status"
		fields := strings.Fields(line)
		if len(fields) >= 3 {
			client := models.Client{
				Name:      fields[0],
				IP:        fields[1],
				Connected: fields[2] == "connected",
				CreatedAt: time.Now(), // Заглушка
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

func (s *AmneziaWGService) CreateClient(req models.CreateClientRequest) (*models.Client, error) {
	var cmd *exec.Cmd
	
	if req.IP != "" {
		cmd = exec.Command("make", "client-add", fmt.Sprintf("name=%s", req.Name), fmt.Sprintf("ip=%s", req.IP))
	} else {
		cmd = exec.Command("make", "client-add", fmt.Sprintf("name=%s", req.Name))
	}
	
	cmd.Dir = "/home/blacksazha/amnezia-wg-docker"
	
	if err := cmd.Run(); err != nil {
		s.logger.WithError(err).WithField("client", req.Name).Error("Failed to create client")
		return nil, fmt.Errorf("failed to create client: %w", err)
	}

	s.logger.WithField("client", req.Name).Info("Client created successfully")

	// Возвращаем информацию о созданном клиенте
	client := &models.Client{
		Name:      req.Name,
		IP:        req.IP,
		Connected: false,
		CreatedAt: time.Now(),
		Traffic: models.TrafficStats{
			Sent:     0,
			Received: 0,
		},
	}

	return client, nil
}

func (s *AmneziaWGService) DeleteClient(name string) error {
	cmd := exec.Command("make", "client-rm", fmt.Sprintf("name=%s", name))
	cmd.Dir = "/home/blacksazha/amnezia-wg-docker"
	
	if err := cmd.Run(); err != nil {
		s.logger.WithError(err).WithField("client", name).Error("Failed to delete client")
		return fmt.Errorf("failed to delete client: %w", err)
	}

	s.logger.WithField("client", name).Info("Client deleted successfully")
	return nil
}

func (s *AmneziaWGService) GetClientConfig(name string) (*models.ClientConfig, error) {
	cmd := exec.Command("make", "client-config", fmt.Sprintf("name=%s", name))
	cmd.Dir = "/home/blacksazha/amnezia-wg-docker"
	
	output, err := cmd.Output()
	if err != nil {
		s.logger.WithError(err).WithField("client", name).Error("Failed to get client config")
		return nil, fmt.Errorf("failed to get client config: %w", err)
	}

	return &models.ClientConfig{
		Name:   name,
		Config: string(output),
	}, nil
}

func (s *AmneziaWGService) GetClientQRCode(name string) (string, error) {
	cmd := exec.Command("make", "client-qr", fmt.Sprintf("name=%s", name))
	cmd.Dir = "/home/blacksazha/amnezia-wg-docker"
	
	output, err := cmd.Output()
	if err != nil {
		s.logger.WithError(err).WithField("client", name).Error("Failed to get client QR code")
		return "", fmt.Errorf("failed to get client QR code: %w", err)
	}

	return string(output), nil
}

// Server Configuration
func (s *AmneziaWGService) GetServerConfig() (*models.ServerConfig, error) {
	config := &models.ServerConfig{
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

	// Читаем конфигурацию из .env файла
	envPath := "/home/blacksazha/amnezia-wg-docker/.env"
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

func (s *AmneziaWGService) UpdateServerConfig(config models.ServerConfig) error {
	envPath := "/home/blacksazha/amnezia-wg-docker/.env"
	
	// Читаем существующий .env файл
	var lines []string
	if file, err := os.Open(envPath); err == nil {
		defer file.Close()
		scanner := bufio.NewScanner(file)
		for scanner.Scan() {
			lines = append(lines, scanner.Text())
		}
	}

	// Обновляем значения
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

	// Записываем обновленный файл
	content := strings.Join(lines, "\n")
	if err := os.WriteFile(envPath, []byte(content), 0644); err != nil {
		s.logger.WithError(err).Error("Failed to update server config")
		return fmt.Errorf("failed to update server config: %w", err)
	}

	s.logger.Info("Server config updated successfully")
	return nil
}
