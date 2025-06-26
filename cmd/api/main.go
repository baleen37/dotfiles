package main

import (
	"fmt"
	"log"
	"net/http"

	calcAdapters "ssulmeta-go/internal/calculator/adapters"
	calcCore "ssulmeta-go/internal/calculator/core"
	channelAdapters "ssulmeta-go/internal/channel/adapters"
	channelService "ssulmeta-go/internal/channel/service"
	healthAdapters "ssulmeta-go/internal/health/adapters"
	textAdapters "ssulmeta-go/internal/text/adapters"
	textCore "ssulmeta-go/internal/text/core"

	"github.com/redis/go-redis/v9"
)

func setupServer() *http.Server {
	return setupServerWithRedisAddr("localhost:6379")
}

func setupServerWithRedisAddr(redisAddr string) *http.Server {
	// Create Redis client
	redisClient := redis.NewClient(&redis.Options{
		Addr: redisAddr, // Redis address
		DB:   0,         // Default DB
	})

	// Create core services
	calculator := calcCore.NewCalculator()
	textProcessor := textCore.NewProcessor()

	// Create channel repository and service
	channelRepo := channelAdapters.NewRedisChannelRepository(redisClient)
	channelSvc := channelService.NewChannelService(channelRepo)

	// Create HTTP adapters
	calcAdapter := calcAdapters.NewHTTPAdapter(calculator)
	textAdapter := textAdapters.NewHTTPAdapter(textProcessor)
	channelAdapter := channelAdapters.NewHTTPAdapter(channelSvc)

	// Setup routes
	mux := http.NewServeMux()

	// Health check
	mux.HandleFunc("/health", healthAdapters.HandleHealth)

	// Calculator endpoints
	mux.HandleFunc("/calculator/add", calcAdapter.HandleAdd)
	mux.HandleFunc("/calculator/multiply", calcAdapter.HandleMultiply)

	// Text processing endpoints
	mux.HandleFunc("/text/reverse", textAdapter.HandleReverse)
	mux.HandleFunc("/text/capitalize", textAdapter.HandleCapitalize)

	// Channel endpoints
	mux.HandleFunc("/channels", func(w http.ResponseWriter, r *http.Request) {
		switch r.Method {
		case http.MethodPost:
			channelAdapter.HandleCreateChannel(w, r)
		case http.MethodGet:
			channelAdapter.HandleListChannels(w, r)
		default:
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		}
	})

	mux.HandleFunc("/channels/", func(w http.ResponseWriter, r *http.Request) {
		// Route based on path and method
		path := r.URL.Path
		method := r.Method

		// Handle /channels/{id}/activate
		if method == http.MethodPost && len(path) > 10 && path[len(path)-9:] == "/activate" {
			channelAdapter.HandleActivateChannel(w, r)
			return
		}

		// Handle /channels/{id}/deactivate
		if method == http.MethodPost && len(path) > 12 && path[len(path)-11:] == "/deactivate" {
			channelAdapter.HandleDeactivateChannel(w, r)
			return
		}

		// Handle /channels/{id}/settings
		if method == http.MethodPut && len(path) > 10 && path[len(path)-9:] == "/settings" {
			channelAdapter.HandleUpdateChannelSettings(w, r)
			return
		}

		// Handle /channels/{id}
		switch method {
		case http.MethodGet:
			channelAdapter.HandleGetChannel(w, r)
		case http.MethodPut:
			channelAdapter.HandleUpdateChannelInfo(w, r)
		case http.MethodDelete:
			channelAdapter.HandleDeleteChannel(w, r)
		default:
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		}
	})

	// Create server
	srv := &http.Server{
		Addr:    ":8080",
		Handler: mux,
	}

	return srv
}

func main() {
	srv := setupServer()

	fmt.Println("Starting server on :8080")
	fmt.Println("Available endpoints:")
	fmt.Println("  GET /health")
	fmt.Println("  GET /calculator/add?a=<num>&b=<num>")
	fmt.Println("  GET /calculator/multiply?a=<num>&b=<num>")
	fmt.Println("  GET /text/reverse?text=<string>")
	fmt.Println("  GET /text/capitalize?text=<string>")
	fmt.Println("")
	fmt.Println("Channel API endpoints:")
	fmt.Println("  POST /channels                     - Create channel")
	fmt.Println("  GET  /channels                     - List channels")
	fmt.Println("  GET  /channels/{id}                - Get channel")
	fmt.Println("  PUT  /channels/{id}                - Update channel info")
	fmt.Println("  DELETE /channels/{id}              - Delete channel")
	fmt.Println("  PUT  /channels/{id}/settings       - Update channel settings")
	fmt.Println("  POST /channels/{id}/activate       - Activate channel")
	fmt.Println("  POST /channels/{id}/deactivate     - Deactivate channel")

	if err := srv.ListenAndServe(); err != nil {
		log.Fatal(err)
	}
}
