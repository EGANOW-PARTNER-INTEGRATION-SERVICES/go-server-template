# Variable for server root
server_root := ./server

build-binary:
	@echo "building binary..." && \
	cd server && \
	rm -rf ./bin && \
	mkdir -p ./bin && \
	go build -o ./bin/<template-name> ./cmd/main.go

gen-protos:
	@chmod +x ./scripts/gen-protos.sh && ./scripts/gen-protos.sh

install-gateway-deps:
	go install github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-grpc-gateway \
        github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-openapiv2 \
        google.golang.org/protobuf/cmd/protoc-gen-go \
        google.golang.org/grpc/cmd/protoc-gen-go-grpc

build-docker:
	@echo "building docker image..." && \
	docker buildx build --platform linux/amd64 -f devops/docker/Dockerfile -t eganowdevteam/eganowdevteam/eganow-<template-name>-go-api:latest server

start-docker-services:
	@echo "starting docker services..." && \
	docker-compose -f devops/docker/compose.yaml up -d

apply-k8s:
	@echo "applying k8s resources..." && \
	kubectl apply -f devops/k8s -R

# Makefile target for creating feature structure
feature:
	@$(foreach feature,$(filter-out $@,$(MAKECMDGOALS)), $(MAKE) create_feature_structure FEATURE_NAME=$(feature);)

# Function to create feature structure for each feature
create_feature_structure:
	@$(eval feature_root=$(server_root)/features/$(FEATURE_NAME))
	@echo "Creating feature structure in $(feature_root)"

	# Define directories to be created
	@$(eval directories := \
		"$(feature_root)/business_logic/app" \
		"$(feature_root)/business_logic/services" \
		"$(feature_root)/di" \
		"$(feature_root)/pkg" \
	)

	# Create directories
	@$(foreach dir,$(directories),mkdir -p "$(dir)";)

	# Define file paths and contents
	@$(eval files := \
		"$(feature_root)/business_logic/app/entities.go|package app" \
		"$(feature_root)/business_logic/app/models.go|package app" \
		"$(feature_root)/business_logic/app/use_case.go|package app" \
		"$(feature_root)/business_logic/app/data_source.go|package app" \
		"$(feature_root)/business_logic/app/repository.go|package app" \
		"$(feature_root)/business_logic/services/grpc.go|package service" \
		"$(feature_root)/di/injector.go|package di" \
		"$(feature_root)/pkg/data_source.go|package pkg" \
		"$(feature_root)/pkg/repository.go|package pkg" \
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

