package auth

import (
	"net/http"
	"strings"

	"amneziawg-web-api/internal/models"

	"github.com/gin-gonic/gin"
	"github.com/sirupsen/logrus"
)

type AuthMiddleware struct {
	jwtService *JWTService
	logger     *logrus.Logger
}

func NewAuthMiddleware(jwtService *JWTService, logger *logrus.Logger) *AuthMiddleware {
	return &AuthMiddleware{
		jwtService: jwtService,
		logger:     logger,
	}
}

// RequireAuth middleware that requires valid JWT token
func (m *AuthMiddleware) RequireAuth() gin.HandlerFunc {
	return func(c *gin.Context) {
		token := m.extractTokenFromHeader(c)
		if token == "" {
			m.logger.Warn("Missing authentication token")
			c.JSON(http.StatusUnauthorized, gin.H{
				"success": false,
				"error":   "Authentication required",
			})
			c.Abort()
			return
		}

		claims, err := m.jwtService.ValidateToken(token)
		if err != nil {
			m.logger.WithError(err).Warn("Invalid authentication token")
			c.JSON(http.StatusUnauthorized, gin.H{
				"success": false,
				"error":   "Invalid or expired token",
			})
			c.Abort()
			return
		}

		// Set user info in context
		c.Set("user_id", claims.UserID)
		c.Set("server_id", claims.ServerID)
		c.Set("user_role", claims.Role)
		c.Set("capabilities", claims.Capabilities)
		c.Set("claims", claims)

		c.Next()
	}
}

// RequireCapability middleware that requires specific capability
func (m *AuthMiddleware) RequireCapability(capability string) gin.HandlerFunc {
	return func(c *gin.Context) {
		capabilities, exists := c.Get("capabilities")
		if !exists {
			m.logger.Error("Capabilities not found in context")
			c.JSON(http.StatusInternalServerError, gin.H{
				"success": false,
				"error":   "Internal server error",
			})
			c.Abort()
			return
		}

		caps, ok := capabilities.([]string)
		if !ok {
			m.logger.Error("Invalid capabilities type in context")
			c.JSON(http.StatusInternalServerError, gin.H{
				"success": false,
				"error":   "Internal server error",
			})
			c.Abort()
			return
		}

		// Check if user has required capability
		hasCapability := false
		for _, cap := range caps {
			if cap == capability {
				hasCapability = true
				break
			}
		}

		if !hasCapability {
			userID, _ := c.Get("user_id")
			m.logger.WithFields(logrus.Fields{
				"user_id":    userID,
				"capability": capability,
				"user_caps":  caps,
			}).Warn("Insufficient permissions")
			
			c.JSON(http.StatusForbidden, gin.H{
				"success": false,
				"error":   "Insufficient permissions",
			})
			c.Abort()
			return
		}

		c.Next()
	}
}

// RequireRole middleware that requires specific role
func (m *AuthMiddleware) RequireRole(role string) gin.HandlerFunc {
	return func(c *gin.Context) {
		userRole, exists := c.Get("user_role")
		if !exists {
			m.logger.Error("User role not found in context")
			c.JSON(http.StatusInternalServerError, gin.H{
				"success": false,
				"error":   "Internal server error",
			})
			c.Abort()
			return
		}

		if userRole != role {
			userID, _ := c.Get("user_id")
			m.logger.WithFields(logrus.Fields{
				"user_id":      userID,
				"required_role": role,
				"user_role":    userRole,
			}).Warn("Insufficient role permissions")
			
			c.JSON(http.StatusForbidden, gin.H{
				"success": false,
				"error":   "Insufficient permissions",
			})
			c.Abort()
			return
		}

		c.Next()
	}
}

// RequireAdminRole middleware that requires admin role
func (m *AuthMiddleware) RequireAdminRole() gin.HandlerFunc {
	return m.RequireRole(models.RoleAdmin)
}

// OptionalAuth middleware that extracts user info if token is present
func (m *AuthMiddleware) OptionalAuth() gin.HandlerFunc {
	return func(c *gin.Context) {
		token := m.extractTokenFromHeader(c)
		if token == "" {
			c.Next()
			return
		}

		claims, err := m.jwtService.ValidateToken(token)
		if err != nil {
			// Log but don't fail the request
			m.logger.WithError(err).Debug("Optional auth token validation failed")
			c.Next()
			return
		}

		// Set user info in context
		c.Set("user_id", claims.UserID)
		c.Set("server_id", claims.ServerID)
		c.Set("user_role", claims.Role)
		c.Set("capabilities", claims.Capabilities)
		c.Set("claims", claims)

		c.Next()
	}
}

// extractTokenFromHeader extracts JWT token from Authorization header
func (m *AuthMiddleware) extractTokenFromHeader(c *gin.Context) string {
	authHeader := c.GetHeader("Authorization")
	if authHeader == "" {
		return ""
	}

	// Check for Bearer token format
	const bearerPrefix = "Bearer "
	if !strings.HasPrefix(authHeader, bearerPrefix) {
		return ""
	}

	return strings.TrimPrefix(authHeader, bearerPrefix)
}

// GetUserID gets user ID from context
func GetUserID(c *gin.Context) (string, bool) {
	userID, exists := c.Get("user_id")
	if !exists {
		return "", false
	}
	
	id, ok := userID.(string)
	return id, ok
}

// GetUserRole gets user role from context
func GetUserRole(c *gin.Context) (string, bool) {
	role, exists := c.Get("user_role")
	if !exists {
		return "", false
	}
	
	r, ok := role.(string)
	return r, ok
}

// GetCapabilities gets user capabilities from context
func GetCapabilities(c *gin.Context) ([]string, bool) {
	caps, exists := c.Get("capabilities")
	if !exists {
		return nil, false
	}
	
	capabilities, ok := caps.([]string)
	return capabilities, ok
}

// GetClaims gets JWT claims from context
func GetClaims(c *gin.Context) (*models.Claims, bool) {
	claims, exists := c.Get("claims")
	if !exists {
		return nil, false
	}
	
	claimsData, ok := claims.(*models.Claims)
	return claimsData, ok
}
