package client

import (
	"fmt"
	"log/slog"
)

func Start(logger *slog.Logger) int {
	logger.Info("client starting")
	fmt.Println("maestro client starting...")
	return 0
}
