package server

import (
	"context"
	"encoding/json"
	"errors"
	"time"

	"net/http"

	"github.com/sirupsen/logrus"
	"github.com/utr1903/opentelemetry-playground/golang/apps/httpserver/logger"
	"github.com/utr1903/opentelemetry-playground/golang/apps/httpserver/mysql"
	"go.opentelemetry.io/otel/attribute"
	semconv "go.opentelemetry.io/otel/semconv/v1.20.0"
	"go.opentelemetry.io/otel/trace"
)

const SERVER string = "httpserver"

type Server struct {
	MySql *mysql.MySqlDatabase
}

// Create a HTTP server instance
func New(
	db *mysql.MySqlDatabase,
) *Server {
	return &Server{
		MySql: db,
	}
}

// Server handler
func (s *Server) Handler(
	w http.ResponseWriter,
	r *http.Request,
) {

	// Get server span
	parentSpan := trace.SpanFromContext(r.Context())
	defer parentSpan.End()

	logger.Log(logrus.InfoLevel, r.Context(), getUser(r), "Handler is triggered")

	// Perform database query
	err := s.performQuery(w, r, &parentSpan)
	if err != nil {
		return
	}

	performPostprocessing(r, &parentSpan)
	s.createHttpResponse(&w, http.StatusOK, []byte("Success"), &parentSpan)
}

// Performs the database query against the MySQL database
func (s *Server) performQuery(
	w http.ResponseWriter,
	r *http.Request,
	parentSpan *trace.Span,
) error {

	// Build query
	dbOperation, dbStatement, err := s.createDbQuery(r)
	if err != nil {
		s.createHttpResponse(&w, http.StatusMethodNotAllowed, []byte("Method not allowed"), parentSpan)
		return err
	}

	// Create database span
	ctx, dbSpan := (*parentSpan).TracerProvider().
		Tracer(SERVER).
		Start(
			r.Context(),
			dbOperation+" "+s.MySql.Opts.Database+"."+s.MySql.Opts.Table,
			trace.WithSpanKind(trace.SpanKindClient),
		)
	defer dbSpan.End()

	// Set additional span attributes
	dbSpanAttrs := s.getCommonDbSpanAttributes()
	dbSpanAttrs = append(dbSpanAttrs, semconv.DBOperation(dbOperation))
	dbSpanAttrs = append(dbSpanAttrs, semconv.DBStatement(dbStatement))

	// Perform query
	err = s.executeDbQuery(ctx, r, dbStatement)
	if err != nil {
		msg := "Executing DB query is failed."
		logger.Log(logrus.ErrorLevel, ctx, getUser(r), msg)

		// Add status code
		dbSpanAttrs = append(dbSpanAttrs, semconv.OTelStatusCodeError)
		dbSpanAttrs = append(dbSpanAttrs, semconv.OTelStatusDescription(msg))
		dbSpan.SetAttributes(dbSpanAttrs...)

		dbSpan.RecordError(err, trace.WithAttributes(
			semconv.ExceptionEscaped(true),
		))

		s.createHttpResponse(&w, http.StatusInternalServerError, []byte(err.Error()), parentSpan)
		return err
	}

	// Create database connection error
	databaseConnectionError := r.URL.Query().Get("databaseConnectionError")
	if databaseConnectionError == "true" {
		msg := "Connection to database is lost."
		logger.Log(logrus.ErrorLevel, ctx, getUser(r), msg)

		// Add status code
		dbSpanAttrs = append(dbSpanAttrs, semconv.OTelStatusCodeError)
		dbSpanAttrs = append(dbSpanAttrs, semconv.OTelStatusDescription(msg))
		dbSpan.SetAttributes(dbSpanAttrs...)

		dbSpan.RecordError(err, trace.WithAttributes(
			semconv.ExceptionEscaped(true),
		))

		s.createHttpResponse(&w, http.StatusInternalServerError, []byte(msg), parentSpan)
		return errors.New("database connection lost")
	}
	dbSpan.SetAttributes(dbSpanAttrs...)
	return nil
}

// Creates the database query operation and statement
func (s *Server) createDbQuery(
	r *http.Request,
) (
	string,
	string,
	error,
) {
	logger.Log(logrus.InfoLevel, r.Context(), getUser(r), "Building query...")

	var dbOperation string
	var dbStatement string

	switch r.Method {
	case http.MethodGet:
		dbOperation = "SELECT"

		// Create table does not exist error
		tableDoesNotExistError := r.URL.Query().Get("tableDoesNotExistError")
		if tableDoesNotExistError == "true" {
			dbStatement = dbOperation + " name FROM " + "faketable"
		} else {
			dbStatement = dbOperation + " name FROM " + s.MySql.Opts.Table
		}
		return dbOperation, dbStatement, nil
	case http.MethodDelete:
		dbOperation = "DELETE"
		dbStatement = dbOperation + " FROM " + s.MySql.Opts.Table
	default:
		logger.Log(logrus.ErrorLevel, r.Context(), getUser(r), "Method is not allowed.")
		return "", "", errors.New("method not allowed")
	}

	logger.Log(logrus.InfoLevel, r.Context(), getUser(r), "Query is built.")
	return dbOperation, dbStatement, nil
}

// Executes the MySQL database statement
func (s *Server) executeDbQuery(
	ctx context.Context,
	r *http.Request,
	dbStatement string,
) error {

	logger.Log(logrus.InfoLevel, ctx, getUser(r), "Executing query...")

	user := getUser(r)
	switch r.Method {
	case http.MethodGet:
		// Perform a query
		rows, err := s.MySql.Instance.Query(dbStatement)
		if err != nil {
			logger.Log(logrus.ErrorLevel, ctx, user, err.Error())
			return err
		}
		defer rows.Close()

		// Iterate over the results
		names := make([]string, 0, 10)
		for rows.Next() {
			var name string
			err = rows.Scan(&name)
			if err != nil {
				logger.Log(logrus.ErrorLevel, ctx, user, err.Error())
				return err
			}
			names = append(names, name)
		}

		_, err = json.Marshal(names)
		if err != nil {
			logger.Log(logrus.ErrorLevel, ctx, user, err.Error())
			return err
		}
	case http.MethodDelete:
		_, err := s.MySql.Instance.Exec(dbStatement)
		if err != nil {
			logger.Log(logrus.ErrorLevel, ctx, user, err.Error())
			return err
		}
	default:
		logger.Log(logrus.ErrorLevel, ctx, getUser(r), "Method is not allowed.")
		return errors.New("method not allowed")
	}

	logger.Log(logrus.InfoLevel, ctx, getUser(r), "Query is executed.")
	return nil
}

// Creates a HTTP response
func (s *Server) createHttpResponse(
	w *http.ResponseWriter,
	statusCode int,
	body []byte,
	serverSpan *trace.Span,
) {
	(*w).WriteHeader(statusCode)
	(*w).Write(body)

	attrs := []attribute.KeyValue{
		semconv.HTTPStatusCode(statusCode),
	}
	(*serverSpan).SetAttributes(attrs...)
}

// Returns common MySQL database span attributes
func (s *Server) getCommonDbSpanAttributes() []attribute.KeyValue {
	return []attribute.KeyValue{
		semconv.DBSystemMySQL,
		semconv.DBUser(s.MySql.Opts.Username),
		semconv.NetPeerName(s.MySql.Opts.Server),
		// semconv.NetPeerPort(int(s.MySql.Opts.Port)),
		semconv.NetTransportTCP,
		semconv.DBName(s.MySql.Opts.Database),
		semconv.DBSQLTable(s.MySql.Opts.Table),
	}
}

// Performs a postprocessing step
func performPostprocessing(
	r *http.Request,
	parentSpan *trace.Span,
) {
	ctx, processingSpan := (*parentSpan).TracerProvider().
		Tracer(SERVER).
		Start(
			r.Context(),
			"postprocessing",
			trace.WithSpanKind(trace.SpanKindInternal),
		)
	defer processingSpan.End()

	produceSchemaNotFoundInCacheWarning(ctx, r)
}

func produceSchemaNotFoundInCacheWarning(
	ctx context.Context,
	r *http.Request,
) {
	logger.Log(logrus.InfoLevel, ctx, getUser(r), "Postprocessing...")
	schemaNotFoundInCacheWarning := r.URL.Query().Get("schemaNotFoundInCacheWarning")
	if schemaNotFoundInCacheWarning == "true" {
		user := getUser(r)
		logger.Log(logrus.WarnLevel, ctx, user, "Processing schema not found in cache. Calculating from scratch.")
		time.Sleep(time.Millisecond * 500)
	} else {
		time.Sleep(time.Millisecond * 10)
	}
	logger.Log(logrus.InfoLevel, r.Context(), getUser(r), "Postprocessing is complete.")
}

func getUser(
	r *http.Request,
) string {

	user := r.Header.Get("X-User-ID")
	if user == "" {
		user = "_anonymous_"
	}
	return user
}
