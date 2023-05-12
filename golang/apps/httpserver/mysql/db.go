package mysql

import (
	"database/sql"
	"fmt"
	"strconv"

	"github.com/utr1903/opentelemetry-playground/golang/apps/httpserver/config"
)

var mysqlDatabase *sql.DB

func CreateDatabaseConnection(
	cfg *config.HttpServerConfig,
) {

	// Connect to MySQL
	datasourceName := cfg.MysqlUsername + ":" + cfg.MysqlPassword + "@tcp(" + cfg.MysqlServer + ":" + strconv.Itoa(int(cfg.MysqlPort)) + ")/"
	db, err := sql.Open("mysql", datasourceName)
	if err != nil {
		panic(err)
	}

	// Create the database
	_, err = db.Exec("CREATE DATABASE IF NOT EXISTS " + cfg.MysqlDatabase)
	if err != nil {
		panic(err)
	}

	fmt.Println("Database is created successfully!")

	// Use the database
	_, err = db.Exec("USE " + cfg.MysqlDatabase)
	if err != nil {
		panic(err)
	}

	// Create the table
	_, err = db.Exec("CREATE TABLE IF NOT EXISTS " + cfg.MysqlTable + " (id INT NOT NULL PRIMARY KEY AUTO_INCREMENT, name VARCHAR(50) NOT NULL)")
	if err != nil {
		panic(err)
	}

	fmt.Println("Table is created successfully!")
	mysqlDatabase = db
}

func Get() *sql.DB {
	return mysqlDatabase
}
