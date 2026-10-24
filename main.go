package main

import (
	"os"

	"github.com/toki-voki/maestro/cmd"
)

func main() {
	os.Exit(cmd.Run(os.Args[1:]))
}
