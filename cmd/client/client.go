package client

import (
	"fmt"
	"os"
)

const badUsageExitCode = 2

func Run(args []string) int {
	if len(args) == 0 {
		fmt.Fprintln(os.Stderr, "[Maestro] Missing client action.")
		usage()
		return badUsageExitCode
	}

	switch args[0] {
	case "start":
		return runStart(args[1:])
	case "-h", "--help":
		usage()
		return 0
	default:
		fmt.Fprintf(os.Stderr, "[Maestro] Unknown client action %q\n", args[0])
		usage()
		return badUsageExitCode
	}
}

func usage() {
	fmt.Fprint(os.Stderr, `
usage: maestro client <action> [flags]

actions:
	start    attach to the server
`)
}
