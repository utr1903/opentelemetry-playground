package com.newrelic.otelplayground.httpserver.services.list;

import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;

import com.newrelic.otelplayground.httpserver.dtos.ResponseBase;
import com.newrelic.otelplayground.httpserver.entities.Name;
import com.newrelic.otelplayground.httpserver.repositories.NameRepository;

@Service
public class ListService {

  private final Logger logger = LoggerFactory.getLogger(ListService.class);

  @Autowired
  private NameRepository repository;

  public ResponseEntity<ResponseBase<List<Name>>> run(String error) {
    logger.info("Retrieving names...");

    try {
      // Get data
      var names = getNames();

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
    return repository.findAll();
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
}
