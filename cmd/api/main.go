package main

import (
	"fmt"
	"log"
	"net/http"

	calcAdapters "ssulmeta-go/internal/calculator/adapters"
	calcCore "ssulmeta-go/internal/calculator/core"
	healthAdapters "ssulmeta-go/internal/health/adapters"
	textAdapters "ssulmeta-go/internal/text/adapters"
	textCore "ssulmeta-go/internal/text/core"
)

func setupServer() *http.Server {
	// Create core services
	calculator := calcCore.NewCalculator()
	textProcessor := textCore.NewProcessor()

	// Create HTTP adapters
	calcAdapter := calcAdapters.NewHTTPAdapter(calculator)
	textAdapter := textAdapters.NewHTTPAdapter(textProcessor)

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

	if err := srv.ListenAndServe(); err != nil {
		log.Fatal(err)
	}
}
