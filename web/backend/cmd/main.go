package main

import (
	"context"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"amneziawg-web-api/internal/api"
	"amneziawg-web-api/internal/auth"
	"amneziawg-web-api/internal/config"
	"amneziawg-web-api/internal/database"
	"amneziawg-web-api/internal/vpn"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/sirupsen/logrus"
)

func main() {
	// Загружаем конфигурацию
	cfg := config.Load()

	// Настраиваем логирование
	logger := logrus.New()
	logLevel, err := logrus.ParseLevel(cfg.LogLevel)
	if err != nil {
		logLevel = logrus.InfoLevel
	}
	logger.SetLevel(logLevel)
	
	if cfg.LogFormat == "json" {
		logger.SetFormatter(&logrus.JSONFormatter{})
	} else {
		logger.SetFormatter(&logrus.TextFormatter{})
	}

	logger.Info("Starting AmneziaWG Web API server...")

	// Инициализируем базу данных
	db, err := database.NewSQLiteDB(cfg.DatabaseURL, logger)
	if err != nil {
		logger.WithError(err).Fatal("Failed to initialize database")
	}
	defer db.Close()

	logger.Info("Database initialized successfully")

	// Инициализируем VPN сервис
	vpnService, err := vpn.NewVPNService(cfg.VPNContainerName, cfg.VPNProjectPath, logger)
	if err != nil {
		logger.WithError(err).Fatal("Failed to initialize VPN service")
	}
	defer vpnService.Close()

	logger.Info("VPN service initialized successfully")

	// Инициализируем JWT сервис
	accessTTL, err := time.ParseDuration(cfg.JWTAccessTTL)
	if err != nil {
		accessTTL = 15 * time.Minute
	}
	
	refreshTTL, err := time.ParseDuration(cfg.JWTRefreshTTL)
	if err != nil {
		refreshTTL = 24 * time.Hour
	}

	authService := auth.NewJWTService(cfg.JWTSecretKey, accessTTL, refreshTTL, db)
	logger.Info("JWT auth service initialized successfully")

	// Настраиваем Gin
	if cfg.Environment == "production" {
		gin.SetMode(gin.ReleaseMode)
	}
	
	router := gin.New()
	router.Use(gin.Logger())
	router.Use(gin.Recovery())

	// CORS настройки
	corsConfig := cors.DefaultConfig()
	corsConfig.AllowOrigins = cfg.CORSAllowedOrigins
	corsConfig.AllowCredentials = true
	corsConfig.AllowMethods = []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"}
	corsConfig.AllowHeaders = []string{"Origin", "Content-Length", "Content-Type", "Authorization"}
	router.Use(cors.New(corsConfig))

	// Создаем API handlers
	apiHandler := api.NewHandler(vpnService, authService, db, logger)

	// Настраиваем маршруты
	apiHandler.SetupRoutes(router)

	// Настраиваем HTTP сервер
	srv := &http.Server{
		Addr:         cfg.ServerAddress,
		Handler:      router,
		ReadTimeout:  30 * time.Second,
		WriteTimeout: 30 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	// Запускаем сервер в горутине
	go func() {
		logger.WithField("address", cfg.ServerAddress).Info("HTTP server started")
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.WithError(err).Fatal("Failed to start server")
		}
	}()

	// Запускаем cleanup routine для токенов
	go func() {
		ticker := time.NewTicker(1 * time.Hour)
		defer ticker.Stop()
		
		for {
			select {
			case <-ticker.C:
				if err := db.CleanupExpiredTokens(); err != nil {
					logger.WithError(err).Error("Failed to cleanup expired tokens")
				}
				if err := db.CleanupExpiredConnectionStrings(); err != nil {
					logger.WithError(err).Error("Failed to cleanup expired connection strings")
				}
			}
		}
	}()

	logger.Info("AmneziaWG Web API server is ready")

	// Ждем сигнал завершения
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	logger.Info("Shutting down server...")

	// Graceful shutdown с таймаутом
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		logger.WithError(err).Fatal("Server forced to shutdown")
	}

	logger.Info("Server exited gracefully")
}
