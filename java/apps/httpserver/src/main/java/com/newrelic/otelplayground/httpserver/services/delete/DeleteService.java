package com.newrelic.otelplayground.httpserver.services.delete;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;

import com.newrelic.otelplayground.httpserver.dtos.ResponseBase;
import com.newrelic.otelplayground.httpserver.repositories.NameRepository;

@Service
public class DeleteService {

  private final Logger logger = LoggerFactory.getLogger(DeleteService.class);

  @Autowired
  private NameRepository repository;

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
    repository.deleteAll();
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
}
