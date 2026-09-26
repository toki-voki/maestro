package main

import (
	"os"

	"github.com/toki-voki/maestro/cli"
)

func main() {
	os.Exit(cli.Run(os.Args))
}
