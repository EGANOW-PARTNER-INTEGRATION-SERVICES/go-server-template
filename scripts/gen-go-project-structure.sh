    #!/bin/bash

# Check if no arguments were given
if [ $# -eq 0 ]; then
    # Use the current directory name as the project name
    project_root=$(basename "$(pwd)")
    # Set a flag indicating a default feature should be created
    create_default_feature=true
else
    # The root directory for the project, taken from the first argument
    project_root=$1
    # Shift the positional parameters to the left to skip the first argument (project name)
    shift
    # Set flag indicating default feature should not be created
    create_default_feature=false
fi


#base import
base_import_path="github.com/eganow/core/$project_root/api"

# The 'server' subdirectory
  server_root="$project_root/server"

# Create base project structure
create_base_structure() {

  mkdir -p "server_root/cmd/server"
  mkdir -p "$server_root/cmd/server/grpc"
  mkdir -p "$server_root/cmd/server/grpc/interceptor"
  touch "$server_root/cmd/server/grpc/interceptor/logging.go"
  echo "package interceptor" > "$server_root/cmd/server/grpc/interceptor/logging.go"
  touch "$server_root/cmd/main.go"
  touch "$server_root/cmd/server/grpc/server.go"
  touch "$server_root/cmd/server/http.go"
  touch "$server_root/cmd/server/server_options.go"

  mkdir -p "$server_root/database"
  mkdir -p "$server_root/configs"
  touch "$server_root/configs/.env"



  mkdir -p "$server_root/internal"
  touch "$server_root/internal/injector.go"


  mkdir -p "$project_root/protos"
  mkdir -p "$project_root/devops"
  mkdir -p "$project_root/devops/docker"
  mkdir -p "$project_root/devops/k8s"
  touch "$project_root/devops/k8s/deployment.yaml"
  mkdir -p "$project_root/protos/eganow/api"
  mkdir -p "$project_root/protos/google/api"
  touch "$project_root/protos/eganow/api/common.proto"

  mkdir -p "$project_root/scripts"
  touch "$project_root/scripts/gen-protos.sh"

  mkdir -p "$server_root/bin"

  mkdir -p "$server_root/cert"


  touch "$server_root/.gitignore"
  touch "$project_root/Makefile"
  touch "$server_root/README.md"
  touch "$project_root/devops/docker/Dockerfile"

  mkdir -p "$server_root/.github/workflows"
  echo "#CI/CD workflow and other GitHub configurations" > "$server_root/.github/workflows/ci.yaml"
}


# Function to create feature structure
create_feature_structure() {
  feature_root="$server_root/features/$1"

  # Define directories to be created
  declare -a directories=(
    "$feature_root/business_logic/app"
    "$feature_root/business_logic/services"
    "$feature_root/di"
    "$feature_root/pkg"
  )

  # Create directories
  for dir in "${directories[@]}"; do
    mkdir -p "$dir"
  done

  # Define file paths and contents
  declare -a files=(
    "$feature_root/business_logic/app/use_case.go|package app"
    "$feature_root/business_logic/app/data_source.go|package app"
    "$feature_root/business_logic/app/repository.go|package app"
    "$feature_root/business_logic/services/grpc.go|package service"
    "$feature_root/di/injector.go|package di"
    "$feature_root/pkg/repository.go|package pkg"
    "$feature_root/pkg/data_source.go|package pkg"
  )

  # Create files with content
  for file in "${files[@]}"; do
    IFS='|' read -r path content <<< "$file"
    echo "$content" > "$path"
  done
}


# Function to create common feature structure
create_common_feature_structure() {
  common_root="$project_root/server/features/common"
  mkdir -p "$common_root/proto_gen"
  mkdir -p "$common_root/utils"
  touch "$common_root/utils/validators.go"
}



# Protobuf generation script
generate_protobuf_script() {
  echo "Generating protobuf script..."

  # Ensure the scripts directory exists
  mkdir -p "$project_root/scripts"

  # Write the script content to 'gen-protos.sh'
  cat << EOF > "$project_root/scripts/gen-protos.sh"
# Description: Generate the protobuf files

# variables
PROTO_PATH=protos
OUR_DIR=server/features/common/proto_gen

# create the gen directory
mkdir -p "\$OUR_DIR"
mkdir -p "\$OUR_DIR/openapi"

# remove the old generated files
rm -rf "\$OUR_DIR"/*.go
rm -rf "\$OUR_DIR"/openapi/*.json

# generate the new files
protoc -I="\$PROTO_PATH" --go_out="\$OUR_DIR" --go_opt=paths=source_relative \
  --go-grpc_out="\$OUR_DIR" --go-grpc_opt=paths=source_relative \
  --grpc-gateway_opt=paths=source_relative \
  --grpc-gateway_out="\$OUR_DIR" \
  --openapiv2_out="\$OUR_DIR/openapi" \
  \$(find "\$PROTO_PATH" -name '*.proto')
EOF

  # Make the new script executable
  chmod +x "$project_root/scripts/gen-protos.sh"
}


# Populate Dockerfile
populate_dockerfile() {
  echo "Populating Dockerfile..."
  cat << EOF > "$project_root/devops/docker/Dockerfile"
# stage 1: build stage
FROM golang:1.21-rc-alpine3.18 AS builder

# optional authors information
LABEL authors="eganow"

# Install git and ca-certificates (needed to be able to call HTTPS)
RUN apk --update add ca-certificates git

# Move to working directory /app
WORKDIR /app

# Copy the code into the container
COPY /server .

# Build the application's binary
RUN go build -o main cmd/main.go


# stage 2: run stage
FROM alpine:latest

# Move to working directory /app
WORKDIR /app

# Copy the code into the container from builder
COPY --from=builder /app/main .
COPY --from=builder /app/configs/.env ./configs/.env

# expose ports
EXPOSE 9900 50051

# Command to run the application when starting the container
CMD ["/app/main"]
EOF
}

# Populate .gitignore
populate_gitignore() {
  echo "Populating .gitignore..."
  cat << EOF > "$server_root/.gitignore"
# # Binaries for programs and plugins
# *.exe
# *.exe~
# *.dll
# *.so
# *.dylib
# # Test binary, built with "go test -c"
# *.test
# # Output of the go coverage tool, specifically when used with LiteIDE
# *.out
# # Go workspace file
# go.work
# .idea/
# **/.env
# bin/
EOF
}


# Populate docker-compose
populate_docker_compose() {
  echo "Populating docker-compose..."
  cat << EOF > "$project_root/devops/docker/compose.yaml"
# This is a Docker Compose file for the 'sampler-server' project.
version: '3.8'  # The version of Docker Compose to use.

# The name of the project.
name: sampler-server

# The services that make up the project.
services:
  # The Microsoft SQL Server service.
  mssql-server:
    image: mcr.microsoft.com/mssql/server:2022-latest  # The Docker image to use.
    container_name: mssql-server  # The name of the container.
    environment: # Environment variables for the container.
      - ACCEPT_EULA=Y  # Accept the End User License Agreement.
      - SA_PASSWORD=Password123  # The password for the 'sa' user.
    ports: # The ports to expose.
      - "1433:1433"  # Expose port 1433.
    volumes: # The volumes to mount.
      - ./data:/var/opt/mssql/data  # Mount the './data' directory to '/var/opt/mssql/data' in the container.

  # The API Gateway service.
  api-gateway:
    image: eganowdevteam/sampler-go-grpc-http-gateway-server:latest  # The Docker image to use.
    container_name: api-gateway  # The name of the container.
    build: # The build context for the Docker image.
      context: /server/devops  # The build context directory.
      dockerfile: Dockerfile  # The Dockerfile to use.
    ports: # The ports to expose.
      - "9900:9900"  # Expose http port 9900.
      - "50051:50051"  # Expose gRPC port 50051.
    depends_on: # The services this service depends on.
      - mssql-server  # This service depends on the 'mssql-server' service.
    environment: # Environment variables for the container.
      - DB_CONN_URL=sqlserver://sa:Password123@mssql-server:1433?database=sampler_test_db&connection+timeout=30&encrypt=disable&trustservercertificate=true
      - DB_HOST=mssql-server  # The host of the database.
      - DB_PORT=1433  # The port of the database.
      - DB_USER=sa  # The user for the database.
      - DB_PASSWORD=Password123  # The password for the database.
      - DB_NAME=sampler_test_db  # The name of the database.
      - DB_DRIVER=sqlserver  # The driver for the database.
      - DB_SSL_MODE=disable  # The SSL mode for the database.
      - DB_MAX_IDLE_CONNS=10  # The maximum number of idle connections for the database.
      - DB_MAX_OPEN_CONNS=100  # The maximum number of open connections for the database.
      - DB_CONN_MAX_LIFETIME=30  # The maximum lifetime of a connection for the database.
      - DB_CONN_MAX_IDLE_TIME=5  # The maximum idle time of a connection for the database.
EOF
}


# Populate docker-compose
populate_k8s_files() {
  echo "Populating k8 files..."
  cat << EOF > "$project_root/devops/k8s/deployment.yaml"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mssql
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mssql-deployment
  template:
    metadata:
      labels:
        app: mssql-deployment
    spec:
      containers:
        - env:
            - name: ACCEPT_EULA
              value: 'Y'
            - name: MSSQL_SA_PASSWORD
              valueFrom:
                secretKeyRef:
                  key: SA_PASSWORD
                  name: mssql
          image: mcr.microsoft.com/mssql/server:2022-latest
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: 1433
          volumeMounts:
            - mountPath: /var/opt/mssql
              name: mssql-storage
          name: mssqldb
      volumes:
        - name: mssql-storage
          persistentVolumeClaim:
            claimName: mssql-pv-claim
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gateway-server
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: gateway-deployment
  template:
    metadata:
      labels:
        app: gateway-deployment
    spec:
      containers:
        - env:
            - name: DB_CONN_URL
              valueFrom:
                secretKeyRef:
                  key: DB_CONN_URL
                  name: mssql
            - name: DB_HOST
              value: localhost
            - name: DB_PORT
              value: '1433'
            - name: DB_USER
              value: sa
            - name: DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  key: SA_PASSWORD
                  name: mssql
            - name: DB_NAME
              value: master
            - name: DB_DRIVER
              value: sqlserver
            - name: DB_SSL_MODE
              value: disable
            - name: DB_MAX_IDLE_CONNS
              value: '10'
            - name: DB_MAX_OPEN_CONNS
              value: '100'
            - name: DB_CONN_MAX_LIFETIME
              value: '30'
            - name: DB_CONN_MAX_IDLE_TIME
              value: '5'
          image: eganowdevteam/sampler-go-grpc-http-gateway-server:latest
          imagePullPolicy: Never
          ports:
            - containerPort: 9900
            - containerPort: 50051
          name: server
EOF

cat << EOF > "$project_root/devops/k8s/persistent_volume.yaml"
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mssql-pv
spec:
  capacity:
    storage: 10Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: standard
  hostPath:
    path: "/mnt/data"
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mssql-pv-claim
spec:
  storageClassName: standard
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
EOF

cat << EOF > "$project_root/devops/k8s/secret.yaml"
apiVersion: v1
kind: Secret
metadata:
  name: mssql
type: Opaque
data:
  SA_PASSWORD: UGFzc3dvcmQxMjM=
  DB_CONN_URL: c3Fsc2VydmVyOi8vc2E6UGFzc3dvcmQxMjNAbG9jYWxob3N0OjE0MzM/ZGF0YWJhc2U9bWFzdGVyJmNvbm5lY3Rpb24rdGltZW91dD0zMCZlbmNyeXB0PWRpc2FibGUmdHJ1c3RzZXJ2ZXJjZXJ0aWZpY2F0ZT10cnVl
EOF

cat << EOF > "$project_root/devops/k8s/service.yaml"
apiVersion: v1
kind: Service
metadata:
  name: mssql-service
  labels:
    app: mssql-service
spec:
  selector:
    app: mssql-deployment
  ports:
    - protocol: TCP
      port: 1433
      targetPort: 1433
  type: ClusterIP
---
apiVersion: v1
kind: Service
metadata:
  name: server-service
  labels:
    app: gateway-server
spec:
  selector:
    app: gateway-deployment
  ports:
    - protocol: TCP
      name: http
      port: 9900
      targetPort: 9900
    - protocol: TCP
      name: grpc
      port: 50051
      targetPort: 50051
  type: ClusterIP
EOF

}

# Populate Makefile
# Populate Makefile
populate_makefile() {
  echo "Populating Makefile..."
  cat << 'EOF' > "$project_root/Makefile"
# Variable for server root
server_root := ./server

build-binary:
	@echo "building binary..." && \
	rm -rf ./bin && \
	mkdir -p ./bin && \
	go build -o ./bin/sampler-go-grpc-http-gateway-server ./cmd/main.go

# replace with the actual proto repo url (https://github.com/username/repo.git)
add-protos-submodule:
	@git submodule add --progress --force https://github.com/username/repo.git protobufs

update-protos-submodule:
	@git submodule update --init --recursive  --remote

gen-protos: add-protos-submodule update-protos-submodule
	@chmod +x gen-protos.sh && ./gen-protos.sh

install-gateway-deps:
	go install github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-grpc-gateway \
        github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-openapiv2 \
        google.golang.org/protobuf/cmd/protoc-gen-go \
        google.golang.org/grpc/cmd/protoc-gen-go-grpc

build-docker:
	@echo "building docker image..." && \
	cd server && \
	docker buildx build --platform linux/amd64 -t eganowdevteam/sampler-go-grpc-http-gateway-server:latest .

start-docker-services:
	@echo "starting docker services..." && \
	docker-compose -f server/devops/docker/compose.yaml up -d

apply-k8s:
	@echo "applying k8s resources..." && \
	kubectl apply -f server/devops/k8s -R

# Makefile target for creating feature structure
feature:
	@$(foreach feature,$(filter-out $@,$(MAKECMDGOALS)), $(MAKE) create_feature_structure FEATURE_NAME=$(feature);)

# Function to create feature structure for each feature
create_feature_structure:
	@$(eval feature_root=$(server_root)/features/$(FEATURE_NAME))
	@echo "Creating feature structure in $(feature_root)"

	# Define directories to be created
	@$(eval directories := \
		"$(feature_root)/business_logic/app/repository/models" \
		"$(feature_root)/business_logic/services" \
		"$(feature_root)/di" \
		"$(feature_root)/pkg" \
	)

	# Create directories
	@$(foreach dir,$(directories),mkdir -p "$(dir)";)

	# Define file paths and contents
	@$(eval files := \
		"$(feature_root)/business_logic/app/use_case.go|package app" \
		"$(feature_root)/business_logic/app/data_source.go|package app" \
		"$(feature_root)/business_logic/app/repository/noop.go|package repository" \
		"$(feature_root)/business_logic/services/grpc.go|package service" \
		"$(feature_root)/di/injector.go|package di" \
		"$(feature_root)/pkg/repository.go|package pkg" \
		"$(feature_root)/pkg/data_source.go|package pkg" \
	)

	# Create files with content using a shell loop
	@for file in $(files); do \
		path=$$(echo "$$file" | cut -d'|' -f1); \
		content=$$(echo "$$file" | cut -d'|' -f2); \
		echo "Creating file $$path with content: $$content"; \
		echo "$$content" > "$$path"; \
	done

# Trick to allow passing arguments to a target
%:
	@:

.PHONY: gen-protos install-gateway-deps build-binary build-docker start-docker-services apply-k8s feature

EOF
}



# Populate main.go
populate_main_go() {
  # Construct the dynamic part of the import path with the given project name


  echo "Populating main.go with dynamic project name..."
  cat << EOF > "$server_root/cmd/main.go"

package main

import (
	"context"
	"$base_import_path/cmd/server"
	"$base_import_path/cmd/server/grpc"
	"$base_import_path/internal"
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

	// set up options for service registration(s)
	opts := []server.ServiceRegistrationOption{
		//grpcServer.WithSvcServer(),
		// @todo: add more services here
	}

// stop the gRPC server when the function returns
	defer func(grpcServer *grpc.GatewayGrpcServer) {
		_ = grpcServer.Stop()
	}(grpcServer)

	// start the gRPC server
	if err := grpcServer.Start(opts...); err != nil {
		log.Fatalf("failed to start grpc server: %v", err)
	}

}

// startHttpGatewayServer starts the http gateway server
func startHttpGatewayServer() {
	// create context
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// create the http gateway server
	httpServer := server.NewHttpGatewayServer(ctx)

	// set up options for service registration(s)
	opts := []server.ServiceRegistrationOption{
		// httpServer.WithSvcServer(),
		// @todo: add more services here
	}

	// stop the http gateway server when the function returns
	defer func(httpServer *server.HttpGatewayServer) {
		_ = httpServer.Stop()
	}(httpServer)

	// start the http gateway server
	if err := httpServer.Start(opts...); err != nil {
		log.Fatalf("failed to start http gateway server: %v", err)
	}
}


EOF
}


# Populate server.go for grpc package
populate_grpc_server_go() {
  echo "Populating grpc server.go with dynamic project name..."

  # Define the path where server.go will reside
  grpc_server_path="$server_root/cmd/server/grpc"

  # Ensure the grpc directory exists
  mkdir -p "$grpc_server_path"

  # Create and write to server.go
  cat << EOF > "$grpc_server_path/server.go"

package grpc

import (
	"fmt"
	"$base_import_path/cmd/server"
    "$base_import_path/cmd/server/grpc/interceptor"
	"$base_import_path/configs"
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
	cfg := configs.NewKeyStoreConfig()

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

// WithAuthServer registers the auth service with the grpc server
/*func (*GatewayGrpcServer) WithAuthServer() server.ServiceRegistrationOption {
	return func(srv *grpc.Server, _ *runtime.ServeMux) error {
		pb.RegisterAuthSvcServer(srv, services.NewAuthService(internal.AuthInjector.UseCase))
		return nil
	}
}*/

EOF
}


# Populate service_registrar.go for grpc package
populate_http_go() {
  echo "Populating grpc http.go with dynamic project name..."

  # Create and write to http.go
  cat << EOF > "$server_root/cmd/server/http.go"
package server

import (
	"context"
	"fmt"
	"$base_import_path/configs"
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

// HttpGatewayServer is the http gateway server
type HttpGatewayServer struct {
	ctx context.Context
	cfg *configs.KeyStoreConfig
	GatewayServer
}

// NewHttpGatewayServer returns a new instance of the http gateway server
func NewHttpGatewayServer(ctx context.Context) *HttpGatewayServer {
	// set the context to the background if it is nil
	if ctx == nil {
		ctx = context.Background()
	}

	// set config
	cfg := configs.NewKeyStoreConfig()

	return &HttpGatewayServer{ctx: ctx, cfg: cfg}
}

// Start starts the http gateway server
func (h *HttpGatewayServer) Start(opts ...ServiceRegistrationOption) error {
	var err error

	// Marshal JSON requests using \`protojson\` (maintain the naming format of proto messages)
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

// WithSvcServer registers the  service with the http gateway server
/*func (h *HttpGatewayServer) WithSvcServer() ServiceRegistrationOption {
	return func(_ *grpc.Server, mux *runtime.ServeMux) error {
		baseUrl := fmt.Sprintf("%s:%s", h.cfg.GrpcServerHost, h.cfg.GrpcServerPort)
		return pb.RegisterSvcHandlerFromEndpoint(h.ctx, mux, baseUrl, dialOpts)
	}
	//note that this is inaccurate as there is no service like svc and this is only a template
}*/

EOF
}



# Populate server_options.go
populate_http_server_options_go() {
  echo "Populating http server_options.go with dynamic project name..."

  # Define the path where server.go will reside
  http_server_path="$server_root/cmd/server"

  # Ensure the http directory exists
  mkdir -p "$http_server_path"

  # Create and write to server.go
  cat << EOF > "$http_server_path/server_options.go"
package server

import (
	"github.com/grpc-ecosystem/grpc-gateway/v2/runtime"
	"google.golang.org/grpc"
)

// ServiceRegistrationOption is a type alias for a function that takes a pointer to either a gRPC server or a HTTP gateway server
type ServiceRegistrationOption func(*grpc.Server, *runtime.ServeMux) error

// GatewayServer is an interface for a server (gRPC or HTTP gateway)
type GatewayServer interface {
	// WithAuthServer registers the auth service with the server instance
	//WithAuthServer() ServiceRegistrationOption //this is an example of how the service is registered in the interface

	// Start starts the server instance
	Start(...ServiceRegistrationOption) error

	// Stop stops the server instance
	Stop() error
}

EOF
}




# Populate keystore.go for configs package
populate_config_keystore_go() {
  echo "Populating configs keystore.go..."

  # Define the path where keystore.go will reside
  config_path="$server_root/configs"

  # Ensure the configs directory exists
  mkdir -p "$config_path"

  # Create and write to keystore.go
  cat << EOF > "$config_path/key_store.go"
package configs

import (
	"fmt"
	"github.com/denisenkom/go-mssqldb/azuread"
	"github.com/joho/godotenv"
	"log"
	"os"
	"strconv"
	"time"
)

// KeyStoreConfig represents the configuration for the KeyStore.
// It contains the sensitive information for the KeyStore.
// This data will be loaded from the .env file, from a key vault or hard coded.
type KeyStoreConfig struct {
	// server
	GrpcServerPort string
	GrpcServerHost string
	HttpServerPort string
	HttpServerHost string

	// database
	DbConnUrl         string
	DbDriver          string
	dbUser            string
	dbPassword        string
	dbHost            string
	dbPort            string
	dbName            string
	DbConnMaxIdleTime time.Duration
	DbConnMaxLifetime time.Duration
	DbMaxOpenConns    int
	DbMaxIdleConns    int
	dbSslMode         bool
}

func NewKeyStoreConfig() *KeyStoreConfig {
	// load env vars
	if err := godotenv.Load("./configs/.env"); err != nil {
		log.Fatalf("failed to load env vars: %v", err)
	}

	cfg := &KeyStoreConfig{
		GrpcServerPort: "50051",
		GrpcServerHost: "0.0.0.0",
		HttpServerPort: "9900",
		HttpServerHost: "0.0.0.0",
		DbDriver:       os.Getenv("DB_DRIVER"),
		dbUser:         os.Getenv("DB_USER"),
		dbPassword:     os.Getenv("DB_PASSWORD"),
		dbHost:         os.Getenv("DB_HOST"),
		dbPort:         os.Getenv("DB_PORT"),
		dbName:         os.Getenv("DB_NAME"),
		DbConnUrl:      os.Getenv("DB_CONN_URL"),
	}

	if idleTime, err := strconv.Atoi(os.Getenv("DB_CONN_MAX_IDLE_TIME")); err == nil {
		cfg.DbConnMaxIdleTime = time.Second * time.Duration(idleTime)
	}

	if lifetime, err := strconv.Atoi(os.Getenv("DB_CONN_MAX_LIFETIME")); err == nil {
		cfg.DbConnMaxLifetime = time.Second * time.Duration(lifetime)
	}

	if maxOpenConns, err := strconv.Atoi(os.Getenv("DB_MAX_OPEN_CONNS")); err == nil {
		cfg.DbMaxOpenConns = maxOpenConns
	}

	if maxIdleConns, err := strconv.Atoi(os.Getenv("DB_MAX_IDLE_CONNS")); err == nil {
		cfg.DbMaxIdleConns = maxIdleConns
	}

	if sslMode, err := strconv.ParseBool(os.Getenv("DB_SSL_MODE")); err == nil {
		cfg.dbSslMode = sslMode
	}

	// get database driver
	if len(cfg.DbDriver) == 0 {
		cfg.DbDriver = azuread.DriverName
	}

	// create database connection url if not provided
	if len(cfg.DbConnUrl) == 0 {
		cfg.DbConnUrl = fmt.Sprintf("%s://%s:%s@%s:%s?database=%s&connection+timeout=30&encrypt=disable&trustservercertificate=%v",
			cfg.DbDriver, cfg.dbUser, cfg.dbPassword, cfg.dbHost, cfg.dbPort, cfg.dbName, cfg.dbSslMode)
	}

	return cfg
}

EOF
}


# Populate validator.go for utils package
populate_utils_validator_go() {
  echo "Populating utils validator.go..."

  # Define the path where validator.go will reside
  utils_path="$server_root/features/common/utils"

  # Ensure the utils directory exists
  mkdir -p "$utils_path"

  # Create and write to validator.go
  cat << EOF > "$utils_path/validators.go"
package utils

import (
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"regexp"
)

var (
	ErrNoEmailAddress      = status.Errorf(codes.InvalidArgument, "email address cannot be empty")
	ErrInvalidEmailAddress = status.Errorf(codes.InvalidArgument, "invalid email address")

	ErrNoPassword      = status.Errorf(codes.InvalidArgument, "password cannot be empty")
	ErrInvalidPassword = status.Errorf(codes.InvalidArgument, "password must be at least 8 characters long and may contain at least one special character")
)

func ValidateEmail(email string) error {
	emailRegex := \`^[a-z0-9._%+\-]+@[a-z0-9.\-]+\.[a-z]{2,4}$\`
	if len(email) == 0 {
		return ErrNoEmailAddress
	}
	if ok, _ := regexp.MatchString(emailRegex, email); !ok {
		return ErrInvalidEmailAddress
	}

	return nil
}

func ValidatePassword(password string) error {
	passwordRegex := \`^[a-zA-Z0-9!@#$&()\-.+]{8,}$\`
	if len(password) == 0 {
		return ErrNoPassword
	}
	if ok, _ := regexp.MatchString(passwordRegex, password); !ok {
		return ErrInvalidPassword
	}

	return nil
}
EOF
}

# Populate validator_test.go for in utils package
populate_validator_test() {
  echo "Populating valiator_test with dynamic project name..."

  # Define the path where validator_test.go will reside
  validator_test_path="$server_root/tests/features/common"


  # Ensure the grpc directory exists
  mkdir -p "$validator_test_path"

  # Create and write to server.go
  cat << EOF > "$validator_test_path/validator_test.go"
package common

import (
	"errors"
	"$base_import_path/features/common/utils"
	"testing"
)

func TestValidators_ValidateEmailAddress(t *testing.T) {
	cases := []struct {
		name        string
		email       string
		expectedErr error
	}{
		{
			name:        "valid email address",
			email:       "sampler@domain.com",
			expectedErr: nil,
		},
		{
			name:        "no email address",
			email:       "",
			expectedErr: utils.ErrNoEmailAddress,
		},
		{
			name:        "invalid email address",
			email:       "sampler@domain",
			expectedErr: utils.ErrInvalidEmailAddress,
		},
		{
			name:        "invalid email address",
			email:       "samplerdomain.com",
			expectedErr: utils.ErrInvalidEmailAddress,
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			// Act
			result := utils.ValidateEmail(tc.email)

			// Assert
			if !errors.Is(tc.expectedErr, result) {
				t.Errorf("expected: %v, got: %v", tc.expectedErr, result)
			}
		})
	}
}

func TestValidators_ValidatePassword(t *testing.T) {
	cases := []struct {
		name        string
		password    string
		expectedErr error
	}{
		{
			name:        "valid password",
			password:    "Sampler@2024",
			expectedErr: nil,
		},
		{
			name:        "no password",
			password:    "",
			expectedErr: utils.ErrNoPassword,
		},
		{
			name:        "invalid password",
			password:    "sampler",
			expectedErr: utils.ErrInvalidPassword,
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			// Act
			result := utils.ValidatePassword(tc.password)

			// Assert
			if !errors.Is(tc.expectedErr, result) {
				t.Errorf("expected: %v, got: %v", tc.expectedErr, result)
			}
		})
	}
}
EOF
}


# Populate main injector.go
populate_main_injector() {
  # Construct the dynamic part of the import path with the given project name


  echo "Populating injector.go with dynamic project name..."
  cat << EOF > "$server_root/internal/injector.go"
package internal


var (
	// Service Injector represents a dependency injector for the service feature.
	// SvcInjector *di.SvcInjector as sample
)

// InitializeDependencies initializes the dependencies for all the features.
func InitializeDependencies() error {
	var err error

	// register dependencies
	err = nil
	return err
}

// CloseDatabases closes all the databases.
func CloseDatabases() {
	//if SvcInjector != nil && SvcInjector.DB != nil {
	//	_ = SvcInjector.DB.Close()
	//}
}

EOF
}

# Populate init sql
populate_sample_init_sql() {
  # Construct the dynamic part of the import path with the given project name


  echo "Populating init sql with dynamic project name..."
  cat << EOF > "$server_root/database/init.sql"
-- create new database sampler_test_db and use it
drop database if exists sampler_test_db;
create database sampler_test_db;
use sampler_test_db;
go

EOF
}


# Populate logging.go
populate_logging_interceptor() {
  # Construct the dynamic part of the import path with the given project name


  echo "Populating logging.go with dynamic project name..."
cat << EOF > "$server_root/cmd/server/grpc/interceptor/logging.go"
package interceptor

import (
	"context"
	"google.golang.org/grpc"
	"log"
	"time"
)

// LoggingUnaryInterceptor logs the unary request
func LoggingUnaryInterceptor(ctx context.Context, req interface{}, info *grpc.UnaryServerInfo, handler grpc.UnaryHandler) (interface{}, error) {
	start := time.Now()

	h, err := handler(ctx, req)

	// logging
	log.Printf(\`
================== gRPC Unary Call ===================
Method: %v
Request: %v
Duration: %v
Error: %v
Response: %v
======================================================
\`,
		info.FullMethod,
		req,
		time.Since(start),
		err,
		h)

	return h, err
}

// LoggingStreamInterceptor logs the stream request
func LoggingStreamInterceptor(srv interface{}, ss grpc.ServerStream, info *grpc.StreamServerInfo, handler grpc.StreamHandler) error {
	start := time.Now()

	err := handler(srv, ss)

	// logging
	log.Printf(\`
================== gRPC Streaming Call ===================
Method: %v
Request: %v
Duration: %v
Error: %v
Response: %v
======================================================
\`,
		info.FullMethod,
		ss,
		time.Since(start),
		err,
		ss)

	return err
}

EOF
}




# Function to initialize Go module and install dependencies
initialize_go_module_and_dependencies() {
  # Navigate to server directory where the Go files are located
  cd "$server_root" || exit


  # Initialize Go module with base_import path which would be same as project name
  # Ensure the go.mod file is created at the root of Go files
  go mod init "$base_import_path"

  echo "Installing common dependencies..."
  # Install common and optional dependencies - ensure your environment has access to these repositories
  go get github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-grpc-gateway \
         github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-openapiv2 \
         google.golang.org/protobuf/cmd/protoc-gen-go \
         google.golang.org/grpc/cmd/protoc-gen-go-grpc

  go mod tidy




  # Check for errors in dependency installation
  if [ $? -ne 0 ]; then
    echo "Failed to install one or more dependencies"
    exit 1
  fi

  # Navigate back to project root (if needed later in the script)
  cd "../" || exit
}




# Main execution
create_base_structure
create_common_feature_structure


if $create_default_feature; then
    # No additional arguments provided, create a default feature
    create_feature_structure "default_feature"
else
    # For any additional arguments, create features with those names
    for feature in "$@"; do
        create_feature_structure "$feature"
    done
fi




# Populate other files and directories
populate_dockerfile
populate_docker_compose
populate_makefile
generate_protobuf_script
populate_gitignore
populate_main_go
populate_grpc_server_go
populate_http_go
populate_http_server_options_go
populate_config_keystore_go
populate_main_injector
populate_utils_validator_go
populate_validator_test
populate_logging_interceptor
populate_k8s_files
populate_sample_init_sql
initialize_go_module_and_dependencies



# Save the current directory
ORIGINAL_DIR=$(pwd)

# Define the base URL for the files and the target directory
BASE_URL="https://raw.githubusercontent.com/googleapis/googleapis/master/google/api"
TARGET_DIR="protos/google/api"

# Create the directory structure
mkdir -p $TARGET_DIR

# Change to the target directory
cd $TARGET_DIR

# List of proto files you want to download
declare -a files=(
				 "httpbody.proto"
                 "annotations.proto"
                 "field_behavior.proto"
                 "http.proto")

# Loop through each file and use curl to download
for file in "${files[@]}"; do
   curl -o "$file" "$BASE_URL/$file"
done

# Return to the original directory
cd $ORIGINAL_DIR

echo "Download complete! Files are in $TARGET_DIR"



# Output created structure for verification
echo "Project structure created:"
