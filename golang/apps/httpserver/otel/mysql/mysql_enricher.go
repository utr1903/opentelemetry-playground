package mysql

import (
	"context"
	"strconv"

	semconv "github.com/utr1903/opentelemetry-playground/golang/apps/httpserver/otel/semconv/v1.24.0"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/trace"
)

const mysql = "mysql"

type mySqlOpts struct {
	TracerName string
	Server     string
	Port       int
	Username   string
	Database   string
	Table      string
}

type mySqlOptFunc func(*mySqlOpts)

type MySqlEnricher struct {
	Opts *mySqlOpts
}

// Create a MySQL database instance
func NewMysqlEnricher(
	optFuncs ...mySqlOptFunc,
) *MySqlEnricher {

	// Apply external options
	var opts *mySqlOpts
	for _, f := range optFuncs {
		f(opts)
	}

	return &MySqlEnricher{
		Opts: opts,
	}
}

// Configure tracer name
func WithTracerName(tracerName string) mySqlOptFunc {
	return func(opts *mySqlOpts) {
		opts.TracerName = tracerName
	}
}

// Configure MySQL server
func WithServer(server string) mySqlOptFunc {
	return func(opts *mySqlOpts) {
		opts.Server = server
	}
}

// Configure MySQL port
func WithPort(port string) mySqlOptFunc {
	return func(opts *mySqlOpts) {
		p, _ := strconv.Atoi(port)
		opts.Port = p
	}
}

// Configure MySQL username
func WithUsername(username string) mySqlOptFunc {
	return func(opts *mySqlOpts) {
		opts.Username = username
	}
}

// Configure MySQL database
func WithDatabase(database string) mySqlOptFunc {
	return func(opts *mySqlOpts) {
		opts.Database = database
	}
}

// Configure MySQL table
func WithTable(table string) mySqlOptFunc {
	return func(opts *mySqlOpts) {
		opts.Table = table
	}
}

func (e *MySqlEnricher) CreateSpan(
	ctx context.Context,
	parentSpan trace.Span,
	operation string,
	statement string,
) (
	context.Context,
	trace.Span,
) {
	// Create database span
	ctx, dbSpan := parentSpan.TracerProvider().
		Tracer(e.Opts.TracerName).
		Start(
			ctx,
			operation+" "+e.Opts.Database+"."+e.Opts.Table,
			trace.WithSpanKind(trace.SpanKindClient),
		)
	defer dbSpan.End()

	// Set additional span attributes
	dbSpanAttrs := e.getCommonAttributes()
	dbSpanAttrs = append(dbSpanAttrs, semconv.DatabaseDbOperation.String(operation))
	dbSpanAttrs = append(dbSpanAttrs, semconv.DatabaseDbStatement.String(statement))
	dbSpan.SetAttributes(dbSpanAttrs...)

	return ctx, dbSpan
}

func (e *MySqlEnricher) getCommonAttributes() []attribute.KeyValue {
	return []attribute.KeyValue{
		semconv.ServerAddress.String(e.Opts.Server),
		semconv.ServerPort.Int(e.Opts.Port),
		semconv.DatabaseSystem.String(mysql),
		semconv.DatabaseUser.String(e.Opts.Username),
		semconv.DatabaseDbName.String(e.Opts.Database),
		semconv.DatabaseDbTable.String(e.Opts.Table),
	}
}
