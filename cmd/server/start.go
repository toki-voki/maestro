package server

import (
	"cmp"
	"flag"
	"fmt"
	"os"

	"github.com/toki-voki/maestro/internal/logging"
	"github.com/toki-voki/maestro/internal/server"
)

func runStart(args []string) int {
	flags := flag.NewFlagSet("maestro server start", flag.ExitOnError)
	logLevel := flags.String("log-level", cmp.Or(os.Getenv("MAESTRO_LOG_LEVEL"), "info"),
		"log level: debug, info, warn or error (env MAESTRO_LOG_LEVEL)")
	logPath := flags.String("log-file", os.Getenv("MAESTRO_SERVER_LOG_FILE"),
		"log file (env MAESTRO_SERVER_LOG_FILE, default $XDG_STATE_HOME/maestro/server.log)")
	_ = flags.Parse(args) // ExitOnError exits 0 on -h and 2 on a bad flag, so the error is always nil

	level, err := logging.ParseLevel(*logLevel)
	if err != nil {
		fmt.Fprintf(os.Stderr, "[Maestro] Invalid --log-level. [error=%v]\n", err)
		return badUsageExitCode
	}
	logger, logFile, err := logging.New(logging.Config{Level: level, File: *logPath, Name: "server", Stderr: true})
	if err != nil {
		fmt.Fprintf(os.Stderr, "[Maestro] Failed to set up logging. [error=%v]\n", err)
		return 1
	}
	defer logFile.Close()

	return server.Start(logger)
}
