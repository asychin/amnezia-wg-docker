package models

import (
	"time"

	"github.com/golang-jwt/jwt/v5"
)

// JWT Claims
type Claims struct {
	UserID       string   `json:"user_id"`
	ServerID     string   `json:"server_id"`
	Capabilities []string `json:"capabilities"`
	Role         string   `json:"role"`
	jwt.RegisteredClaims
}

// Auth Request/Response models
type LoginRequest struct {
	Username string `json:"username" binding:"required"`
	Password string `json:"password" binding:"required"`
}

type LoginResponse struct {
	AccessToken  string    `json:"access_token"`
	RefreshToken string    `json:"refresh_token"`
	ExpiresAt    time.Time `json:"expires_at"`
	User         User      `json:"user"`
}

type RefreshTokenRequest struct {
	RefreshToken string `json:"refresh_token" binding:"required"`
}

type User struct {
	ID           string    `json:"id" db:"id"`
	Username     string    `json:"username" db:"username"`
	PasswordHash string    `json:"-" db:"password_hash"`
	Role         string    `json:"role" db:"role"`
	CreatedAt    time.Time `json:"created_at" db:"created_at"`
	UpdatedAt    time.Time `json:"updated_at" db:"updated_at"`
}

// Auth Token Storage
type AuthToken struct {
	ID           string    `json:"id" db:"id"`
	UserID       string    `json:"user_id" db:"user_id"`
	TokenHash    string    `json:"-" db:"token_hash"`
	TokenType    string    `json:"token_type" db:"token_type"` // access, refresh
	ExpiresAt    time.Time `json:"expires_at" db:"expires_at"`
	Revoked      bool      `json:"revoked" db:"revoked"`
	CreatedAt    time.Time `json:"created_at" db:"created_at"`
	LastUsedAt   *time.Time `json:"last_used_at" db:"last_used_at"`
}

// Permission types
const (
	RoleAdmin     = "admin"
	RoleOperator  = "operator"
	RoleReadOnly  = "readonly"
	
	TokenTypeAccess  = "access"
	TokenTypeRefresh = "refresh"
)

// Capabilities
var DefaultCapabilities = map[string][]string{
	RoleAdmin:    {"clients", "logs", "stats", "config", "users", "tokens"},
	RoleOperator: {"clients", "logs", "stats", "config"},
	RoleReadOnly: {"logs", "stats"},
}
