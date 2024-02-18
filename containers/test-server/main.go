package main

import (
	"encoding/json"
	"flag"
	"log/slog"
	"net"
	"net/http"
	"time"
)

var (
	listen = flag.String("listen", ":8080", "Server listening address and port")
)

type Response struct {
	Timestamp time.Time `json:"timestamp"`
	From      string    `json:"from"`
	To        string    `json:"to"`
}

func getLocalAddr() string {
	addrs, err := net.InterfaceAddrs()
	if err != nil {
		panic(err)
	}
	for _, addr := range addrs {
		if ipnet, ok := addr.(*net.IPNet); ok && !ipnet.IP.IsLoopback() {
			if ipnet.IP.To4() != nil {
				return ipnet.IP.String()
			}
		}
	}
	return "unknown"
}

func main() {
	flag.Parse()
	slog.SetDefault(slog.Default())

	mux := http.NewServeMux()

	localAddr := getLocalAddr()

	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		resp := Response{
			Timestamp: time.Now(),
			To:        r.RemoteAddr,
			From:      localAddr,
		}

		buf, err := json.Marshal(resp)
		if err != nil {
			w.WriteHeader(http.StatusInternalServerError)
			w.Write([]byte("Failed to marshal response"))
			return
		}
		slog.Info("Send response", slog.String("To", r.RemoteAddr), slog.String("From", localAddr))
		w.Write(buf)
	})
	slog.Info("Test server is running at", slog.String("Host", *listen))

	server := http.Server{
		Addr:    *listen,
		Handler: mux,
	}

	if err := server.ListenAndServe(); err != nil {
		slog.Error("Failed to start HTTP server", slog.Any("error", err))
	}
}
