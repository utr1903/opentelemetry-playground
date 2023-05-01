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

@Component
public class Simulator implements CommandLineRunner {

  private final Logger logger = LoggerFactory.getLogger(Simulator.class);

  @Value(value = "${HTTP_SERVER_ENDPOINT}")
  private String httpserverEndpoint;

  @Value(value = "${HTTP_SERVER_PORT}")
  private String httpserverPort;

  @Value(value = "${HTTP_SERVER_REQUEST_INTERVAL}")
  private int httpserverRequestInterval;

  @Autowired
  private RestTemplate restTemplate;

  public Simulator() {
  }

  public void run(String... args) {

    // Set simulation interval for each endpoint
    var simulationIntervalCreate = httpserverRequestInterval;
    var simulationIntervalList = httpserverRequestInterval * 2;
    var simulationIntervalDelete = httpserverRequestInterval * 4;

    // Create scheduler
    var scheduler = Executors.newScheduledThreadPool(6);

    // Simulate OTel services
    // scheduler.scheduleAtFixedRate(() -> create(), simulationInterval,
    // simulationIntervalCreate,
    // TimeUnit.MILLISECONDS);
    scheduler.scheduleAtFixedRate(() -> list(), httpserverRequestInterval, simulationIntervalList,
        TimeUnit.MILLISECONDS);
    scheduler.scheduleAtFixedRate(() -> delete(), httpserverRequestInterval, simulationIntervalDelete,
        TimeUnit.MILLISECONDS);
  }

  // private void create(
  // boolean isOtel) {

  // var url = setEndpointUrl(isOtel) + "/create";
  // var dto = "{\"name\":\"name\",\"value\":\"value\"}";

  // var headers = new HttpHeaders();
  // headers.setContentType(MediaType.APPLICATION_JSON);
  // headers.setAccept(Collections.singletonList(MediaType.APPLICATION_JSON));

  // var entity = new HttpEntity<>(dto, headers);
  // var response = restTemplate.exchange(url, HttpMethod.POST, entity,
  // String.class);

  // logger.info(url + response);
  // }

  private void list() {
    
    var url = "http://" + httpserverEndpoint + ":" + httpserverPort + "/list";

    var headers = new HttpHeaders();
    headers.setContentType(MediaType.APPLICATION_JSON);
    headers.setAccept(Collections.singletonList(MediaType.APPLICATION_JSON));

    var entity = new HttpEntity<>(null, headers);
    var response = restTemplate.exchange(url, HttpMethod.GET, entity, String.class);

    logger.info(url + response);
  }

  private void delete() {

    var url = "http://" + httpserverEndpoint + ":" + httpserverPort + "/delete";

    var headers = new HttpHeaders();
    headers.setContentType(MediaType.APPLICATION_JSON);
    headers.setAccept(Collections.singletonList(MediaType.APPLICATION_JSON));

    var entity = new HttpEntity<>(null, headers);
    var response = restTemplate.exchange(url, HttpMethod.DELETE, entity, String.class);

    logger.info(url + response);
  }
}
