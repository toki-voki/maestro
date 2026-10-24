package server

import (
	"fmt"
	"os"
)

const badUsageExitCode = 2

func Run(args []string) int {
	if len(args) == 0 {
		fmt.Fprintln(os.Stderr, "[Maestro] Missing server action.")
		usage()
		return badUsageExitCode
	}

	switch args[0] {
	case "start":
		return runStart(args[1:])
	case "stop":
		return runStop(args[1:])
	case "-h", "--help":
		usage()
		return 0
	default:
		fmt.Fprintf(os.Stderr, "[Maestro] Unknown server action %q\n", args[0])
		usage()
		return badUsageExitCode
	}
}

func usage() {
	fmt.Fprint(os.Stderr, `
usage: maestro server <action> [flags]

actions:
	start    start the server
	stop     stop the running server
`)
}
