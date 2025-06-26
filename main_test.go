package main

import (
	"os"
	"os/exec"
	"strings"
	"testing"
)

// TestMainExecution tests that main runs without errors
func TestMainExecution(t *testing.T) {
	cmd := exec.Command("go", "run", "main.go")
	output, err := cmd.CombinedOutput()
	
	if err != nil {
		t.Fatalf("main.go execution failed: %v\nOutput: %s", err, output)
	}
	
	outputStr := string(output)
	expectedContents := []string{
		"Hello, World!",
		"Add(5, 3) = 8",
		"Reverse('hello') = olleh",
		"Result: 30",
		"Health Check [200]: Service is healthy",
	}
	
	for _, expected := range expectedContents {
		if !strings.Contains(outputStr, expected) {
			t.Errorf("Expected output to contain %q, got:\n%s", expected, outputStr)
		}
	}
}

// TestMainCompiles tests that the main package compiles successfully
func TestMainCompiles(t *testing.T) {
	cmd := exec.Command("go", "build", "-o", "/tmp/ssulmeta-go-test", ".")
	err := cmd.Run()
	
	if err != nil {
		t.Fatalf("main package compilation failed: %v", err)
	}
	
	// Clean up the test binary
	os.Remove("/tmp/ssulmeta-go-test") // nolint: errcheck
}