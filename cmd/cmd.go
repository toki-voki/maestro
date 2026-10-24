package cmd

import (
	"fmt"
	"os"

	"github.com/toki-voki/maestro/cmd/client"
	"github.com/toki-voki/maestro/cmd/server"
)

const badUsageExitCode = 2

func Run(args []string) int {
	if len(args) == 0 {
		usage()
		return badUsageExitCode
	}

	switch args[0] {
	case "server":
		return server.Run(args[1:])
	case "client":
		return client.Run(args[1:])
	case "version", "-v", "--version":
		return runVersion()
	case "-h", "--help":
		usage()
		return 0
	default:
		fmt.Fprintf(os.Stderr, "[Maestro] Unknown command %q\n", args[0])
		usage()
		return badUsageExitCode
	}
}

func usage() {
	fmt.Fprint(os.Stderr, `
usage: maestro <command> [<action>] [flags]

commands:
	server start    start the server
	server stop     stop the running server
	client start    attach to the server
	version         print version

Run "maestro <command> -h" for help on a command.
`)
}
