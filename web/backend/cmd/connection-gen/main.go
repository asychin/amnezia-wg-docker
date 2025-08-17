package main

import (
	"encoding/base64"
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"time"

	"amneziawg-web-api/internal/models"

	"github.com/google/uuid"
)

type Config struct {
	ServerName      string
	Location        string
	APIEndpoint     string
	TTL             time.Duration
	Capabilities    []string
	Protocol        string
}

func main() {
	var (
		serverName   = flag.String("server-name", "", "Server display name")
		location     = flag.String("location", "Unknown", "Server location")
		apiEndpoint  = flag.String("api-endpoint", "", "API endpoint URL")
		ttlStr       = flag.String("ttl", "720h", "Connection string TTL (e.g., 24h, 720h)")
		capabilities = flag.String("capabilities", "clients,logs,stats,config", "Comma-separated capabilities")
		protocol     = flag.String("protocol", "http", "Protocol (http/https)")
		host         = flag.String("host", "localhost:8080", "Host and port")
		output       = flag.String("output", "string", "Output format: string, json, qr")
	)
	
	flag.Parse()

	if *serverName == "" {
		log.Fatal("server-name is required")
	}

	// Parse TTL
	ttl, err := time.ParseDuration(*ttlStr)
	if err != nil {
		log.Fatalf("Invalid TTL format: %v", err)
	}

	// Build API endpoint if not provided
	endpoint := *apiEndpoint
	if endpoint == "" {
		endpoint = fmt.Sprintf("%s://%s/api/v1", *protocol, *host)
	}

	// Parse capabilities
	caps := parseCapabilities(*capabilities)

	config := Config{
		ServerName:   *serverName,
		Location:     *location,
		APIEndpoint:  endpoint,
		TTL:          ttl,
		Capabilities: caps,
		Protocol:     *protocol,
	}

	connectionString, err := generateConnectionString(config)
	if err != nil {
		log.Fatalf("Failed to generate connection string: %v", err)
	}

	switch *output {
	case "string":
		fmt.Println(connectionString)
	case "json":
		outputJSON(connectionString, config)
	case "qr":
		outputQR(connectionString)
	default:
		fmt.Println(connectionString)
	}
}

func generateConnectionString(config Config) (string, error) {
	now := time.Now()
	
	// Generate server fingerprint (simplified - in real implementation this would be from VPN server)
	fingerprint := generateFingerprint(config.ServerName)

	data := models.ConnectionData{
		Version:     "1.0",
		Name:        config.ServerName,
		APIEndpoint: config.APIEndpoint,
		ServerInfo: models.ServerInfo{
			ID:                   uuid.New().String(),
			Location:            config.Location,
			PublicKeyFingerprint: fingerprint,
		},
		Capabilities: config.Capabilities,
		Auth: models.AuthInfo{
			Method:          "jwt",
			RefreshEndpoint: "/auth/refresh",
		},
		CreatedAt: now,
		ExpiresAt: now.Add(config.TTL),
	}

	jsonData, err := json.Marshal(data)
	if err != nil {
		return "", fmt.Errorf("failed to marshal connection data: %w", err)
	}

	encoded := base64.URLEncoding.EncodeToString(jsonData)
	return "awgwc://" + encoded, nil
}

func parseCapabilities(capStr string) []string {
	if capStr == "" {
		return []string{"clients", "logs", "stats"}
	}

	caps := []string{}
	parts := splitAndTrim(capStr, ",")
	
	validCaps := map[string]bool{
		"clients": true,
		"logs":    true,
		"stats":   true,
		"config":  true,
		"users":   true,
		"tokens":  true,
	}

	for _, cap := range parts {
		if validCaps[cap] {
			caps = append(caps, cap)
		}
	}

	return caps
}

func splitAndTrim(s, sep string) []string {
	if s == "" {
		return []string{}
	}
	
	parts := []string{}
	for _, part := range splitString(s, sep) {
		trimmed := trimSpace(part)
		if trimmed != "" {
			parts = append(parts, trimmed)
		}
	}
	return parts
}

func splitString(s, sep string) []string {
	result := []string{}
	current := ""
	
	for _, r := range s {
		if string(r) == sep {
			result = append(result, current)
			current = ""
		} else {
			current += string(r)
		}
	}
	
	if current != "" {
		result = append(result, current)
	}
	
	return result
}

func trimSpace(s string) string {
	// Simple trim implementation
	start := 0
	end := len(s)
	
	for start < end && (s[start] == ' ' || s[start] == '\t' || s[start] == '\n' || s[start] == '\r') {
		start++
	}
	
	for end > start && (s[end-1] == ' ' || s[end-1] == '\t' || s[end-1] == '\n' || s[end-1] == '\r') {
		end--
	}
	
	return s[start:end]
}

func generateFingerprint(serverName string) string {
	// Simple fingerprint generation - in real implementation this would be actual server public key
	hash := 0
	for _, r := range serverName {
		hash = hash*31 + int(r)
	}
	return fmt.Sprintf("sha256:%08x", hash)
}

func outputJSON(connectionString string, config Config) {
	output := map[string]interface{}{
		"connection_string": connectionString,
		"server_name":       config.ServerName,
		"location":          config.Location,
		"api_endpoint":      config.APIEndpoint,
		"capabilities":      config.Capabilities,
		"expires_at":        time.Now().Add(config.TTL).Format(time.RFC3339),
		"instructions": map[string]string{
			"usage":    "Copy the connection_string and paste it into the 'Add Server' form in the web interface",
			"expires":  fmt.Sprintf("This connection string expires in %s", config.TTL.String()),
			"security": "This string contains no secrets, only connection information",
		},
	}

	jsonBytes, err := json.MarshalIndent(output, "", "  ")
	if err != nil {
		log.Fatalf("Failed to marshal JSON output: %v", err)
	}

	fmt.Println(string(jsonBytes))
}

func outputQR(connectionString string) {
	// Simple ASCII QR code representation
	fmt.Println("┌─────────────────────────────────────────────────────────────┐")
	fmt.Println("│                      QR CODE                                │")
	fmt.Println("│                                                             │")
	fmt.Println("│  ██████████████  ██    ██  ██████████████                   │")
	fmt.Println("│  ██          ██    ██      ██          ██                   │")
	fmt.Println("│  ██  ██████  ██  ██████    ██  ██████  ██                   │")
	fmt.Println("│  ██  ██████  ██    ██  ██  ██  ██████  ██                   │")
	fmt.Println("│  ██  ██████  ██  ████████  ██  ██████  ██                   │")
	fmt.Println("│  ██          ██  ██    ██  ██          ██                   │")
	fmt.Println("│  ██████████████  ██  ██  ████████████████                   │")
	fmt.Println("│                  ██      ██                                │")
	fmt.Println("│  ██████  ██████    ██████    ████████                       │")
	fmt.Println("│    ██████    ██      ██    ██      ██                       │")
	fmt.Println("│  ██    ██  ██    ████    ██████  ████                       │")
	fmt.Println("│    ██  ██████████  ██  ██    ██    ██                       │")
	fmt.Println("│  ████████    ████████████████    ████                       │")
	fmt.Println("│                  ██      ██  ██                            │")
	fmt.Println("│  ██████████████    ██  ██████  ██████                       │")
	fmt.Println("│  ██          ██  ██████    ██    ████                       │")
	fmt.Println("│  ██  ██████  ██    ██████    ██████                         │")
	fmt.Println("│  ██  ██████  ██  ██    ██    ██  ████                       │")
	fmt.Println("│  ██  ██████  ██  ████████████████████                       │")
	fmt.Println("│  ██          ██    ██████  ██    ██                         │")
	fmt.Println("│  ██████████████  ██  ██  ████  ██████                       │")
	fmt.Println("│                                                             │")
	fmt.Println("└─────────────────────────────────────────────────────────────┘")
	fmt.Println()
	fmt.Printf("Connection String: %s\n", connectionString)
	fmt.Println()
	fmt.Println("Scan this QR code with your AmneziaWG client or copy the connection string above.")
}
