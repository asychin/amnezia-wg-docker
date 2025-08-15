package config

import (
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/sirupsen/logrus"
)

type Config struct {
	Environment string
	LogLevel    logrus.Level
	Server      ServerConfig
	AmneziaWG   AmneziaWGConfig
	CORS        CORSConfig
}

type ServerConfig struct {
	Address      string
	ReadTimeout  time.Duration
	WriteTimeout time.Duration
	IdleTimeout  time.Duration
}

type AmneziaWGConfig struct {
	ConfigPath   string
	ClientsPath  string
	ScriptsPath  string
	MakeCommand  string
	ServiceName  string
}

type CORSConfig struct {
	AllowedOrigins []string
}

func Load() *Config {
	cfg := &Config{
		Environment: getEnv("ENVIRONMENT", "development"),
		LogLevel:    parseLogLevel(getEnv("LOG_LEVEL", "info")),
		Server: ServerConfig{
			Address:      getEnv("SERVER_ADDRESS", ":8080"),
			ReadTimeout:  parseDuration(getEnv("SERVER_READ_TIMEOUT", "10s")),
			WriteTimeout: parseDuration(getEnv("SERVER_WRITE_TIMEOUT", "10s")),
			IdleTimeout:  parseDuration(getEnv("SERVER_IDLE_TIMEOUT", "60s")),
		},
		AmneziaWG: AmneziaWGConfig{
			ConfigPath:  getEnv("AWG_CONFIG_PATH", "/app/config"),
			ClientsPath: getEnv("AWG_CLIENTS_PATH", "/app/clients"),
			ScriptsPath: getEnv("AWG_SCRIPTS_PATH", "/app/scripts"),
			MakeCommand: getEnv("AWG_MAKE_COMMAND", "make"),
			ServiceName: getEnv("AWG_SERVICE_NAME", "amneziawg-server"),
		},
		CORS: CORSConfig{
			AllowedOrigins: strings.Split(getEnv("CORS_ALLOWED_ORIGINS", "http://localhost:3000"), ","),
		},
	}

	return cfg
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func parseLogLevel(level string) logrus.Level {
	parsed, err := logrus.ParseLevel(level)
	if err != nil {
		return logrus.InfoLevel
	}
	return parsed
}

func parseDuration(duration string) time.Duration {
	parsed, err := time.ParseDuration(duration)
	if err != nil {
		return 30 * time.Second
	}
	return parsed
}

func parseInt(value string, defaultValue int) int {
	if parsed, err := strconv.Atoi(value); err == nil {
		return parsed
	}
	return defaultValue
}
