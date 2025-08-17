package config

import (
	"os"
	"strconv"
	"strings"
)

type Config struct {
	// Server Configuration
	Environment   string
	ServerAddress string
	LogLevel      string
	LogFormat     string

	// JWT Configuration
	JWTSecretKey    string
	JWTAccessTTL    string
	JWTRefreshTTL   string

	// Database Configuration
	DatabaseURL string

	// VPN Server Integration
	VPNContainerName string
	VPNProjectPath   string

	// CORS Configuration
	CORSAllowedOrigins []string

	// Rate Limiting
	RateLimitRequests int
	RateLimitWindow   string

	// Connection String Settings
	ConnectionDefaultTTL    string
	ServerDefaultLocation   string
	APIEndpointHost         string
	APIEndpointProtocol     string
}

func Load() *Config {
	cfg := &Config{
		// Server Configuration
		Environment:   getEnv("SERVER_ENVIRONMENT", "development"),
		ServerAddress: getEnv("SERVER_ADDRESS", ":8080"),
		LogLevel:      getEnv("LOG_LEVEL", "info"),
		LogFormat:     getEnv("LOG_FORMAT", "text"),

		// JWT Configuration
		JWTSecretKey:  getEnv("JWT_SECRET_KEY", "default-secret-key-change-in-production"),
		JWTAccessTTL:  getEnv("JWT_ACCESS_TTL", "15m"),
		JWTRefreshTTL: getEnv("JWT_REFRESH_TTL", "24h"),

		// Database Configuration
		DatabaseURL: getEnv("DATABASE_URL", "file:./data/amneziawg.db?cache=shared&mode=rwc"),

		// VPN Server Integration
		VPNContainerName: getEnv("VPN_CONTAINER_NAME", "amneziawg-server"),
		VPNProjectPath:   getEnv("VPN_PROJECT_PATH", "/app/amnezia-wg-docker"),

		// CORS Configuration
		CORSAllowedOrigins: strings.Split(getEnv("CORS_ALLOWED_ORIGINS", "http://localhost:3000,http://localhost:80,http://localhost"), ","),

		// Rate Limiting
		RateLimitRequests: parseInt(getEnv("RATE_LIMIT_REQUESTS", "100"), 100),
		RateLimitWindow:   getEnv("RATE_LIMIT_WINDOW", "1h"),

		// Connection String Settings
		ConnectionDefaultTTL:  getEnv("CONNECTION_DEFAULT_TTL", "720h"),
		ServerDefaultLocation: getEnv("SERVER_DEFAULT_LOCATION", "Unknown"),
		APIEndpointHost:       getEnv("API_ENDPOINT_HOST", "localhost:8080"),
		APIEndpointProtocol:   getEnv("API_ENDPOINT_PROTOCOL", "http"),
	}

	// Validate JWT secret key
	if cfg.JWTSecretKey == "default-secret-key-change-in-production" && cfg.Environment == "production" {
		panic("JWT_SECRET_KEY must be set in production environment")
	}

	return cfg
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func parseInt(value string, defaultValue int) int {
	if parsed, err := strconv.Atoi(value); err == nil {
		return parsed
	}
	return defaultValue
}