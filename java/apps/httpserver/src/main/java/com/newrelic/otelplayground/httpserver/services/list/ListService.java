package com.newrelic.otelplayground.httpserver.services.list;

import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;

import com.newrelic.otelplayground.httpserver.dtos.ResponseBase;
import com.newrelic.otelplayground.httpserver.entities.Name;
import com.newrelic.otelplayground.httpserver.repositories.NameRepository;

import io.opentelemetry.api.OpenTelemetry;
import io.opentelemetry.api.trace.Span;
import io.opentelemetry.api.trace.SpanKind;
import io.opentelemetry.api.trace.Tracer;
import io.opentelemetry.context.Scope;
import io.opentelemetry.semconv.trace.attributes.SemanticAttributes;
import io.opentelemetry.semconv.trace.attributes.SemanticAttributes.OtelStatusCodeValues;

@Service
public class ListService {

  private final Logger logger = LoggerFactory.getLogger(ListService.class);

  @Value(value = "${MYSQL_SERVER}")
  private String mysqlServer;

  @Value(value = "${MYSQL_USERNAME}")
  private String mysqlUser;

  @Value(value = "${MYSQL_PORT}")
  private String mysqlPort;

  @Value(value = "${MYSQL_DATABASE}")
  private String mysqlDatabase;

  @Value(value = "${MYSQL_TABLE}")
  private String mysqlTable;

  private final String DB_OPERATION = "SELECT";

  private Tracer tracer;

  @Autowired
  private NameRepository repository;

  public ListService(OpenTelemetry openTelemetry) {
    // Get tracer
    this.tracer = openTelemetry.getTracer(ListService.class.getName());
  }

  public ResponseEntity<ResponseBase<List<Name>>> run(String error) {
    logger.info("Retrieving names...");

    try {
      // Get data
      List<Name> names = getNames();

      // Create success response
      String message = "Names are retrieved successfully.";
      return createResponse(message, names, HttpStatus.OK);
    } catch (Exception e) {

      // Create fail response
      String message = "Names are not retrieved successfully.";
      logger.error(message);
      return createResponse(message, null, HttpStatus.INTERNAL_SERVER_ERROR);
    }
  }

  private List<Name> getNames() {
    // Set database statement
    String dbStatement = DB_OPERATION + " " + mysqlDatabase + "." + mysqlTable;

    Span span = tracer.spanBuilder(dbStatement)
        .setSpanKind(SpanKind.CLIENT)
        .startSpan();

    // Make the span the current span
    try (Scope scope = span.makeCurrent()) {

      setCommonSpanAttributes(span, dbStatement);
      return repository.findAll();
    } catch (Exception e) {
      setExceptionSpanAttributes(span, e);
      logger.error(e.getMessage(), e);
      return null;
    } finally {
      span.end();
    }
  }

  private ResponseEntity<ResponseBase<List<Name>>> createResponse(
      String message,
      List<Name> names,
      HttpStatus statusCode) {
    return new ResponseEntity<ResponseBase<List<Name>>>(
        new ResponseBase<List<Name>>(
            message,
            names),
        statusCode);
  }

  private void setCommonSpanAttributes(Span span, String dbStatement) {
    span.setAttribute(SemanticAttributes.DB_SYSTEM, "mysql");
    span.setAttribute(SemanticAttributes.DB_USER, mysqlUser);
    span.setAttribute(SemanticAttributes.DB_NAME, mysqlDatabase);
    span.setAttribute(SemanticAttributes.DB_SQL_TABLE, mysqlTable);
    span.setAttribute(SemanticAttributes.NET_PEER_NAME, mysqlServer);
    span.setAttribute(SemanticAttributes.NET_PEER_PORT, Integer.parseInt(mysqlPort));
    span.setAttribute(SemanticAttributes.NET_TRANSPORT, "IP.TCP");
    span.setAttribute(SemanticAttributes.DB_OPERATION, DB_OPERATION);
    span.setAttribute(SemanticAttributes.DB_STATEMENT, dbStatement);
  }

  private void setExceptionSpanAttributes(Span span, Exception e) {
    span.setAttribute(SemanticAttributes.OTEL_STATUS_CODE, OtelStatusCodeValues.ERROR);
    span.setAttribute(SemanticAttributes.EXCEPTION_MESSAGE, e.getMessage());
    span.setAttribute(SemanticAttributes.EXCEPTION_STACKTRACE, e.getStackTrace().toString());
  }
}
