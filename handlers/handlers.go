package handlers

import (
	"fmt"
	"net/http"
	"ssulmeta-go/utils"
	"strconv"
)

// HelloHandler returns a simple greeting message
func HelloHandler() string {
	return "Hello, World!"
}

// AddHandler simulates handling an addition request
func AddHandler(aStr, bStr string) (string, error) {
	a, err := strconv.Atoi(aStr)
	if err != nil {
		return "", fmt.Errorf("invalid parameter a: %v", err)
	}

	b, err := strconv.Atoi(bStr)
	if err != nil {
		return "", fmt.Errorf("invalid parameter b: %v", err)
	}

	result := utils.Add(a, b)
	return fmt.Sprintf("Result: %d", result), nil
}

// ReverseHandler simulates handling a string reverse request
func ReverseHandler(text string) string {
	if text == "" {
		return "No text provided"
	}
	return utils.ReverseString(text)
}

// HealthCheckHandler simulates a health check endpoint
func HealthCheckHandler() (int, string) {
	return http.StatusOK, "Service is healthy"
}
