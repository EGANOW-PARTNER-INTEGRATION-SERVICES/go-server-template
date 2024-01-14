package internal

import (
	"errors"
	"github.com/eganow/core/template/api/configs"
	"github.com/jmoiron/sqlx"
	"log"
)

var (
	DB             *sqlx.DB
	ConfigInjector *configs.ConfigInjector
	// @todo -> add other dependencies here
)

// InitializeDependencies initializes the dependencies for all the features.
func InitializeDependencies() error {
	// initialize key store
	if ConfigInjector = configs.NewConfigInjector(); ConfigInjector == nil {
		err := errors.New("failed to initialize config injector")
		return err
	}

	// connect to database
	dbChan := make(chan *sqlx.DB, 1)
	go connectToDatabase(dbChan, ConfigInjector.KeyStoreConfig)

	if DB = <-dbChan; DB == nil {
		err := errors.New("failed to connect to database. please check your database connection string")
		return err
	}

	return nil
}

// CloseDatabases closes all the databases.
func CloseDatabases() {
	if DB != nil {
		_ = DB.Close()
	}
}

func connectToDatabase(dbChan chan *sqlx.DB, cfg *configs.KeyStoreConfig) {
	db, err := sqlx.Open(cfg.DbDriver, cfg.DbConnUrl)
	if err != nil {
		log.Printf("failed to connect to database: %v\n", err)
		dbChan <- nil
		return
	}

	// ping database to make sure connection is alive
	if err = db.Ping(); err != nil {
		log.Printf("failed to ping database: %v\n", err)
		dbChan <- nil
		return
	}

	dbChan <- db
}
