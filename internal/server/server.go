package server

import (
	"fmt"
	"log/slog"
	"os"
	"os/signal"
	"path/filepath"
	"syscall"
)

func Start(logger *slog.Logger) int {
	logger.Info("server starting")

	socketFilePath := defaultSocketFilePath()
	hub, err := NewHub(socketFilePath, logger)
	if err != nil {
		logger.Error("start hub", "err", err)
		return 1
	}

	sig := make(chan os.Signal, 1)
	signal.Notify(sig, os.Interrupt, syscall.SIGTERM)
	go func() {
		<-sig
		closeError := hub.Close()
		if closeError != nil {
			logger.Error("close hub", "err", closeError)
		}
	}()

	logger.Info("server listening", "socket", socketFilePath)

	err = hub.Serve()
	if err != nil {
		logger.Error("serve hub", "err", err)
		closeError := hub.Close()
		if closeError != nil {
			logger.Error("close hub", "err", closeError)
		}
		return 1
	}

	logger.Info("server stopped")
	return 0
}

func defaultSocketFilePath() string {
	return filepath.Join("/tmp", fmt.Sprintf("maestro-%d", os.Getuid()), "default.sock")
}
