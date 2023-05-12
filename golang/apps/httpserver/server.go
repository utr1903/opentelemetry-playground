package main

import (
	"context"
	"encoding/json"
	"errors"
	"time"

	"net/http"

	"github.com/sirupsen/logrus"
	"go.opentelemetry.io/otel/attribute"
	semconv "go.opentelemetry.io/otel/semconv/v1.18.0"
	"go.opentelemetry.io/otel/trace"
)

func handler(
	w http.ResponseWriter,
	r *http.Request,
) {

	// Get server span
	parentSpan := trace.SpanFromContext(r.Context())
	defer parentSpan.End()

	log(logrus.InfoLevel, r.Context(), getUser(r), "Handler is triggered")

	// Perform database query
	err := performQuery(w, r, &parentSpan)
	if err != nil {
		return
	}

	performPostprocessing(r, &parentSpan)
	createHttpResponse(&w, http.StatusOK, []byte("Success"), &parentSpan)
}

func performQuery(
	w http.ResponseWriter,
	r *http.Request,
	parentSpan *trace.Span,
) error {

	err := performQueryWithDbSpan(w, r, parentSpan)
	if err != nil {
		return err
	}
	return nil
}

func performQueryWithDbSpan(
	w http.ResponseWriter,
	r *http.Request,
	parentSpan *trace.Span,
) error {

	// Build query
	dbOperation, dbStatement, err := createDbQuery(r)
	if err != nil {
		createHttpResponse(&w, http.StatusMethodNotAllowed, []byte("Method not allowed"), parentSpan)
		return err
	}

	ctx, dbSpan := (*parentSpan).TracerProvider().
		Tracer(appName).
		Start(
			r.Context(),
			dbOperation+" "+mysqlDatabase+"."+mysqlTable,
			trace.WithSpanKind(trace.SpanKindClient),
		)
	defer dbSpan.End()

	// Set additional span attributes
	dbSpanAttrs := getCommonDbSpanAttributes()
	dbSpanAttrs = append(dbSpanAttrs, semconv.DBOperation(dbOperation))
	dbSpanAttrs = append(dbSpanAttrs, semconv.DBStatement(dbStatement))

	// Perform query
	err = executeDbQuery(ctx, r, dbStatement)
	if err != nil {
		// Add status code
		dbSpanAttrs = append(dbSpanAttrs, semconv.OTelStatusCodeError)
		dbSpan.SetAttributes(dbSpanAttrs...)

		createHttpResponse(&w, http.StatusInternalServerError, []byte(err.Error()), parentSpan)
		return err
	}

	// Create database connection error
	databaseConnectionError := r.URL.Query().Get("databaseConnectionError")
	if databaseConnectionError == "true" {
		msg := "Connection to database is lost."
		log(logrus.ErrorLevel, ctx, getUser(r), msg)

		// Add status code
		dbSpanAttrs = append(dbSpanAttrs, semconv.OTelStatusCodeError)
		dbSpan.SetAttributes(dbSpanAttrs...)

		createHttpResponse(&w, http.StatusInternalServerError, []byte(msg), parentSpan)
		return errors.New("database connection lost")
	}
	dbSpan.SetAttributes(dbSpanAttrs...)
	return nil
}

func performQueryWithoutDbSpan(
	w http.ResponseWriter,
	r *http.Request,
	parentSpan *trace.Span,
) error {
	// Build query
	_, dbStatement, err := createDbQuery(r)
	if err != nil {
		createHttpResponse(&w, http.StatusMethodNotAllowed, []byte("Method not allowed"), parentSpan)
		return err
	}

	// Perform query
	err = executeDbQuery(r.Context(), r, dbStatement)
	if err != nil {
		createHttpResponse(&w, http.StatusInternalServerError, []byte(err.Error()), parentSpan)
		return err
	}

	// Parse query parameters
	databaseConnectionError := r.URL.Query().Get("databaseConnectionError")
	if databaseConnectionError == "true" {
		msg := "Connection to database is lost."
		log(logrus.ErrorLevel, r.Context(), getUser(r), msg)
		createHttpResponse(&w, http.StatusInternalServerError, []byte(msg), parentSpan)
		return errors.New("database connection lost")
	}
	return nil
}

func createDbQuery(
	r *http.Request,
) (
	string,
	string,
	error,
) {
	log(logrus.InfoLevel, r.Context(), getUser(r), "Building query...")

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
			dbStatement = dbOperation + " name FROM " + mysqlTable
		}
		return dbOperation, dbStatement, nil
	case http.MethodDelete:
		dbOperation = "DELETE"
		dbStatement = dbOperation + " FROM " + mysqlTable
	default:
		log(logrus.ErrorLevel, r.Context(), getUser(r), "Method is not allowed.")
		return "", "", errors.New("method not allowed")
	}

	log(logrus.InfoLevel, r.Context(), getUser(r), "Query is built.")
	return dbOperation, dbStatement, nil
}

func executeDbQuery(
	ctx context.Context,
	r *http.Request,
	dbStatement string,
) error {

	log(logrus.InfoLevel, ctx, getUser(r), "Executing query...")

	user := getUser(r)
	switch r.Method {
	case http.MethodGet:
		// Perform a query
		rows, err := db.Query(dbStatement)
		if err != nil {
			log(logrus.ErrorLevel, ctx, user, err.Error())
			return err
		}
		defer rows.Close()

		// Iterate over the results
		names := make([]string, 0, 10)
		for rows.Next() {
			var name string
			err = rows.Scan(&name)
			if err != nil {
				log(logrus.ErrorLevel, ctx, user, err.Error())
				return err
			}
			names = append(names, name)
		}

		_, err = json.Marshal(names)
		if err != nil {
			log(logrus.ErrorLevel, ctx, user, err.Error())
			return err
		}
	case http.MethodDelete:
		_, err := db.Exec(dbStatement)
		if err != nil {
			log(logrus.ErrorLevel, ctx, user, err.Error())
			return err
		}
	default:
		log(logrus.ErrorLevel, ctx, getUser(r), "Method is not allowed.")
		return errors.New("method not allowed")
	}

	log(logrus.InfoLevel, ctx, getUser(r), "Query is executed.")
	return nil
}

func createHttpResponse(
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

func getCommonDbSpanAttributes() []attribute.KeyValue {
	return []attribute.KeyValue{
		semconv.DBSystemMySQL,
		semconv.DBUser(mysqlUsername),
		semconv.NetPeerName(mysqlServer),
		semconv.NetPeerPort(mysqlPort),
		semconv.NetTransportTCP,
		semconv.DBName(mysqlDatabase),
		semconv.DBSQLTable(mysqlTable),
	}
}

func performPostprocessing(
	r *http.Request,
	parentSpan *trace.Span,
) {
	ctx, processingSpan := (*parentSpan).TracerProvider().
		Tracer(appName).
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
	log(logrus.InfoLevel, ctx, getUser(r), "Postprocessing...")
	schemaNotFoundInCacheWarning := r.URL.Query().Get("schemaNotFoundInCacheWarning")
	if schemaNotFoundInCacheWarning == "true" {
		user := getUser(r)
		log(logrus.WarnLevel, ctx, user, "Processing schema not found in cache. Calculating from scratch.")
		time.Sleep(time.Millisecond * 500)
	} else {
		time.Sleep(time.Millisecond * 10)
	}
	log(logrus.InfoLevel, r.Context(), getUser(r), "Postprocessing is complete.")
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
