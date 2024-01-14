package main

import (
	"context"
	"github.com/eganow/core/template/api/cmd/server"
	"github.com/eganow/core/template/api/cmd/server/grpc"
	"github.com/eganow/core/template/api/internal"
	"log"
)

// reference: https://github.com/grpc-ecosystem/grpc-gateway?tab=readme-ov-file
func main() {

	// Initialize dependencies
	if err := internal.InitializeDependencies(); err != nil {
		log.Fatalf("failed to initialize dependencies: %v", err)
	}

	// Close databases
	defer internal.CloseDatabases()

	// Start gRPC server in a goroutine
	go startGrpcServer()

	// Start HTTP server on main thread
	startHttpGatewayServer()
}

// startGrpcServer starts the gRPC server
func startGrpcServer() {
	// create the grpc server
	grpcServer := grpc.NewGrpcServer()

	// stop the gRPC server when the function returns
	defer func(grpcServer *grpc.GatewayGrpcServer) {
		_ = grpcServer.Stop()
	}(grpcServer)

	// start the gRPC server
	if err := grpcServer.Start(server.RegisterServices(grpcServer)...); err != nil {
		log.Fatalf("failed to start grpc server: %v", err)
	}

}

// startHttpGatewayServer starts the http gateway server
func startHttpGatewayServer() {
	// create context
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// create the http gateway server
	httpServer := server.NewHttpGatewayServer(ctx, internal.ConfigInjector.KeyStoreConfig)

	// stop the http gateway server when the function returns
	defer func(httpServer *server.GatewayHttpServer) {
		_ = httpServer.Stop()
	}(httpServer)

	// start the http gateway server
	if err := httpServer.Start(server.RegisterServices(httpServer)...); err != nil {
		log.Fatalf("failed to start http gateway server: %v", err)
	}
}
