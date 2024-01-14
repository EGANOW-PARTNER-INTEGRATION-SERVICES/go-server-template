package server

// RegisterServices registers the services for the gRPC server or the HTTP gateway server
func RegisterServices(server GatewayServer) []ServiceRegistrationOption {
	return []ServiceRegistrationOption{
		// @todo -> add more services here
	}
}
