package server

import (
	"flag"
	"fmt"
	"os"
)

func runStop(args []string) int {
	flags := flag.NewFlagSet("maestro server stop", flag.ExitOnError)
	_ = flags.Parse(args) // ExitOnError exits 0 on -h and 2 on a bad flag, so the error is always nil

	fmt.Fprintln(os.Stderr, "[Maestro] Server stop not implemented.")
	return 1
}
