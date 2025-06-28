package adapters

import (
	"context"
	"encoding/json"
	"fmt"
	"log/slog"
	"time"

	"golang.org/x/oauth2"
	"golang.org/x/oauth2/google"

	"ssulmeta-go/internal/youtube/ports"
	"ssulmeta-go/pkg/errors"
)

// OAuthService implements YouTube OAuth2 authentication
type OAuthService struct {
	config *oauth2.Config
	logger *slog.Logger
}

// NewOAuthService creates a new OAuth service instance
func NewOAuthService(config *ports.OAuthConfig, logger *slog.Logger) *OAuthService {
	oauth2Config := &oauth2.Config{
		ClientID:     config.ClientID,
		ClientSecret: config.ClientSecret,
		RedirectURL:  config.RedirectURLs[0], // Use first redirect URL as default
		Scopes:       config.Scopes,
		Endpoint:     google.Endpoint,
	}

	return &OAuthService{
		config: oauth2Config,
		logger: logger,
	}
}

// GetAuthURL generates an OAuth2 authorization URL
func (s *OAuthService) GetAuthURL(state string) string {
	url := s.config.AuthCodeURL(state, oauth2.AccessTypeOffline, oauth2.ApprovalForce)

	s.logger.Info("Generated OAuth2 authorization URL",
		"state", state,
		"url_length", len(url),
	)

	return url
}

// ExchangeCode exchanges an authorization code for tokens
func (s *OAuthService) ExchangeCode(ctx context.Context, code string) (*ports.AuthToken, error) {
	s.logger.Info("Exchanging authorization code for tokens", "code_length", len(code))

	token, err := s.config.Exchange(ctx, code)
	if err != nil {
		return nil, errors.NewExternalError(
			errors.CodeExternalAPIError,
			"failed to exchange authorization code",
			map[string]interface{}{
				"error": err.Error(),
			},
		)
	}

	authToken := &ports.AuthToken{
		AccessToken:  token.AccessToken,
		RefreshToken: token.RefreshToken,
		TokenType:    token.TokenType,
		ExpiresAt:    token.Expiry,
		Scopes:       s.config.Scopes,
	}

	s.logger.Info("Successfully exchanged authorization code",
		"token_type", authToken.TokenType,
		"expires_at", authToken.ExpiresAt,
		"has_refresh_token", authToken.RefreshToken != "",
	)

	return authToken, nil
}

// RefreshToken refreshes an expired access token
func (s *OAuthService) RefreshToken(ctx context.Context, refreshToken string) (*ports.AuthToken, error) {
	s.logger.Info("Refreshing access token")

	token := &oauth2.Token{
		RefreshToken: refreshToken,
	}

	tokenSource := s.config.TokenSource(ctx, token)
	newToken, err := tokenSource.Token()
	if err != nil {
		return nil, errors.NewExternalError(
			errors.CodeExternalAPIError,
			"failed to refresh access token",
			map[string]interface{}{
				"error": err.Error(),
			},
		)
	}

	authToken := &ports.AuthToken{
		AccessToken:  newToken.AccessToken,
		RefreshToken: newToken.RefreshToken,
		TokenType:    newToken.TokenType,
		ExpiresAt:    newToken.Expiry,
		Scopes:       s.config.Scopes,
	}

	// Keep original refresh token if new one is not provided
	if authToken.RefreshToken == "" {
		authToken.RefreshToken = refreshToken
	}

	s.logger.Info("Successfully refreshed access token",
		"token_type", authToken.TokenType,
		"expires_at", authToken.ExpiresAt,
	)

	return authToken, nil
}

// ValidateToken validates an access token
func (s *OAuthService) ValidateToken(ctx context.Context, accessToken string) error {
	s.logger.Debug("Validating access token")

	// Create a token from the access token
	token := &oauth2.Token{
		AccessToken: accessToken,
		TokenType:   "Bearer",
	}

	// Create an HTTP client with the token
	client := s.config.Client(ctx, token)

	// Make a simple API call to validate the token
	// We'll use the YouTube API's channels endpoint with "mine" parameter
	resp, err := client.Get("https://www.googleapis.com/youtube/v3/channels?part=id&mine=true")
	if err != nil {
		return errors.NewExternalError(
			errors.CodeExternalAPIError,
			"failed to validate access token",
			map[string]interface{}{
				"error": err.Error(),
			},
		)
	}
	defer func() {
		_ = resp.Body.Close() // Ignore close error
	}()

	if resp.StatusCode != 200 {
		return errors.NewExternalError(
			errors.CodeUnauthorized,
			"access token is invalid or expired",
			map[string]interface{}{
				"status_code": resp.StatusCode,
				"status":      resp.Status,
			},
		)
	}

	s.logger.Debug("Access token validation successful")
	return nil
}

// RevokeToken revokes an access token
func (s *OAuthService) RevokeToken(ctx context.Context, token string) error {
	s.logger.Info("Revoking access token")

	revokeURL := fmt.Sprintf("https://oauth2.googleapis.com/revoke?token=%s", token)

	client := s.config.Client(ctx, nil)
	resp, err := client.Post(revokeURL, "application/x-www-form-urlencoded", nil)
	if err != nil {
		return errors.NewExternalError(
			errors.CodeExternalAPIError,
			"failed to revoke access token",
			map[string]interface{}{
				"error": err.Error(),
			},
		)
	}
	defer func() {
		_ = resp.Body.Close() // Ignore close error
	}()

	if resp.StatusCode != 200 {
		return errors.NewExternalError(
			errors.CodeExternalAPIError,
			"token revocation failed",
			map[string]interface{}{
				"status_code": resp.StatusCode,
				"status":      resp.Status,
			},
		)
	}

	s.logger.Info("Successfully revoked access token")
	return nil
}

// GetTokenInfo retrieves information about a token (for debugging/monitoring)
func (s *OAuthService) GetTokenInfo(ctx context.Context, accessToken string) (map[string]interface{}, error) {
	s.logger.Debug("Getting token information")

	infoURL := fmt.Sprintf("https://oauth2.googleapis.com/tokeninfo?access_token=%s", accessToken)

	client := s.config.Client(ctx, nil)
	resp, err := client.Get(infoURL)
	if err != nil {
		return nil, errors.NewExternalError(
			errors.CodeExternalAPIError,
			"failed to get token info",
			map[string]interface{}{
				"error": err.Error(),
			},
		)
	}
	defer func() {
		_ = resp.Body.Close() // Ignore close error
	}()

	if resp.StatusCode != 200 {
		return nil, errors.NewExternalError(
			errors.CodeExternalAPIError,
			"token info request failed",
			map[string]interface{}{
				"status_code": resp.StatusCode,
				"status":      resp.Status,
			},
		)
	}

	var tokenInfo map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&tokenInfo); err != nil {
		return nil, errors.NewExternalError(
			errors.CodeExternalAPIError,
			"failed to decode token info response",
			map[string]interface{}{
				"error": err.Error(),
			},
		)
	}

	s.logger.Debug("Successfully retrieved token information",
		"scope", tokenInfo["scope"],
		"expires_in", tokenInfo["expires_in"],
	)

	return tokenInfo, nil
}

// IsTokenExpired checks if a token is expired
func (s *OAuthService) IsTokenExpired(token *ports.AuthToken) bool {
	if token.ExpiresAt.IsZero() {
		return false // No expiration time set
	}

	// Add a buffer of 5 minutes to account for clock skew
	buffer := time.Minute * 5
	return time.Now().Add(buffer).After(token.ExpiresAt)
}

// CreateOAuth2Token converts ports.AuthToken to oauth2.Token for use with Google API clients
func (s *OAuthService) CreateOAuth2Token(authToken *ports.AuthToken) *oauth2.Token {
	return &oauth2.Token{
		AccessToken:  authToken.AccessToken,
		RefreshToken: authToken.RefreshToken,
		TokenType:    authToken.TokenType,
		Expiry:       authToken.ExpiresAt,
	}
}
