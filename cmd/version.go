package cmd

import "fmt"

// version is set at build time via -ldflags "-X github.com/toki-voki/maestro/cmd.version=...".
var version = "dev"

func runVersion() int {
	fmt.Println("maestro " + version)
	return 0
}
