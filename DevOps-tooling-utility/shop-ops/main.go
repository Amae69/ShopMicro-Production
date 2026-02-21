package main

import (
	"fmt"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"time"
)

func main() {
	if len(os.Args) < 2 {
		printUsage()
		return
	}

	command := os.Args[1]

	switch command {
	case "validate":
		validateHealth()
	case "collect":
		collectEvidence()
	case "help":
		printUsage()
	default:
		fmt.Printf("Unknown command: %s\n", command)
		printUsage()
		os.Exit(1)
	}
}

func printUsage() {
	fmt.Println("Usage: shop-ops <command>")
	fmt.Println("\nCommands:")
	fmt.Println("  validate  Check the health of local services")
	fmt.Println("  collect   Collect logs and system state for grading")
	fmt.Println("  help      Show this help message")
}

func validateHealth() {
	services := map[string]string{
		"Frontend":   "http://localhost:3000",
		"Backend":    "http://localhost:3001",
		"ML Service": "http://localhost:5000",
	}

	fmt.Println("Checking environment health...")
	allPass := true

	for name, url := range services {
		client := http.Client{
			Timeout: 2 * time.Second,
		}
		resp, err := client.Get(url)
		if err != nil {
			fmt.Printf("[FAIL] %-12s: %v\n", name, err)
			allPass = false
			continue
		}
		resp.Body.Close()

		if resp.StatusCode >= 200 && resp.StatusCode < 400 {
			fmt.Printf("[PASS] %-12s: Status %d\n", name, resp.StatusCode)
		} else {
			fmt.Printf("[WARN] %-12s: Status %d\n", name, resp.StatusCode)
			allPass = false
		}
	}

	if allPass {
		fmt.Println("\nOverall Health: EXCELLENT")
	} else {
		fmt.Println("\nOverall Health: ISSUES DETECTED")
		os.Exit(1)
	}
}

func collectEvidence() {
	evidenceDir := "grading-evidence"
	err := os.MkdirAll(evidenceDir, 0755)
	if err != nil {
		fmt.Printf("Failed to create evidence directory: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("Collecting evidence into %s/...\n", evidenceDir)

	// 1. Capture Docker Compose Status
	runAndSave("docker-compose-ps.txt", "docker", "compose", "ps")

	// 2. Capture Docker Compose Logs
	runAndSave("docker-compose-logs.txt", "docker", "compose", "logs", "--no-color", "--tail", "100")

	// 3. Create a summary file
	summaryPath := filepath.Join(evidenceDir, "summary.txt")
	summaryFile, _ := os.Create(summaryPath)
	defer summaryFile.Close()

	fmt.Fprintf(summaryFile, "Captsone Project Evidence\n")
	fmt.Fprintf(summaryFile, "Timestamp: %s\n", time.Now().Format(time.RFC3339))
	fmt.Fprintf(summaryFile, "Hostname: %s\n", getHostname())

	fmt.Println("Evidence collection complete.")
}

func runAndSave(filename string, command string, args ...string) {
	evidenceDir := "grading-evidence"
	outputPath := filepath.Join(evidenceDir, filename)

	cmd := exec.Command(command, args...)
	output, err := cmd.CombinedOutput()

	f, createErr := os.Create(outputPath)
	if createErr != nil {
		fmt.Printf("Error creating file %s: %v\n", outputPath, createErr)
		return
	}
	defer f.Close()

	if err != nil {
		fmt.Fprintf(f, "[COMMAND FAILED: %v]\n", err)
	}
	f.Write(output)
	fmt.Printf("- Captured %s\n", filename)
}

func getHostname() string {
	name, err := os.Hostname()
	if err != nil {
		return "unknown"
	}
	return name
}
