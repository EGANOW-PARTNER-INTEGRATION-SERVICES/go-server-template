package grpc

import (
	"fmt"
	"github.com/eganow/core/template/api/cmd/server"
	"github.com/eganow/core/template/api/cmd/server/grpc/interceptor"
	"github.com/eganow/core/template/api/internal"
	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"
	"log"
	"net"
)

// GatewayGrpcServer is the grpc server
type GatewayGrpcServer struct {
	srv *grpc.Server
	server.GatewayServer
}

// NewGrpcServer returns a new instance of the grpc server
func NewGrpcServer() *GatewayGrpcServer {
	return &GatewayGrpcServer{}
}

// Start starts the grpc server
func (g *GatewayGrpcServer) Start(opts ...server.ServiceRegistrationOption) error {
	var err error

	// create the grpc server
	g.srv = grpc.NewServer(
		grpc.UnaryInterceptor(interceptor.LoggingUnaryInterceptor),
		grpc.StreamInterceptor(interceptor.LoggingStreamInterceptor),
	)

	// enable reflection
	reflection.Register(g.srv)

	// register services from the options
	for _, opt := range opts {
		if err = opt(g.srv, nil); err != nil {
			return err
		}
	}

	// get keystore config
	cfg := internal.ConfigInjector.KeyStoreConfig

	// set up the listener for the gRPC server
	lis, err := net.Listen("tcp", fmt.Sprintf("%s:%s", cfg.GrpcServerHost, cfg.GrpcServerPort))
	if err != nil {
		log.Printf("failed to listen on gRPC server: %v", err)
		return err
	}

	// Start the gRPC server
	log.Printf("Starting gRPC server on port %s", cfg.GrpcServerPort)
	if err = g.srv.Serve(lis); err != nil {
		log.Printf("failed to start gRPC server: %v", err)
	}

	return err
}

// Stop stops the grpc server
func (g *GatewayGrpcServer) Stop() error {
	log.Println("Stopping gRPC server")
	g.srv.GracefulStop()
	return nil
}

// @todo -> implement services here
