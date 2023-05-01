package com.newrelic.otelplayground.simulator.services;

import java.util.Collections;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

import io.opentelemetry.api.OpenTelemetry;
import io.opentelemetry.api.trace.Span;
import io.opentelemetry.api.trace.SpanKind;
import io.opentelemetry.api.trace.Tracer;
import io.opentelemetry.context.Context;
import io.opentelemetry.context.Scope;
import io.opentelemetry.context.propagation.TextMapPropagator;
import io.opentelemetry.semconv.trace.attributes.SemanticAttributes;
import io.opentelemetry.semconv.trace.attributes.SemanticAttributes.HttpFlavorValues;
import io.opentelemetry.semconv.trace.attributes.SemanticAttributes.OtelStatusCodeValues;

@Component
public class HttpClient implements CommandLineRunner {

  private final Logger logger = LoggerFactory.getLogger(HttpClient.class);

  private Tracer tracer;
  private TextMapPropagator propagator;

  @Value(value = "${HTTP_SERVER_ENDPOINT}")
  private String httpserverEndpoint;

  @Value(value = "${HTTP_SERVER_PORT}")
  private String httpserverPort;

  @Value(value = "${HTTP_SERVER_REQUEST_INTERVAL}")
  private int httpserverRequestInterval;

  @Autowired
  private RestTemplate restTemplate;

  public HttpClient(OpenTelemetry openTelemetry) {
    // Initialize tracer
    tracer = openTelemetry.getTracer(HttpClient.class.getName());

    // Initialize propagator
    propagator = openTelemetry.getPropagators().getTextMapPropagator();
  }

  public void run(String... args) {

    // Set simulation interval for each endpoint
    var simulationIntervalList = httpserverRequestInterval;
    var simulationIntervalDelete = httpserverRequestInterval * 4;

    // Create scheduler
    var scheduler = Executors.newScheduledThreadPool(2);

    // Simulate
    scheduler.scheduleAtFixedRate(() -> list(), httpserverRequestInterval, simulationIntervalList,
        TimeUnit.MILLISECONDS);
    scheduler.scheduleAtFixedRate(() -> delete(), httpserverRequestInterval, simulationIntervalDelete,
        TimeUnit.MILLISECONDS);
  }

  private void list() {

    Span span = tracer.spanBuilder("GET").setSpanKind(SpanKind.CLIENT).startSpan();

    // Make the span the current span
    try (Scope scope = span.makeCurrent()) {
      var url = "http://" + httpserverEndpoint + ":" + httpserverPort + "/list";

      span.setAttribute(SemanticAttributes.HTTP_METHOD, HttpMethod.GET.toString());
      span.setAttribute(SemanticAttributes.HTTP_FLAVOR, HttpFlavorValues.HTTP_1_1.toString());
      span.setAttribute(SemanticAttributes.HTTP_SCHEME, "http");
      span.setAttribute(SemanticAttributes.HTTP_URL, url);
      span.setAttribute(SemanticAttributes.NET_PEER_NAME, httpserverEndpoint);
      span.setAttribute(SemanticAttributes.NET_PEER_PORT, Integer.parseInt(httpserverPort));

      var headers = new HttpHeaders();
      headers.setContentType(MediaType.APPLICATION_JSON);
      headers.setAccept(Collections.singletonList(MediaType.APPLICATION_JSON));

      propagator.inject(Context.current(), headers, HttpHeaders::set);

      var entity = new HttpEntity<>(null, headers);
      var response = restTemplate.exchange(url, HttpMethod.GET, entity, String.class);

      span.setAttribute(SemanticAttributes.HTTP_STATUS_CODE, response.getStatusCode().value());

      logger.info(url + response);
    } catch (Exception e) {
      span.setAttribute(SemanticAttributes.OTEL_STATUS_CODE, OtelStatusCodeValues.ERROR);
      span.setAttribute(SemanticAttributes.EXCEPTION_MESSAGE, e.getMessage());
      span.setAttribute(SemanticAttributes.EXCEPTION_STACKTRACE, e.getStackTrace().toString());
      logger.error(e.getMessage(), e);
    } finally {
      span.end();
    }
  }

  private void delete() {

    Span span = tracer.spanBuilder("DELETE").setSpanKind(SpanKind.CLIENT).startSpan();

    // Make the span the current span
    try (Scope scope = span.makeCurrent()) {
      var url = "http://" + httpserverEndpoint + ":" + httpserverPort + "/delete";

      span.setAttribute(SemanticAttributes.HTTP_METHOD, HttpMethod.DELETE.toString());
      span.setAttribute(SemanticAttributes.HTTP_FLAVOR, HttpFlavorValues.HTTP_1_1.toString());
      span.setAttribute(SemanticAttributes.HTTP_SCHEME, "http");
      span.setAttribute(SemanticAttributes.HTTP_URL, url);
      span.setAttribute(SemanticAttributes.NET_PEER_NAME, httpserverEndpoint);
      span.setAttribute(SemanticAttributes.NET_PEER_PORT, Integer.parseInt(httpserverPort));

      var headers = new HttpHeaders();
      headers.setContentType(MediaType.APPLICATION_JSON);
      headers.setAccept(Collections.singletonList(MediaType.APPLICATION_JSON));

      propagator.inject(Context.current(), headers, HttpHeaders::set);

      var entity = new HttpEntity<>(null, headers);
      var response = restTemplate.exchange(url, HttpMethod.DELETE, entity, String.class);

      span.setAttribute(SemanticAttributes.HTTP_STATUS_CODE, response.getStatusCode().value());

      logger.info(url + response);
    } catch (Exception e) {
      span.setAttribute(SemanticAttributes.OTEL_STATUS_CODE, OtelStatusCodeValues.ERROR);
      span.setAttribute(SemanticAttributes.EXCEPTION_MESSAGE, e.getMessage());
      span.setAttribute(SemanticAttributes.EXCEPTION_STACKTRACE, e.getStackTrace().toString());
      logger.error(e.getMessage(), e);
    } finally {
      span.end();
    }
  }
}
