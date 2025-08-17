package api

import (
	"net/http"

	"amneziawg-web-api/internal/auth"
	"amneziawg-web-api/internal/models"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// Login handles user authentication
func (h *Handler) Login(c *gin.Context) {
	var req models.LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		h.sendError(c, http.StatusBadRequest, "Invalid request body")
		return
	}

	// Get user from database
	user, err := h.db.GetUserByUsername(req.Username)
	if err != nil {
		h.logger.WithField("username", req.Username).Warn("Login attempt with invalid username")
		h.sendError(c, http.StatusUnauthorized, "Invalid credentials")
		return
	}

	// Check password
	if !h.authService.CheckPassword(req.Password, user.PasswordHash) {
		h.logger.WithField("username", req.Username).Warn("Login attempt with invalid password")
		h.sendError(c, http.StatusUnauthorized, "Invalid credentials")
		return
	}

	// Generate server ID (could be configuration-based)
	serverID := uuid.New().String()

	// Generate token pair
	tokenResponse, err := h.authService.GenerateTokenPair(user, serverID)
	if err != nil {
		h.logger.WithError(err).Error("Failed to generate token pair")
		h.sendError(c, http.StatusInternalServerError, "Failed to generate authentication tokens")
		return
	}

	h.logger.WithFields(map[string]interface{}{
		"user_id":  user.ID,
		"username": user.Username,
		"role":     user.Role,
	}).Info("User logged in successfully")

	h.sendSuccess(c, tokenResponse)
}

// RefreshToken handles token refresh
func (h *Handler) RefreshToken(c *gin.Context) {
	var req models.RefreshTokenRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		h.sendError(c, http.StatusBadRequest, "Invalid request body")
		return
	}

	// Validate refresh token
	claims, err := h.authService.ValidateToken(req.RefreshToken)
	if err != nil {
		h.logger.WithError(err).Warn("Invalid refresh token")
		h.sendError(c, http.StatusUnauthorized, "Invalid or expired refresh token")
		return
	}

	// Get user from database
	user, err := h.db.GetUserByID(claims.UserID)
	if err != nil {
		h.logger.WithError(err).WithField("user_id", claims.UserID).Error("User not found during token refresh")
		h.sendError(c, http.StatusUnauthorized, "User not found")
		return
	}

	// Generate new token pair
	tokenResponse, err := h.authService.RefreshToken(req.RefreshToken, user, claims.ServerID)
	if err != nil {
		h.logger.WithError(err).Error("Failed to refresh token")
		h.sendError(c, http.StatusInternalServerError, "Failed to refresh token")
		return
	}

	h.logger.WithField("user_id", user.ID).Info("Token refreshed successfully")
	h.sendSuccess(c, tokenResponse)
}

// CreateUser creates a new user (admin only)
func (h *Handler) CreateUser(c *gin.Context) {
	var req struct {
		Username string `json:"username" binding:"required,min=3,max=50"`
		Password string `json:"password" binding:"required,min=6"`
		Role     string `json:"role" binding:"required,oneof=admin operator readonly"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		h.sendError(c, http.StatusBadRequest, "Invalid request body")
		return
	}

	// Check if user already exists
	existingUser, err := h.db.GetUserByUsername(req.Username)
	if err == nil && existingUser != nil {
		h.sendError(c, http.StatusConflict, "User already exists")
		return
	}

	// Hash password
	passwordHash, err := h.authService.HashPassword(req.Password)
	if err != nil {
		h.logger.WithError(err).Error("Failed to hash password")
		h.sendError(c, http.StatusInternalServerError, "Failed to create user")
		return
	}

	// Create user
	user := &models.User{
		Username:     req.Username,
		PasswordHash: passwordHash,
		Role:         req.Role,
	}

	if err := h.db.CreateUser(user); err != nil {
		h.logger.WithError(err).Error("Failed to create user in database")
		h.sendError(c, http.StatusInternalServerError, "Failed to create user")
		return
	}

	// Don't return password hash
	user.PasswordHash = ""

	h.logger.WithFields(map[string]interface{}{
		"username":    user.Username,
		"role":        user.Role,
		"created_by":  func() string { userID, _ := auth.GetUserID(c); return userID }(),
	}).Info("User created successfully")

	h.sendSuccess(c, user)
}

// ListUsers lists all users (admin only)
func (h *Handler) ListUsers(c *gin.Context) {
	// This would require implementing a ListUsers method in the database
	// For now, return a placeholder response
	h.sendSuccess(c, map[string]interface{}{
		"users": []interface{}{},
		"total": 0,
		"message": "User listing not implemented yet",
	})
}
