package auth

import (
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"time"

	"amneziawg-web-api/internal/models"
	
	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
)

var (
	ErrInvalidToken = errors.New("invalid token")
	ErrTokenExpired = errors.New("token expired")
	ErrInvalidCredentials = errors.New("invalid credentials")
)

type JWTService struct {
	secretKey      []byte
	accessTTL      time.Duration
	refreshTTL     time.Duration
	issuer         string
	tokenStorage   TokenStorage
}

type TokenStorage interface {
	StoreToken(token *models.AuthToken) error
	GetToken(tokenHash string) (*models.AuthToken, error)
	RevokeToken(tokenHash string) error
	CleanupExpiredTokens() error
}

func NewJWTService(secretKey string, accessTTL, refreshTTL time.Duration, storage TokenStorage) *JWTService {
	return &JWTService{
		secretKey:    []byte(secretKey),
		accessTTL:    accessTTL,
		refreshTTL:   refreshTTL,
		issuer:       "amneziawg-web-api",
		tokenStorage: storage,
	}
}

// GenerateTokenPair creates access and refresh tokens
func (s *JWTService) GenerateTokenPair(user *models.User, serverID string) (*models.LoginResponse, error) {
	now := time.Now()
	
	// Generate access token
	accessClaims := &models.Claims{
		UserID:       user.ID,
		ServerID:     serverID,
		Capabilities: models.DefaultCapabilities[user.Role],
		Role:         user.Role,
		RegisteredClaims: jwt.RegisteredClaims{
			ID:        uuid.New().String(),
			Subject:   user.ID,
			Issuer:    s.issuer,
			IssuedAt:  jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(now.Add(s.accessTTL)),
		},
	}

	accessToken := jwt.NewWithClaims(jwt.SigningMethodHS256, accessClaims)
	accessTokenString, err := accessToken.SignedString(s.secretKey)
	if err != nil {
		return nil, err
	}

	// Generate refresh token
	refreshClaims := &models.Claims{
		UserID:   user.ID,
		ServerID: serverID,
		Role:     user.Role,
		RegisteredClaims: jwt.RegisteredClaims{
			ID:        uuid.New().String(),
			Subject:   user.ID,
			Issuer:    s.issuer,
			IssuedAt:  jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(now.Add(s.refreshTTL)),
		},
	}

	refreshToken := jwt.NewWithClaims(jwt.SigningMethodHS256, refreshClaims)
	refreshTokenString, err := refreshToken.SignedString(s.secretKey)
	if err != nil {
		return nil, err
	}

	// Store tokens in database
	accessTokenHash := s.hashToken(accessTokenString)
	refreshTokenHash := s.hashToken(refreshTokenString)

	if err := s.tokenStorage.StoreToken(&models.AuthToken{
		ID:        accessClaims.ID,
		UserID:    user.ID,
		TokenHash: accessTokenHash,
		TokenType: models.TokenTypeAccess,
		ExpiresAt: accessClaims.ExpiresAt.Time,
		CreatedAt: now,
	}); err != nil {
		return nil, err
	}

	if err := s.tokenStorage.StoreToken(&models.AuthToken{
		ID:        refreshClaims.ID,
		UserID:    user.ID,
		TokenHash: refreshTokenHash,
		TokenType: models.TokenTypeRefresh,
		ExpiresAt: refreshClaims.ExpiresAt.Time,
		CreatedAt: now,
	}); err != nil {
		return nil, err
	}

	return &models.LoginResponse{
		AccessToken:  accessTokenString,
		RefreshToken: refreshTokenString,
		ExpiresAt:    accessClaims.ExpiresAt.Time,
		User:         *user,
	}, nil
}

// ValidateToken validates and parses JWT token
func (s *JWTService) ValidateToken(tokenString string) (*models.Claims, error) {
	token, err := jwt.ParseWithClaims(tokenString, &models.Claims{}, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, errors.New("unexpected signing method")
		}
		return s.secretKey, nil
	})

	if err != nil {
		return nil, ErrInvalidToken
	}

	claims, ok := token.Claims.(*models.Claims)
	if !ok || !token.Valid {
		return nil, ErrInvalidToken
	}

	// Check if token exists in database and not revoked
	tokenHash := s.hashToken(tokenString)
	storedToken, err := s.tokenStorage.GetToken(tokenHash)
	if err != nil {
		return nil, ErrInvalidToken
	}

	if storedToken.Revoked {
		return nil, ErrInvalidToken
	}

	if time.Now().After(storedToken.ExpiresAt) {
		return nil, ErrTokenExpired
	}

	return claims, nil
}

// RefreshToken creates new access token from refresh token
func (s *JWTService) RefreshToken(refreshTokenString string, user *models.User, serverID string) (*models.LoginResponse, error) {
	// Validate refresh token
	_, err := s.ValidateToken(refreshTokenString)
	if err != nil {
		return nil, err
	}

	// Check if it's a refresh token
	refreshTokenHash := s.hashToken(refreshTokenString)
	storedToken, err := s.tokenStorage.GetToken(refreshTokenHash)
	if err != nil || storedToken.TokenType != models.TokenTypeRefresh {
		return nil, ErrInvalidToken
	}

	// Generate new token pair
	return s.GenerateTokenPair(user, serverID)
}

// RevokeToken revokes a token
func (s *JWTService) RevokeToken(tokenString string) error {
	tokenHash := s.hashToken(tokenString)
	return s.tokenStorage.RevokeToken(tokenHash)
}

// RevokeAllUserTokens revokes all tokens for a user
func (s *JWTService) RevokeAllUserTokens(userID string) error {
	// This would need to be implemented in the storage layer
	return nil
}

// HashPassword creates bcrypt hash of password
func (s *JWTService) HashPassword(password string) (string, error) {
	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	return string(hash), err
}

// CheckPassword verifies password against hash
func (s *JWTService) CheckPassword(password, hash string) bool {
	err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(password))
	return err == nil
}

// GenerateSecureKey generates a secure key for JWT signing
func GenerateSecureKey() (string, error) {
	key := make([]byte, 32) // 256 bits
	_, err := rand.Read(key)
	if err != nil {
		return "", err
	}
	return hex.EncodeToString(key), nil
}

// hashToken creates SHA256 hash of token for storage
func (s *JWTService) hashToken(token string) string {
	hash := sha256.Sum256([]byte(token))
	return hex.EncodeToString(hash[:])
}

// CleanupExpiredTokens removes expired tokens from storage
func (s *JWTService) CleanupExpiredTokens() error {
	return s.tokenStorage.CleanupExpiredTokens()
}
