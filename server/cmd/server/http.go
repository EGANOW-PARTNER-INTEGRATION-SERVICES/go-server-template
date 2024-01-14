package server

import (
	"context"
	"fmt"
	"github.com/eganow/core/template/api/configs"
	"github.com/grpc-ecosystem/grpc-gateway/v2/runtime"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/protobuf/encoding/protojson"
	"log"
	"net"
	"net/http"
)

var (
	// dialOpts is a slice of grpc.DialOption (using insecure credentials)
	dialOpts = []grpc.DialOption{grpc.WithTransportCredentials(insecure.NewCredentials())}
)

// GatewayHttpServer is the http gateway server
type GatewayHttpServer struct {
	ctx context.Context
	cfg *configs.KeyStoreConfig
	GatewayServer
}

// NewHttpGatewayServer returns a new instance of the http gateway server
func NewHttpGatewayServer(ctx context.Context, cfg *configs.KeyStoreConfig) *GatewayHttpServer {
	// set the context to the background if it is nil
	if ctx == nil {
		ctx = context.Background()
	}

	return &GatewayHttpServer{ctx: ctx, cfg: cfg}
}

// Start starts the http gateway server
func (h *GatewayHttpServer) Start(opts ...ServiceRegistrationOption) error {
	var err error

	// Marshal JSON requests using `protojson` (maintain the naming format of proto messages)
	jsonOpts := runtime.WithMarshalerOption(
		runtime.MIMEWildcard,
		&runtime.JSONPb{
			MarshalOptions: protojson.MarshalOptions{
				UseProtoNames:  true,
				UseEnumNumbers: false,
			},
			UnmarshalOptions: protojson.UnmarshalOptions{
				DiscardUnknown: true,
			},
		},
	)

	// Register gRPC server endpoint
	grpcMux := runtime.NewServeMux(jsonOpts)

	// register services from the options
	for _, opt := range opts {
		if err = opt(nil, grpcMux); err != nil {
			return err
		}
	}

	// Create HTTP server that listens on a port and proxies requests to gRPC server endpoint
	httpMux := http.NewServeMux()
	httpMux.Handle("/", grpcMux)

	// create a listener for the HTTP server
	lis, err := net.Listen("tcp", fmt.Sprintf("%s:%s", h.cfg.HttpServerHost, h.cfg.HttpServerPort))
	if err != nil {
		log.Printf("failed to listen on HTTP server: %v", err)
		return err
	}

	// Start HTTP server (and proxy calls to gRPC server endpoint)
	log.Printf("Starting HTTP server on port %s", h.cfg.HttpServerPort)
	if err = http.Serve(lis, httpMux); err != nil {
		log.Printf("failed to start HTTP server: %v", err)
		return err
	}

	return err
}

// @todo -> implement services here
