package server

import (
	"fmt"
	"os"
	"os/signal"
	"path/filepath"
	"syscall"
)

func Start() int {
	fmt.Println("[Server] Maestro server starting...")

	socketFilePath := defaultSocketFilePath()
	hub, err := NewHub(socketFilePath)
	if err != nil {
		fmt.Fprintf(os.Stderr, "[Server] Failed to start the hub. [error=%v]\n", err)
		return 1
	}

	sig := make(chan os.Signal, 1)
	signal.Notify(sig, os.Interrupt, syscall.SIGTERM)
	go func() {
		<-sig
		closeError := hub.Close()
		if closeError != nil {
			fmt.Fprintf(os.Stderr, "[Server] Failed to close the hub. [error=%v]\n", closeError)
		}
	}()

	fmt.Printf("[Server] Maestro server listening on %s\n", socketFilePath)

	err = hub.Serve()
	if err != nil {
		fmt.Fprintf(os.Stderr, "[Server] Hub failed to serve. [error=%v]\n", err)
		closeError := hub.Close()
		if closeError != nil {
			fmt.Fprintf(os.Stderr, "[Server] Failed to close the hub. [error=%v]\n", closeError)
		}
		return 1
	}

	fmt.Printf("[Server] Maestro server stopped\n")
	return 0
}

func defaultSocketFilePath() string {
	return filepath.Join("/tmp", fmt.Sprintf("maestro-%d", os.Getuid()), "default.sock")
}
