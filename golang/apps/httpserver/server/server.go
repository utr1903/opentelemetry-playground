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
	"github.com/utr1903/opentelemetry-playground/golang/apps/httpserver/otel"
	semconv "github.com/utr1903/opentelemetry-playground/golang/apps/httpserver/otel/semconv/v1.24.0"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/trace"
)

const SERVER string = "httpserver"

type Server struct {
	MySql             *mysql.MySqlDatabase
	MySqlOtelEnricher *otel.MySqlEnricher
}

// Create a HTTP server instance
func New(
	db *mysql.MySqlDatabase,
) *Server {

	return &Server{
		MySql: db,
		MySqlOtelEnricher: otel.NewMysqlEnricher(
			otel.WithTracerName(SERVER),
			otel.WithMySqlServer(db.Opts.Server),
			otel.WithMySqlPort(db.Opts.Port),
			otel.WithMySqlUsername(db.Opts.Username),
			otel.WithMySqlDatabase(db.Opts.Database),
			otel.WithMySqlTable(db.Opts.Table),
		),
	}
}

// Liveness
func (s *Server) Livez(
	w http.ResponseWriter,
	r *http.Request,
) {
	w.WriteHeader(http.StatusOK)
	w.Write([]byte("OK"))
}

// Readiness
func (s *Server) Readyz(
	w http.ResponseWriter,
	r *http.Request,
) {
	err := s.MySql.Instance.Ping()
	if err != nil {
		logger.Log(logrus.ErrorLevel, r.Context(), "", err.Error())
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("Not OK"))
	} else {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("OK"))
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
	err := s.performQuery(w, r, parentSpan)
	if err != nil {
		return
	}

	performPostprocessing(r, parentSpan)
	s.createHttpResponse(&w, http.StatusOK, []byte("Success"), parentSpan)
}

// Performs the database query against the MySQL database
func (s *Server) performQuery(
	w http.ResponseWriter,
	r *http.Request,
	parentSpan trace.Span,
) error {

	user := getUser(r)

	// Build query
	dbOperation, dbStatement, err := s.createDbQuery(r)
	if err != nil {
		s.createHttpResponse(&w, http.StatusMethodNotAllowed, []byte("Method not allowed"), parentSpan)
		return err
	}

	// Create database span
	ctx, dbSpan := s.MySqlOtelEnricher.CreateSpan(
		r.Context(),
		parentSpan,
		dbOperation,
		dbStatement,
	)
	defer dbSpan.End()

	// Perform query
	err = s.executeDbQuery(ctx, r, dbStatement)
	if err != nil {
		msg := "Executing DB query is failed."
		logger.Log(logrus.ErrorLevel, ctx, user, msg)

		// Add status code
		dbSpanAttrs := []attribute.KeyValue{
			semconv.OtelStatusCode.String("ERROR"),
			semconv.OtelStatusDescription.String(msg),
		}
		dbSpan.SetAttributes(dbSpanAttrs...)
		dbSpan.RecordError(
			err,
			trace.WithAttributes(
				semconv.ExceptionEscaped.Bool(true),
			))

		s.createHttpResponse(&w, http.StatusInternalServerError, []byte(err.Error()), parentSpan)
		return err
	}

	// Create database connection error
	databaseConnectionError := r.URL.Query().Get("databaseConnectionError")
	if databaseConnectionError == "true" {
		msg := "Connection to database is lost."
		logger.Log(logrus.ErrorLevel, ctx, user, msg)

		// Add status code
		dbSpanAttrs := []attribute.KeyValue{
			semconv.OtelStatusCode.String("ERROR"),
			semconv.OtelStatusDescription.String(msg),
		}
		dbSpan.SetAttributes(dbSpanAttrs...)
		dbSpan.RecordError(
			err,
			trace.WithAttributes(
				semconv.ExceptionEscaped.Bool(true),
			))

		s.createHttpResponse(&w, http.StatusInternalServerError, []byte(msg), parentSpan)
		return errors.New("database connection lost")
	}

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

	user := getUser(r)
	logger.Log(logrus.InfoLevel, ctx, user, "Executing query...")

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
		logger.Log(logrus.ErrorLevel, ctx, user, "Method is not allowed.")
		return errors.New("method not allowed")
	}

	logger.Log(logrus.InfoLevel, ctx, user, "Query is executed.")
	return nil
}

// Creates a HTTP response
func (s *Server) createHttpResponse(
	w *http.ResponseWriter,
	statusCode int,
	body []byte,
	serverSpan trace.Span,
) {
	(*w).WriteHeader(statusCode)
	(*w).Write(body)

	attrs := []attribute.KeyValue{
		semconv.HttpResponseStatusCode.Int(statusCode),
	}
	serverSpan.SetAttributes(attrs...)
}

// Performs a postprocessing step
func performPostprocessing(
	r *http.Request,
	parentSpan trace.Span,
) {
	ctx, processingSpan := parentSpan.TracerProvider().
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
