package mysql

import (
	"database/sql"
	"fmt"
)

type Opts struct {
	Server   string
	Port     string
	Username string
	Password string
	Database string
	Table    string
}

type OptFunc func(*Opts)

func defaultOpts() *Opts {
	return &Opts{
		Server:   "mysql",
		Port:     "3306",
		Username: "root",
		Password: "password",
		Database: "otel",
		Table:    "names",
	}
}

type MySqlDatabase struct {
	Opts     *Opts
	Instance *sql.DB
}

// Create a MySQL database instance
func New(
	optFuncs ...OptFunc,
) *MySqlDatabase {

	// Instantiate options with default values
	opts := defaultOpts()

	// Apply external options
	for _, f := range optFuncs {
		f(opts)
	}

	return &MySqlDatabase{
		Opts: opts,
	}
}

// Configure MySQL server
func WithServer(server string) OptFunc {
	return func(opts *Opts) {
		opts.Server = server
	}
}

// Configure MySQL port
func WithPort(port string) OptFunc {
	return func(opts *Opts) {
		opts.Port = port
	}
}

// Configure MySQL username
func WithUsername(username string) OptFunc {
	return func(opts *Opts) {
		opts.Username = username
	}
}

// Configure MySQL password
func WithPassword(password string) OptFunc {
	return func(opts *Opts) {
		opts.Password = password
	}
}

// Configure MySQL database
func WithDatabase(database string) OptFunc {
	return func(opts *Opts) {
		opts.Database = database
	}
}

// Configure MySQL table
func WithTable(table string) OptFunc {
	return func(opts *Opts) {
		opts.Table = table
	}
}

// Creates MySQL database connection
func (m *MySqlDatabase) CreateDatabaseConnection() {

	// Connect to MySQL
	datasourceName := m.Opts.Username + ":" + m.Opts.Password + "@tcp(" + m.Opts.Server + ":" + m.Opts.Port + ")/"
	db, err := sql.Open("mysql", datasourceName)
	if err != nil {
		panic(err)
	}

	// Create the database
	_, err = db.Exec("CREATE DATABASE IF NOT EXISTS " + m.Opts.Database)
	if err != nil {
		panic(err)
	}

	fmt.Println("Database is created successfully!")

	// Use the database
	_, err = db.Exec("USE " + m.Opts.Database)
	if err != nil {
		panic(err)
	}

	// Create the table
	_, err = db.Exec("CREATE TABLE IF NOT EXISTS " + m.Opts.Table + " (id INT NOT NULL PRIMARY KEY AUTO_INCREMENT, name VARCHAR(50) NOT NULL)")
	if err != nil {
		panic(err)
	}

	fmt.Println("Table is created successfully!")
	m.Instance = db
}
