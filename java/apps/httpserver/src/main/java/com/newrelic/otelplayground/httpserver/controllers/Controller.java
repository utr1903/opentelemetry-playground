package com.newrelic.otelplayground.httpserver.controllers;

import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.newrelic.otelplayground.httpserver.dtos.ResponseBase;
import com.newrelic.otelplayground.httpserver.entity.Name;
import com.newrelic.otelplayground.httpserver.services.delete.DeleteService;
import com.newrelic.otelplayground.httpserver.services.list.ListService;

@RestController
@RequestMapping
public class Controller {

	private final Logger logger = LoggerFactory.getLogger(Controller.class);

	@Autowired
	private ListService listService;

	@Autowired
	private DeleteService deleteService;

	@GetMapping("list")
	public ResponseEntity<ResponseBase<List<Name>>> list(
			@RequestParam(name = "error", defaultValue = "", required = false) String error) {
		logger.info("List method is triggered...");

		var response = listService.run(error);

		logger.info("List method is executed.");

		return response;
	}

	@DeleteMapping("delete")
	public ResponseEntity<ResponseBase<Boolean>> delete(
			@RequestParam(name = "error", defaultValue = "", required = false) String error) {
		logger.info("Delete method is triggered...");

		var response = deleteService.run(error);

		logger.info("Delete method is executed.");

		return response;
	}
}
