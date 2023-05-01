package com.newrelic.otelplayground.httpserver.repositories;

import org.springframework.data.jpa.repository.JpaRepository;

import com.newrelic.otelplayground.httpserver.entities.Name;


public interface NameRepository extends JpaRepository<Name, Long> {

}
