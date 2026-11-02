package server

import (
	"errors"
	"fmt"
	"io"
	"log/slog"
	"net"
	"os"
	"path/filepath"
	"sync"
)

type Hub struct {
	path      string
	listener  net.Listener
	mu        sync.Mutex
	clients   map[int]*Client
	nextID    int
	closeOnce sync.Once
	logger    *slog.Logger
}

type Client struct {
	id         int
	connection net.Conn
}

func NewHub(path string, logger *slog.Logger) (*Hub, error) {
	err := os.MkdirAll(filepath.Dir(path), 0o700)
	if err != nil {
		return nil, fmt.Errorf("[Hub] Failed to create socket directory. [error=%w]", err)
	}

	// A running server answers on its socket; a file left behind by a crashed
	// server doesn't. Only remove the file when nobody answers.
	connection, dialError := net.Dial("unix", path)
	if dialError == nil {
		connection.Close()
		return nil, fmt.Errorf("[Hub] Server already running on %s", path)
	}

	err = os.Remove(path)
	if err != nil && !errors.Is(err, os.ErrNotExist) {
		return nil, fmt.Errorf("[Hub] Failed to remove old socket file. [error=%w]", err)
	}

	listener, err := net.Listen("unix", path)
	if err != nil {
		return nil, fmt.Errorf("[Hub] Failed to create a listener for unix socket. [error=%w]", err)
	}

	return &Hub{
		path:     path,
		listener: listener,
		clients:  make(map[int]*Client),
		logger:   logger.With("component", "hub"),
	}, nil
}

func (hub *Hub) Serve() error {
	for {
		conn, err := hub.listener.Accept()
		if err != nil {
			if errors.Is(err, net.ErrClosed) {
				return nil
			}
			return err
		}
		go hub.handle(conn)
	}
}

func (hub *Hub) Close() error {
	var err error
	hub.closeOnce.Do(func() {
		var errs []error

		removeErr := os.Remove(hub.path)
		if removeErr != nil && !errors.Is(removeErr, os.ErrNotExist) {
			errs = append(errs, fmt.Errorf("[Hub] Failed to close hub, failed to remove socket file. [error=%w]", removeErr))
		}

		closeListenerError := hub.listener.Close()
		if closeListenerError != nil {
			errs = append(errs, fmt.Errorf("[Hub] Failed to close hub, failed to close listener. [error=%w]", closeListenerError))
		}

		hub.mu.Lock()
		for _, client := range hub.clients {
			client.connection.Close()
		}
		hub.mu.Unlock()

		err = errors.Join(errs...)
	})
	return err
}

func (hub *Hub) handle(connection net.Conn) {
	client := hub.add(connection)
	hub.logger.Info("client attached", "client", client.id)

	defer func() {
		hub.remove(client)
		connection.Close()
		hub.logger.Info("client detached", "client", client.id)
	}()

	buffer := make([]byte, 4096)
	for {
		readBytes, err := connection.Read(buffer)
		if readBytes > 0 {
			hub.logger.Debug("client sent", "client", client.id, "bytes", readBytes, "data", string(buffer[:readBytes]))
		}
		if err != nil {
			if !errors.Is(err, io.EOF) && !errors.Is(err, net.ErrClosed) {
				hub.logger.Error("read from client", "client", client.id, "err", err)
			}
			return
		}
	}
}

func (hub *Hub) add(connection net.Conn) *Client {
	hub.mu.Lock()
	defer hub.mu.Unlock()
	hub.nextID++
	client := &Client{id: hub.nextID, connection: connection}
	hub.clients[client.id] = client
	return client
}

func (hub *Hub) remove(client *Client) {
	hub.mu.Lock()
	defer hub.mu.Unlock()
	delete(hub.clients, client.id)
}
