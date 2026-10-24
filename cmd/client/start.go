package client

import (
	"flag"

	"github.com/toki-voki/maestro/internal/client"
)

func runStart(args []string) int {
	flags := flag.NewFlagSet("maestro client start", flag.ExitOnError)
	_ = flags.Parse(args) // ExitOnError exits 0 on -h and 2 on a bad flag, so the error is always nil

	return client.Start()
}
