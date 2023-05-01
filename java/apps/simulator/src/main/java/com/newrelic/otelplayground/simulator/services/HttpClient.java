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
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

import io.opentelemetry.api.OpenTelemetry;
import io.opentelemetry.api.common.Attributes;
import io.opentelemetry.api.metrics.LongHistogram;
import io.opentelemetry.api.metrics.Meter;
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
  private final LongHistogram httpClientDuration;

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

    // Initialize meter
    Meter meter = openTelemetry.getMeter(HttpClient.class.getName());
    httpClientDuration = meter
        .histogramBuilder("http.client.duration")
        .ofLongs()
        .setDescription("Measures the duration of outbound HTTP requests.")
        .build();
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

    long startTime = System.currentTimeMillis();
    int resultStatusCode = HttpStatus.OK.value();

    var url = "http://" + httpserverEndpoint + ":" + httpserverPort + "/list";

    Span span = tracer.spanBuilder(HttpMethod.GET.toString()).setSpanKind(SpanKind.CLIENT).startSpan();

    // Make the span the current span
    try (Scope scope = span.makeCurrent()) {

      setCommonSpanAttributes(span, HttpMethod.GET, url);

      var headers = new HttpHeaders();
      headers.setContentType(MediaType.APPLICATION_JSON);
      headers.setAccept(Collections.singletonList(MediaType.APPLICATION_JSON));

      propagator.inject(Context.current(), headers, HttpHeaders::set);

      var entity = new HttpEntity<>(null, headers);
      var response = restTemplate.exchange(url, HttpMethod.GET, entity, String.class);

      resultStatusCode = response.getStatusCode().value();
      span.setAttribute(SemanticAttributes.HTTP_STATUS_CODE, resultStatusCode);

      logger.info(url + response);
    } catch (Exception e) {
      setExceptionSpanAttributes(span, e);
      resultStatusCode = HttpStatus.INTERNAL_SERVER_ERROR.value();
      logger.error(e.getMessage(), e);
    } finally {
      recordHttpClientDuration(startTime, HttpMethod.GET, url, resultStatusCode);
      span.end();
    }
  }

  private void delete() {

    long startTime = System.currentTimeMillis();
    int resultStatusCode = HttpStatus.OK.value();

    var url = "http://" + httpserverEndpoint + ":" + httpserverPort + "/delete";

    Span span = tracer.spanBuilder(HttpMethod.DELETE.toString()).setSpanKind(SpanKind.CLIENT).startSpan();

    // Make the span the current span
    try (Scope scope = span.makeCurrent()) {

      setCommonSpanAttributes(span, HttpMethod.DELETE, url);

      var headers = new HttpHeaders();
      headers.setContentType(MediaType.APPLICATION_JSON);
      headers.setAccept(Collections.singletonList(MediaType.APPLICATION_JSON));

      propagator.inject(Context.current(), headers, HttpHeaders::set);

      var entity = new HttpEntity<>(null, headers);
      var response = restTemplate.exchange(url, HttpMethod.DELETE, entity, String.class);

      resultStatusCode = response.getStatusCode().value();
      span.setAttribute(SemanticAttributes.HTTP_STATUS_CODE, resultStatusCode);

      logger.info(url + response);
    } catch (Exception e) {
      setExceptionSpanAttributes(span, e);
      resultStatusCode = HttpStatus.INTERNAL_SERVER_ERROR.value();
      logger.error(e.getMessage(), e);
    } finally {
      span.end();
      recordHttpClientDuration(startTime, HttpMethod.DELETE, url, resultStatusCode);
    }
  }

  private void setCommonSpanAttributes(Span span, HttpMethod httpMethod, String url) {
    span.setAttribute(SemanticAttributes.HTTP_METHOD, httpMethod.toString());
    span.setAttribute(SemanticAttributes.HTTP_FLAVOR, HttpFlavorValues.HTTP_1_1.toString());
    span.setAttribute(SemanticAttributes.HTTP_SCHEME, "http");
    span.setAttribute(SemanticAttributes.HTTP_URL, url);
    span.setAttribute(SemanticAttributes.NET_PEER_NAME, httpserverEndpoint);
    span.setAttribute(SemanticAttributes.NET_PEER_PORT, Integer.parseInt(httpserverPort));
  }

  private void setExceptionSpanAttributes(Span span, Exception e) {
    span.setAttribute(SemanticAttributes.OTEL_STATUS_CODE, OtelStatusCodeValues.ERROR);
    span.setAttribute(SemanticAttributes.EXCEPTION_MESSAGE, e.getMessage());
    span.setAttribute(SemanticAttributes.EXCEPTION_STACKTRACE, e.getStackTrace().toString());
  }

  private void recordHttpClientDuration(long startTime, HttpMethod httpMethod, String url, int httpStatus) {
    long duration = System.currentTimeMillis() - startTime;
    Attributes attrs = Attributes.builder()
        .put(SemanticAttributes.HTTP_METHOD.toString(), httpMethod.toString())
        .put(SemanticAttributes.HTTP_FLAVOR, HttpFlavorValues.HTTP_1_1.toString())
        .put(SemanticAttributes.HTTP_SCHEME.toString(), "http")
        .put(SemanticAttributes.HTTP_URL.toString(), url)
        .put(SemanticAttributes.NET_PEER_NAME.toString(), httpserverEndpoint)
        .put(SemanticAttributes.NET_PEER_PORT.toString(), Integer.parseInt(httpserverPort))
        .put(SemanticAttributes.HTTP_STATUS_CODE.toString(), httpStatus)
        .build();
    httpClientDuration.record(duration, attrs);
  }
}
