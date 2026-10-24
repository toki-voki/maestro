package server

import (
	"flag"

	"github.com/toki-voki/maestro/internal/server"
)

func runStart(args []string) int {
	flags := flag.NewFlagSet("maestro server start", flag.ExitOnError)
	_ = flags.Parse(args) // ExitOnError exits 0 on -h and 2 on a bad flag, so the error is always nil

	return server.Start()
}
