package com.newrelic.otelplayground.httpserver.services.delete;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;

import com.newrelic.otelplayground.httpserver.dtos.ResponseBase;
import com.newrelic.otelplayground.httpserver.repositories.NameRepository;
import com.newrelic.otelplayground.httpserver.services.list.ListService;

import io.opentelemetry.api.OpenTelemetry;
import io.opentelemetry.api.common.Attributes;
import io.opentelemetry.api.trace.Span;
import io.opentelemetry.api.trace.SpanKind;
import io.opentelemetry.api.trace.Tracer;
import io.opentelemetry.context.Scope;
import io.opentelemetry.semconv.trace.attributes.SemanticAttributes;
import io.opentelemetry.semconv.trace.attributes.SemanticAttributes.OtelStatusCodeValues;

@Service
public class DeleteService {

  private static final Logger logger = LogManager.getLogger(ListService.class);

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

  private final String DB_OPERATION = "DELETE";

  private Tracer tracer;

  @Autowired
  private NameRepository repository;

  public DeleteService(OpenTelemetry openTelemetry) {
    // Get tracer
    this.tracer = openTelemetry.getTracer(DeleteService.class.getName());
  }

  public ResponseEntity<ResponseBase<Boolean>> run(String error) {
    logger.info("Deleting names...");

    try {
      // Delete data
      deleteNames();

      // Create success response
      String message = "Names are deleted successfully.";
      return createResponse(message, true, HttpStatus.OK);
    } catch (Exception e) {

      // Create fail response
      String message = "Names datas are not deleted successfully.";
      logger.error(message);
      return createResponse(message, false, HttpStatus.INTERNAL_SERVER_ERROR);
    }
  }

  private void deleteNames() {
    // Set database statement
    String dbStatement = DB_OPERATION + " name FROM " + mysqlTable;

    Span span = tracer.spanBuilder(dbStatement)
        .setSpanKind(SpanKind.CLIENT)
        .startSpan();

    // Make the span the current span
    try (Scope scope = span.makeCurrent()) {

      setCommonSpanAttributes(span, dbStatement);
      repository.deleteAll();
    } catch (Exception e) {
      setExceptionSpanAttributes(span, e);
      logger.error(e.getMessage(), e);
    } finally {
      span.end();
    }
  }

  private ResponseEntity<ResponseBase<Boolean>> createResponse(
      String message,
      Boolean isSuccessful,
      HttpStatus statusCode) {
    return new ResponseEntity<ResponseBase<Boolean>>(
        new ResponseBase<Boolean>(
            message,
            isSuccessful),
        statusCode);
  }

  private void setCommonSpanAttributes(
      Span span,
      String dbStatement) {
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

  private void setExceptionSpanAttributes(
      Span span,
      Exception e) {
    span.setAttribute(SemanticAttributes.OTEL_STATUS_CODE, OtelStatusCodeValues.ERROR);
    span.setAttribute(SemanticAttributes.OTEL_STATUS_DESCRIPTION, e.getMessage());

    span.recordException(e, Attributes.of(SemanticAttributes.EXCEPTION_ESCAPED, true));
  }
}
