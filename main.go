package main

import (
	"fmt"
	"ssulmeta-go/handlers"
	"ssulmeta-go/utils"
)

func main() {
	// Demonstrate handlers
	fmt.Println(handlers.HelloHandler())

	// Demonstrate utils
	fmt.Printf("Add(5, 3) = %d\n", utils.Add(5, 3))
	fmt.Printf("Reverse('hello') = %s\n", utils.ReverseString("hello"))

	// Demonstrate handlers with utils
	result, err := handlers.AddHandler("10", "20")
	if err != nil {
		fmt.Printf("Error: %v\n", err)
	} else {
		fmt.Println(result)
	}

	// Health check
	status, message := handlers.HealthCheckHandler()
	fmt.Printf("Health Check [%d]: %s\n", status, message)
}
