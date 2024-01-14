package configs

import "log"

type ConfigInjector struct {
	KeyStoreConfig *KeyStoreConfig
}

func NewConfigInjector() *ConfigInjector {
	injector := &ConfigInjector{}

	// create config instance @todo -> switch to key vault in production
	if injector.KeyStoreConfig = NewKeyStoreConfigFromDotEnv(); injector.KeyStoreConfig == nil {
		log.Fatalln("failed to initialize key store")
		return nil
	}

	return injector
}
