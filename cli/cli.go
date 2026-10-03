package cli

import (
	"fmt"
	"os"

	"github.com/toki-voki/maestro/client"
	"github.com/toki-voki/maestro/server"
)

const badUsageExitCode = 2

func Run(args []string) int {
	args = args[1:]

	if len(args) == 0 {
		usage()
		return badUsageExitCode
	}

	switch args[0] {
	case "server":
		return runServer(args[1:])
	case "client":
		return runClient(args[1:])
	case "-h", "--help":
		usage()
		return 0
	default:
		fmt.Fprintf(os.Stderr, "[Maestro] Unknown command %q\n", args[0])
		usage()
		return badUsageExitCode
	}
}

func runServer(args []string) int {
	if len(args) == 0 {
		fmt.Fprintln(os.Stderr, "[Maestro] Missing server action.")
		usage()
		return badUsageExitCode
	}

	switch args[0] {
	case "start":
		return server.Start()
	case "stop":
		fmt.Fprintln(os.Stderr, "[Maestro] Server stop not implemented.")
		return 1
	default:
		fmt.Fprintf(os.Stderr, "[Maestro] Unknown command %q\n", args[0])
		usage()
		return badUsageExitCode
	}
}

func runClient(args []string) int {
	if len(args) == 0 {
		fmt.Fprintln(os.Stderr, "[Maestro] Missing client action.")
		usage()
		return badUsageExitCode
	}

	switch args[0] {
	case "start":
		return client.Start()
	default:
		fmt.Fprintf(os.Stderr, "[Maestro] Unknown command %q\n", args[0])
		usage()
		return badUsageExitCode
	}
}

func usage() {
	fmt.Fprint(os.Stderr, `
usage: maestro <command> <action>

commands:
	server start    start the server
	server stop     stop the running server
	client start    attach to the server
`)
}
