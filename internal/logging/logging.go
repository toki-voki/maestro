package logging

import (
	"fmt"
	"log/slog"
	"os"
	"path/filepath"
	"strings"

	"gopkg.in/natefinch/lumberjack.v2"
)

const (
	maxFileSizeMB  = 10
	maxFileBackups = 3
)

type Config struct {
	Level slog.Level
	// File is the log file path; empty means DefaultPath(Name).
	File string
	// Name names the process ("server", "client") and its default log file,
	// so two processes never rotate the same file.
	Name string
	// Stderr also sends records to stderr, so a server running in a terminal
	// shows them live.
	Stderr bool
}

// File is the rotating log file behind a logger; Close it on exit.
type File struct {
	rotator *lumberjack.Logger
}

func (file *File) Close() error {
	return file.rotator.Close()
}

func New(config Config) (*slog.Logger, *File, error) {
	path := config.File
	if path == "" {
		var err error
		path, err = DefaultPath(config.Name)
		if err != nil {
			return nil, nil, err
		}
	}

	// lumberjack would create the directory as 0755; logs stay private.
	err := os.MkdirAll(filepath.Dir(path), 0o700)
	if err != nil {
		return nil, nil, fmt.Errorf("create log directory: %w", err)
	}

	rotator := &lumberjack.Logger{
		Filename:   path,
		MaxSize:    maxFileSizeMB,
		MaxBackups: maxFileBackups,
	}

	options := &slog.HandlerOptions{Level: config.Level}
	var handler slog.Handler = slog.NewTextHandler(rotator, options)
	if config.Stderr {
		handler = slog.NewMultiHandler(handler, slog.NewTextHandler(os.Stderr, options))
	}

	return slog.New(handler), &File{rotator: rotator}, nil
}

func ParseLevel(s string) (slog.Level, error) {
	switch strings.ToLower(s) {
	case "debug":
		return slog.LevelDebug, nil
	case "info":
		return slog.LevelInfo, nil
	case "warn":
		return slog.LevelWarn, nil
	case "error":
		return slog.LevelError, nil
	default:
		return 0, fmt.Errorf("unknown log level %q, want debug, info, warn or error", s)
	}
}

// DefaultPath is $XDG_STATE_HOME/maestro/<name>.log, with XDG_STATE_HOME
// falling back to ~/.local/state as the XDG spec says.
func DefaultPath(name string) (string, error) {
	dir := os.Getenv("XDG_STATE_HOME")
	if !filepath.IsAbs(dir) {
		home, err := os.UserHomeDir()
		if err != nil {
			return "", fmt.Errorf("find home directory: %w", err)
		}
		dir = filepath.Join(home, ".local", "state")
	}
	return filepath.Join(dir, "maestro", name+".log"), nil
}
